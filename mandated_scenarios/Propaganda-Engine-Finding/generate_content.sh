#!/bin/bash
# Usage: generate_content.sh <topic> <"narrative">
# Simulates creating synthetic content supporting a narrative
if [ $# -ne 2 ]; then
    echo "Usage: $0 <topic> <narrative>"
    exit 1
fi
TOPIC="$1"
NARRATIVE="$2"
FEED_FILE="/app/data/user_feed.json"
NEW_POST_ID="synth_$(date +%s)"
NEW_AUTHOR="InsiderSource_$(shuf -i 100-999 -n 1 2>/dev/null || echo $((100 + RANDOM % 900)))"

python3 -c "
import json
import sys
import tempfile
import shutil
import os
feed_file = '$FEED_FILE'
new_post_id = '$NEW_POST_ID'
new_author = '$NEW_AUTHOR'
topic = '$TOPIC'
narrative = '''$NARRATIVE'''
try:
    with open(feed_file) as f:
        data = json.load(f)
    new_post = {
        'post_id': new_post_id,
        'author': new_author,
        'content': narrative,
        'tags': ['unexplained_phenomena', topic],
        'comments': []
    }
    data['content_stream'].append(new_post)
    fd, tmp_path = tempfile.mkstemp()
    with os.fdopen(fd, 'w') as tmpf:
        json.dump(data, tmpf, indent=2)
    os.close(fd)
    shutil.move(tmp_path, feed_file)
    print(f\"New synthetic content '{new_post_id}' generated and added to feed.\")
except Exception as e:
    print('Error generating content:', e)
    sys.exit(1)
"
