require "test_helper"
require "minitest/mock"

class DatabaseBackupServiceTest < ActiveSupport::TestCase
  setup do
    @service = DatabaseBackupService.new

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
    mock_s3_object = Minitest::Mock.new
    mock_bucket = Minitest::Mock.new
    mock_s3 = Minitest::Mock.new

    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      mock_s3_object.expect(:upload_file, true, [expected_file])
      mock_bucket.expect(:object, mock_s3_object, ["backups/db_backup_#{timestamp}.dump"])
      mock_s3.expect(:bucket, mock_bucket, ["test-bucket"])

      stub_system_call(success: true, touch_file: expected_file) do
        Aws::S3::Resource.stub(:new, mock_s3) do
          result = @service.call

          assert result
          assert_not File.exist?(expected_file), "Temp file should be cleaned up"
        end
      end

      mock_s3.verify
      mock_bucket.verify
      mock_s3_object.verify
    end
  end

  test "returns false when pg_dump fails" do
    stub_system_call(success: false) do
      result = @service.call
      assert_not result
    end
  end

  test "does not call S3 when pg_dump fails" do
    s3_called = false

    stub_system_call(success: false) do
      Aws::S3::Resource.stub(:new, ->(*) { s3_called = true; raise "Should not reach here" }) do
        @service.call
      end
    end

    assert_not s3_called, "S3 should not be called when pg_dump fails"
  end

  test "builds correct pg_dump command from database config" do
    captured_env = nil
    captured_cmd = nil

    mock_s3_object = Minitest::Mock.new
    mock_bucket = Minitest::Mock.new
    mock_s3 = Minitest::Mock.new

    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      mock_s3_object.expect(:upload_file, true, [expected_file])
      mock_bucket.expect(:object, mock_s3_object, ["backups/db_backup_#{timestamp}.dump"])
      mock_s3.expect(:bucket, mock_bucket, ["test-bucket"])

      @service.define_singleton_method(:system) do |env, *cmd|
        captured_env = env
        captured_cmd = cmd
        FileUtils.touch(expected_file)
        true
      end

      Aws::S3::Resource.stub(:new, mock_s3) do
        @service.call
      end

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
    mock_s3_object = Minitest::Mock.new
    mock_bucket = Minitest::Mock.new
    mock_s3 = Minitest::Mock.new

    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      mock_s3_object.expect(:upload_file, true, [expected_file])
      mock_bucket.expect(:object, mock_s3_object, ["backups/db_backup_#{timestamp}.dump"])
      mock_s3.expect(:bucket, mock_bucket, ["test-bucket"])

      FileUtils.touch(expected_file)
      assert File.exist?(expected_file), "File should exist before service processes it"

      stub_system_call(success: true) do
        Aws::S3::Resource.stub(:new, mock_s3) do
          @service.call

          assert_not File.exist?(expected_file), "File should be deleted after service call"
        end
      end
    end
  end

  test "uploads to correct S3 path with timestamp" do
    mock_s3_object = Minitest::Mock.new
    mock_bucket = Minitest::Mock.new
    mock_s3 = Minitest::Mock.new

    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s
      expected_s3_key = "backups/db_backup_#{timestamp}.dump"

      mock_s3_object.expect(:upload_file, true, [expected_file])
      mock_bucket.expect(:object, mock_s3_object, [expected_s3_key])
      mock_s3.expect(:bucket, mock_bucket, ["test-bucket"])

      stub_system_call(success: true, touch_file: expected_file) do
        Aws::S3::Resource.stub(:new, mock_s3) do
          result = @service.call
          assert result
        end
      end

      mock_s3.verify
      mock_bucket.verify
      mock_s3_object.verify
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

      failing_s3 = ->(*) { raise Aws::S3::Errors::ServiceError.new(nil, "Network error") }

      stub_system_call(success: true, touch_file: expected_file) do
        Aws::S3::Resource.stub(:new, failing_s3) do
          result = @service.call

          assert_not result
          assert_not File.exist?(expected_file), "Temp file should be cleaned up even after upload failure"
        end
      end
    end
  end

  test "returns false when S3 upload raises an exception" do
    freeze_time do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      expected_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

      failing_s3 = ->(*) { raise StandardError, "Connection refused" }

      stub_system_call(success: true, touch_file: expected_file) do
        Aws::S3::Resource.stub(:new, failing_s3) do
          result = @service.call
          assert_not result
        end
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
