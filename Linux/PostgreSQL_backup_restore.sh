#!/bin/bash

# Function to display usage for backup
usage_backup() {
  echo "Usage: $0 backup -H <DB_HOST> -P <DB_PORT> -d <DB_NAME> -U <DB_USER> -p <DB_PASSWORD> -D <BACKUP_DIR>"
  exit 1
}

# Function to display usage for restore
usage_restore() {
  echo "Usage: $0 restore -H <DB_HOST> -P <DB_PORT> -d <DB_NAME> -U <DB_USER> -p <DB_PASSWORD> -D <BACKUP_DIR> <RESTORE_FILE>"
  exit 1
}

# Check the first parameter for the operation
OPERATION=$1
shift

# Parse command line arguments
while getopts "H:P:d:U:p:D:" opt; do
  case $opt in
    H) DB_HOST="$OPTARG" ;;
    P) DB_PORT="$OPTARG" ;;
    d) DB_NAME="$OPTARG" ;;
    U) DB_USER="$OPTARG" ;;
    p) DB_PASSWORD="$OPTARG" ;;
    D) BACKUP_DIR="$OPTARG" ;;
    *) if [ "$OPERATION" == "backup" ]; then usage_backup; else usage_restore; fi ;;
  esac
done

# Shift to remove the processed options from the arguments
shift $((OPTIND -1))

# Validate mandatory parameters
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$BACKUP_DIR" ]; then
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
BACKUP_FILE="$BACKUP_DIR/PostgreSQL_${DB_USER}_backup.sql"

# Set the PGPASSWORD environment variable
export PGPASSWORD=$DB_PASSWORD

# Backup command
PG_DUMP_CMD="pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -O --clean --if-exists -v -f $BACKUP_FILE $DB_NAME"

# Restore command
PG_RESTORE_CMD="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "

case $OPERATION in
  backup)
    # Execute backup command
    echo "Starting database backup..."
    $PG_DUMP_CMD

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
      echo "Backup successful, file saved at: $BACKUP_FILE"
    else
      echo "Backup failed"
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
    $PG_RESTORE_CMD $RESTORE_FILE

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
