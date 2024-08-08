#!/bin/bash

# Function to display usage for backup
usage_backup() {
  echo "Usage: $0 backup -H <DB_HOST> -u <DB_USER> -p <DB_PASSWORD> -d <DB_NAME> -D <BACKUP_DIR>"
  exit 1
}

# Function to display usage for restore
usage_restore() {
  echo "Usage: $0 restore -H <DB_HOST> -u <DB_USER> -p <DB_PASSWORD> -d <DB_NAME> -D <BACKUP_DIR> <RESTORE_FILE>"
  exit 1
}

# Check the first parameter for the operation
OPERATION=$1
shift

# Parse command line arguments
while getopts "H:u:p:d:D:" opt; do
  case $opt in
    H) DB_HOST="$OPTARG" ;;
    u) DB_USER="$OPTARG" ;;
    p) DB_PASSWORD="$OPTARG" ;;
    d) DB_NAME="$OPTARG" ;;
    D) BACKUP_DIR="$OPTARG" ;;
    *) if [ "$OPERATION" == "backup" ]; then usage_backup; else usage_restore; fi ;;
  esac
done

# Shift to remove the processed options from the arguments
shift $((OPTIND -1))

# Validate mandatory parameters
if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ] || [ -z "$BACKUP_DIR" ]; then
  if [ "$OPERATION" == "backup" ]; then
    usage_backup
  elif [ "$OPERATION" == "restore" ]; then
    usage_restore
  else
    echo "Invalid operation. Please use 'backup' or 'restore'."
    exit 1
  fi
fi

# Set the backup file path
BACKUP_FILE="$BACKUP_DIR/MySQL_${DB_USER}_backup.sql"

# Backup command
MYSQLDUMP_CMD="mysqldump --no-tablespaces -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE"

# Restore command
MYSQL_CMD="mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < "

case $OPERATION in
  backup)
    # Execute backup command
    echo "Starting database backup..."
    eval $MYSQLDUMP_CMD

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
      echo "Backup successful, file saved at: $BACKUP_FILE"
    else
      echo "Backup failed"
      rm -f $BACKUP_FILE
      exit 1
    fi
    ;;
  restore)
    # Check if a restore file was provided
    RESTORE_FILE=$1
    if [ -z "$RESTORE_FILE" ]; then
      echo "Please provide the path to the restore file"
      usage_restore
    fi

    # Execute restore command
    echo "Starting database restore..."
    eval $MYSQL_CMD $RESTORE_FILE

    # Check if the restore was successful
    if [ $? -eq 0 ]; then
      echo "Restore successful"
    else
      echo "Restore failed"
      exit 1
    fi
    ;;
  *)
    echo "Invalid operation. Please use 'backup' or 'restore'."
    exit 1
    ;;
esac
