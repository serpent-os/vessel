#!/bin/bash

## Testing imports
curl -X POST localhost:5050/api/v1/collections/import -H "Content-Type: application/json" \
    -d '{"reportID": 0, "collectables": [ {"type": "package", "uri": "file://../reposync/protosnek/x86_64/bash-5.1.16-1-1-x86_64.stone", "sha256sum": "b171eef6dabe0f0db68a6def14fa541e1fb51d01e411a1f78c64735b62db2d22"}]}'
