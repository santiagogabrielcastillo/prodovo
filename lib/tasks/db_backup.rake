namespace :db do
  desc "Dumps the database and uploads it to AWS S3"
  task backup: :environment do
    puts "Starting database backup process..."
    if DatabaseBackupService.new.call
      puts "Backup successfully created and uploaded to S3."
    else
      puts "Backup failed. Check logs."
    end
  end
end
