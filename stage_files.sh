#!/usr/bin/env bash

set -euxo pipefail

[[ ! -d "stage" ]] && mkdir -vp "stage"

# get photon 0.3.3 from JSDelivr and stage it

curl --fail --show-error --location -L https://cdn.jsdelivr.net/npm/@silvia-odwyer/photon@0.3.3/photon_rs.js -o stage/photon_rs.js
curl --fail --show-error --location -L https://cdn.jsdelivr.net/npm/@silvia-odwyer/photon@0.3.3/photon_rs_bg.wasm -o stage/photon_rs_bg.wasm

# get EXIFR 7.1.3 from JSDelivr and stage it

curl --fail --show-error --location -L "https://cdn.jsdelivr.net/npm/exifr@7.1.3/+esm" -o stage/exifr.js
