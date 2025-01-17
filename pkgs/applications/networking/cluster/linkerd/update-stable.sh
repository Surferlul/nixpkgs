#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gnugrep gnused jq

set -x -eu -o pipefail

cd $(dirname "$0")

TAG=$(curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} \
    --silent https://api.github.com/repos/linkerd/linkerd2/releases/latest | \
    jq -r '.tag_name')

VERSION=$(echo ${TAG} | sed 's/^stable-//')

SHA256=$(nix-prefetch-url --quiet --unpack https://github.com/linkerd/linkerd2/archive/refs/tags/${TAG}.tar.gz)

setKV () {
  sed -i "s|$1 = \".*\"|$1 = \"${2:-}\"|" ./default.nix
}

setKV version ${VERSION}
setKV sha256 ${SHA256}
setKV vendorSha256 "" # Necessary to force clean build.

cd ../../../../../
set +e
VENDOR_SHA256=$(nix-build --no-out-link -A linkerd 2>&1 | grep "got:" | cut -d':' -f2 | sed 's| ||g')
set -e
cd - > /dev/null

if [ -n "${VENDOR_SHA256:-}" ]; then
  setKV vendorSha256 ${VENDOR_SHA256}
else
  echo "Update failed. VENDOR_SHA256 is empty."
  exit 1
fi
