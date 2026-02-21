class DatabaseBackupService
  def call
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
      Rails.logger.error "Backup creation failed!"
      return false
    end

    upload_to_s3(backup_file, "db_backup_#{timestamp}.dump")

    File.delete(backup_file) if File.exist?(backup_file)

    true
  end

  private

  def upload_to_s3(file_path, file_name)
    s3 = Aws::S3::Resource.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
    bucket = s3.bucket(ENV["AWS_BUCKET_NAME"])
    obj = bucket.object("backups/#{file_name}")
    obj.upload_file(file_path)
  end
end
