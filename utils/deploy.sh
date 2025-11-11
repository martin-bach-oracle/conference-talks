#!/usr/bin/env bash

set -euxo pipefail

TARGET=${1:-development}

[[ $(basename `pwd`) != conference-talks ]] && {
    echo ERR: please run this command from the top-level directory
    exit 1
}

# this check shouldn't be necessary, the deployment is typically triggered
# via npm run ... but let's be safe rather than sorry
[[ ! ${TARGET} =~ development|production ]] && {
    echo ERR: target must be either production or development
    exit 1
}

# Simulate a CI/CD pipeline
# 
# requires that connections have been defined in sqlcl/SQLDev ext for VSCode
#

npm run format && \
npm run lint && \
npm run build && \
npx esbuild dist/sampleData.js --bundle --outfile=dist/bundle.js --format=esm && \

# ensure SQLcl is in your path
sql -name "emily_${TARGET}" <<EOF

whenever sqlerror exit

@utils/cleanup

lb set engine SQLCL

cd src/database

lb update -changelog-file ${TARGET}.xml

exit
EOF