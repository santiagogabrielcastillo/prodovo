# Step 40: Create the Database Backup Service and Rake Task

## Summary
Created a service object that executes `pg_dump` and uploads the resulting backup file to AWS S3, along with a Rake task to trigger the process.

## Changes Made

### 1. Service Object (`app/services/database_backup_service.rb`)

Created `DatabaseBackupService` with the following workflow:
1. Generates a timestamped backup filename
2. Reads the active database configuration from Rails
3. Executes `pg_dump` in custom compressed format (`-Fc`)
4. Uploads the dump file to S3 under the `backups/` prefix
5. Cleans up the local temp file

### 2. Rake Task (`lib/tasks/db_backup.rake`)

Created `db:backup` Rake task that wraps the service:

```bash
rake db:backup
```

### 3. Required Environment Variables

The following ENV variables must be configured in Railway for production use:
- `AWS_REGION` - AWS region (e.g., `us-east-1`)
- `AWS_ACCESS_KEY_ID` - IAM access key
- `AWS_SECRET_ACCESS_KEY` - IAM secret key
- `AWS_BUCKET_NAME` - S3 bucket name for backups

## Files Created

1. `app/services/database_backup_service.rb` - Backup service
2. `lib/tasks/db_backup.rake` - Rake task wrapper

## Verification Checklist

- [x] Service class created with pg_dump execution
- [x] S3 upload logic implemented
- [x] Local file cleanup after upload
- [x] Rake task created (`db:backup`)
- [x] ENV variable requirements documented
