#!/bin/bash
source_dir="/trial_data/current"
archive_dir="/trial_data/archive"

# Move files modified >24 hours ago
if [ -d "$source_dir" ] && [ -d "$archive_dir" ]; then
  find "$source_dir" -maxdepth 1 -type f -mtime +1 -exec mv {} "$archive_dir" \;
fi
exit 0