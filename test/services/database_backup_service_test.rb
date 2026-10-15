require "test_helper"

class DatabaseBackupServiceTest < ActiveSupport::TestCase
  class FakeS3Client
    attr_reader :put_object_calls

    def initialize(raise_error: nil)
      @put_object_calls = []
      @raise_error = raise_error
    end

    def put_object(bucket:, key:, body:)
      raise @raise_error if @raise_error

      @put_object_calls << { bucket: bucket, key: key, body: body }
      true
    end
  end

  setup do
    @s3_client = FakeS3Client.new
    @service = DatabaseBackupService.new(s3_client: @s3_client)

    ENV["AWS_REGION"] = "us-east-1"
    ENV["AWS_ACCESS_KEY_ID"] = "test-key"
    ENV["AWS_SECRET_ACCESS_KEY"] = "test-secret"
    ENV["AWS_BUCKET_NAME"] = "test-bucket"
  end

  teardown do
    ENV.delete("AWS_REGION")
    ENV.delete("AWS_ACCESS_KEY_ID")
    ENV.delete("AWS_SECRET_ACCESS_KEY")
    ENV.delete("AWS_BUCKET_NAME")
  end

  test "returns true on successful backup and upload" do
    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      stub_system_call(success: true, touch_file: expected_file) do
        result = @service.call

        assert result
        assert_equal 1, @s3_client.put_object_calls.size
        assert_equal "test-bucket", @s3_client.put_object_calls.first[:bucket]
        assert_equal "backups/db_backup_#{timestamp}.dump", @s3_client.put_object_calls.first[:key]
        assert_not File.exist?(expected_file), "Temp file should be cleaned up"
      end
    end
  end

  test "returns false when pg_dump fails" do
    stub_system_call(success: false) do
      result = @service.call
      assert_not result
    end
  end

  test "does not call S3 when pg_dump fails" do
    stub_system_call(success: false) do
      @service.call
    end

    assert_empty @s3_client.put_object_calls, "S3 should not be called when pg_dump fails"
  end

  test "builds correct pg_dump command from database config" do
    captured_env = nil
    captured_cmd = nil

    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      @service.define_singleton_method(:system) do |env, *cmd|
        captured_env = env
        captured_cmd = cmd
        FileUtils.touch(expected_file)
        true
      end

      @service.call

      db_config = ActiveRecord::Base.connection_db_config.configuration_hash
      assert_equal db_config[:password].to_s, captured_env["PGPASSWORD"]
      assert_equal "pg_dump", captured_cmd[0]
      assert_includes captured_cmd, "-Fc"
      assert_includes captured_cmd, "-v"
      assert_includes captured_cmd, db_config[:database].to_s
      assert_includes captured_cmd, db_config[:host].to_s
      assert_includes captured_cmd, db_config[:username].to_s
    end
  end

  test "cleans up temp file after successful upload" do
    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      FileUtils.touch(expected_file)
      assert File.exist?(expected_file), "File should exist before service processes it"

      stub_system_call(success: true) do
        @service.call

        assert_not File.exist?(expected_file), "File should be deleted after service call"
      end
    end
  end

  test "uploads to correct S3 path with timestamp" do
    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s
      expected_s3_key = "backups/db_backup_#{timestamp}.dump"

      stub_system_call(success: true, touch_file: expected_file) do
        result = @service.call
        assert result
      end

      call = @s3_client.put_object_calls.last
      assert_equal expected_s3_key, call[:key]
      assert_equal ENV["AWS_BUCKET_NAME"], call[:bucket]
    end
  end

  test "returns false when required ENV variables are missing" do
    ENV.delete("AWS_REGION")
    ENV.delete("AWS_BUCKET_NAME")

    result = @service.call

    assert_not result
  end

  test "does not run pg_dump when ENV variables are missing" do
    ENV.delete("AWS_ACCESS_KEY_ID")
    system_called = false

    @service.define_singleton_method(:system) do |*_args|
      system_called = true
      true
    end

    @service.call

    assert_not system_called, "pg_dump should not run when ENV variables are missing"
  end

  test "cleans up temp file when S3 upload raises an exception" do
    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      failing_client = FakeS3Client.new(raise_error: Aws::S3::Errors::ServiceError.new(nil, "Network error"))
      @service = DatabaseBackupService.new(s3_client: failing_client)

      stub_system_call(success: true, touch_file: expected_file) do
        result = @service.call

        assert_not result
        assert_not File.exist?(expected_file), "Temp file should be cleaned up even after upload failure"
      end
    end
  end

  test "returns false when S3 upload raises an exception" do
    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      failing_client = FakeS3Client.new(raise_error: StandardError.new("Connection refused"))
      @service = DatabaseBackupService.new(s3_client: failing_client)

      stub_system_call(success: true, touch_file: expected_file) do
        result = @service.call
        assert_not result
      end
    end
  end

  private

  def stub_system_call(success:, touch_file: nil)
    @service.define_singleton_method(:system) do |*_args|
      FileUtils.touch(touch_file) if touch_file
      success
    end
    yield
  end
end
