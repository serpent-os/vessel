#!/bin/bash

## Testing imports
curl -X POST localhost:5050/api/v1/collections/import -H "Content-Type: application/json" \
    -d '{"reportID": 0, "collectables": [ 
            {"type": "package", "uri": "https://dev.serpentos.com/protosnek/x86_64/lmdb-0.9.29-4-1-x86_64.stone",  "sha256sum": "a4aa4fa43ea41ffc5f4c92e457143a91cbacf0cbcbc941c63a98195c7f2aafd4"},
            {"type": "package", "uri": "https://dev.serpentos.com/protosnek/x86_64/lmdb-devel-0.9.29-4-1-x86_64.stone",  "sha256sum": "7d15e42e9e1ba145acb849225a03dbc4a733b93358f5674a85b4a645a809e246"},
        ]}'
