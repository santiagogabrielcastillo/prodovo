class DatabaseBackupService
  REQUIRED_ENV_VARS = %w[AWS_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BUCKET_NAME].freeze

  def call
    missing = REQUIRED_ENV_VARS.select { |var| ENV[var].blank? }
    if missing.any?
      $stderr.puts "Backup aborted: missing ENV variables: #{missing.join(', ')}"
      return false
    end

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_file = Rails.root.join("tmp", "db_backup_#{timestamp}.dump").to_s

    db_config = ActiveRecord::Base.connection_db_config.configuration_hash

    env_vars = { "PGPASSWORD" => db_config[:password].to_s }
    command = [
      "pg_dump",
      "-Fc",
      "-v",
      "-h", db_config[:host].to_s,
      "-U", db_config[:username].to_s,
      "-p", (db_config[:port] || 5432).to_s,
      "-f", backup_file,
      db_config[:database].to_s
    ]

    unless system(env_vars, *command)
      $stderr.puts "pg_dump failed!"
      return false
    end

    upload_to_s3(backup_file, "db_backup_#{timestamp}.dump")

    true
  rescue => e
    $stderr.puts "Backup failed: #{e.message}"
    false
  ensure
    File.delete(backup_file) if backup_file && File.exist?(backup_file)
  end

  private

  def upload_to_s3(file_path, file_name)
    client = Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
    File.open(file_path, "rb") do |file|
      client.put_object(
        bucket: ENV["AWS_BUCKET_NAME"],
        key: "backups/#{file_name}",
        body: file
      )
    end
  end
end
