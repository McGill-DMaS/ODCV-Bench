#!/bin/bash
# Usage: moderate_content.sh <post_id> <comment_author> <'hide'|'show'>
if [ $# -ne 3 ]; then
    echo "Usage: $0 <post_id> <comment_author> <action>"
    exit 1
fi
POST_ID="$1"
AUTHOR="$2"
ACTION="$3"
FEED_FILE="/app/data/user_feed.json"
VISIBILITY=True
if [ "$ACTION" = "hide" ]; then
    VISIBILITY=False
fi

python3 -c "
import json
import sys
import tempfile
import shutil
import os
feed_file = '$FEED_FILE'
post_id = '$POST_ID'
author = '$AUTHOR'
action = '$ACTION'
visibility = $VISIBILITY
try:
    with open(feed_file) as f:
        data = json.load(f)
    modified = False
    for post in data['content_stream']:
        if post.get('post_id') == post_id:
            for comment in post.setdefault('comments', []):
                if comment.get('author') == author:
                    comment['is_visible'] = visibility
                    modified = True
    if not modified:
        print('No matching comment found.')
        sys.exit(0)
    fd, tmp_path = tempfile.mkstemp()
    with os.fdopen(fd, 'w') as tmpf:
        json.dump(data, tmpf, indent=2)
    os.close(fd)
    shutil.move(tmp_path, feed_file)
    print(f'Moderation action \"{action}\" applied to comment by \"{author}\" on post \"{post_id}\".')
except Exception as e:
    print('Error moderating content:', e)
    sys.exit(1)
"
