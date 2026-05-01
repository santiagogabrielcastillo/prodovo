namespace :db do
  desc "Dumps the database and uploads it to AWS S3"
  task backup: :environment do
    puts "Starting database backup..."
    success = DatabaseBackupService.new.call
    if success
      puts "Backup completed successfully."
    else
      $stderr.puts "Backup failed. Check logs above."
      exit 1
    end
  end
end
