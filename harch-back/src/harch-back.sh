#!/bin/bash
#  creator: https://github.com/harch-linux
# Usage:
#   harch-back backup /path/to/output/folder
#     Backup files from /var/cache/pacman/pkg to the specified folder.
#     Example: harch-back backup /home/user/backups

#   harch-back restore /path/to/backup/file
#     Restore files from the specified backup file to /var/cache/pacman/pkg.
#     Example: harch-back restore /home/user/backups/pkg-backup-2024-06-08-00.tar.gz

#   harch-back --help
#     Display this help message.

# Define the source and destination directories
SOURCE_DIR="/var/cache/pacman/pkg"

# Backup function
backup() {
    DEST_DIR="$1"

    # Check if the destination directory exists
    if [ ! -d "$DEST_DIR" ]; then
        echo "Destination directory does not exist: $DEST_DIR"
        exit 1
    fi

    # Generate date and time components for the backup file name
    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")
    HOUR=$(date +"%H")
    MINUTE=$(date +"%M")

    # Name of the final backup file with timestamp
    FINAL_BACKUP_FILE="$DEST_DIR/pkg-backup-${YEAR}-${MONTH}-${DAY}-${HOUR}-${MINUTE}.tar.gz"

    # Calculate total size for progress estimation and display it
    TOTAL_SIZE=$(du -sb "$SOURCE_DIR" | cut -f1)
    echo "Total size of files to be compressed: $(bc <<< "scale=2; $TOTAL_SIZE/1024/1024") MB ($(bc <<< "scale=2; $TOTAL_SIZE/1024/1024/1024") GB)"

    # Create the backup with progress bar
    tar -czf - -C "$SOURCE_DIR" . | pv -s $TOTAL_SIZE > "$FINAL_BACKUP_FILE"

    # Print completion message
    echo "Backup completed successfully. File saved to: $FINAL_BACKUP_FILE"
}

# Restore function
restore() {
    BACKUP_FILE="$1"

    # Check if the script is run as root
    if [ "$EUID" -ne 0 ]; then
        echo "This operation must be run as root. Please use sudo."
        exit 1
    fi

    # Check if the backup file exists
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Backup file does not exist: $BACKUP_FILE"
        exit 1
    fi

    # Check if the backup file contains at least one zst file
    if ! tar -tf "$BACKUP_FILE" | grep -q "\.zst$"; then
        echo "Error: No zst files found in the backup archive."
        exit 1
    fi

    # Extract the backup file to the source directory with progress bar
    pv "$BACKUP_FILE" | tar -xzf - -C "$SOURCE_DIR"

    # Print completion message
    echo "Restore completed successfully. Files restored to: $SOURCE_DIR"
}

# Main script logic
if [ "$1" == "--help" ]; then
    echo "creator: https://github.com/harch-linux"
    echo ""
    echo "Usage:"
    echo "    harch-back backup /path/to/output/folder"
    echo "    Backup files from pkgs cache folder to the specified folder."
    echo "    Example: harch-back backup ~/Desktop"
    echo ""
    echo "    harch-back restore /path/to/backup/file"
    echo "    Restore files from the specified backup file to pkgs cache folder"
    echo "    Example: harch-back restore ~/Desktop/pkg-backup-2024-06-08-00.tar.gz"
    echo ""
    echo "  harch-back --help"
    echo "    Display this help message."
    exit 0
fi

if [ "$1" == "backup" ]; then
    if [ -z "$2" ]; then
    echo "Error: Destination folder not specified."
    echo "    Backup files from pkgs cache folder to the specified folder."
    echo "    Example: harch-back backup ~/Desktop"
        exit 1
    fi
    backup "$2"
elif [ "$1" == "restore" ]; then
    if [ -z "$2" ]; then
        echo "Error: Backup file not specified."
    echo "    Restore files from the specified backup file to pkgs cache folder"
    echo "    Example: harch-back restore ~/Desktop/pkg-backup-2024-06-08-00.tar.gz"
        exit 1
    fi
    restore "$2"
else
    echo "Error: Invalid command."
    echo "  harch-back --help"
    echo "    Display this help message."
    exit 1
fi
