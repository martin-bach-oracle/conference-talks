#!/usr/bin/env bash

set -euxo pipefail

TARGET=${1:-development}

[[ $(basename `pwd`) != conference-talks ]] && {
    echo ERR: please run this command from the top-level directory
    exit 1
}

[[ ! ${TARGET} =~ development|production ]] && {
    echo ERR: target must be either production or development
    exit 1
}

# simulate a CI/CD pipeline
# TODO: change connection details
export PATH=./node_modules/.bin:$PATH && \
npm run format 2>&1 > /dev/null && \
npm run build && \
rollup -c && \
~/devel/tools/sqlcl/bin/sql -cloudconfig ~/Downloads/Wallet_blogpost.zip /nolog <<EOF

whenever sqlerror exit
conn -n apexworld
lb set engine SQLCL

@utils/cleanup
cd src/database

lb update -changelog-file ${TARGET}.xml

exit
EOF