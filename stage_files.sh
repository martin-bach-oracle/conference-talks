#!/usr/bin/env bash

set -euxo pipefail

[[ ! -d "stage" ]] && mkdir -vp "stage"

# get photon 0.3.3 from JSDelivr and stage it

curl --fail --show-error --location -L https://cdn.jsdelivr.net/npm/@silvia-odwyer/photon@0.3.3/photon_rs.js -o stage/photon_rs.js
curl --fail --show-error --location -L https://cdn.jsdelivr.net/npm/@silvia-odwyer/photon@0.3.3/photon_rs_bg.wasm -o stage/photon_rs_bg.wasm

# get EXIFR 7.1.3 from JSDelivr and stage it

curl --fail --show-error --location -L "https://cdn.jsdelivr.net/npm/exifr@7.1.3/+esm" -o stage/exifr.js

cat <<'EOF'

Files have been successfully staged. The EXIFR module is already present in the database, but empty. Use the files in the stage directory to load them into the database

- photon_rs.js, version 0.3.3 must be loaded into wasm_modules
- photon_rs_bg.wasm, version 0.3.3 must be loaded into wasm_modules

APEX supporting objects will create the MLE modules based on the uploaded
files

EOF
