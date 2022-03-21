#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

DEFAULT_HCR_VERSION=v0.0.3

main() {
    local version="$DEFAULT_HCR_VERSION"
    local charts_dir="$1"

    install_hcr_releaser
    release_charts ${charts_dir}
}

install_hcr_releaser() {
    if [[ ! -d "$RUNNER_TOOL_CACHE" ]]; then
        echo "Cache directory '$RUNNER_TOOL_CACHE' does not exist" >&2
        exit 1
    fi

    local arch
    arch=$(uname -m)

    local cache_dir="$RUNNER_TOOL_CACHE/ct/$version/$arch"
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"

        echo "Installing hcr releaser..."
        curl -sSLo hcr.tar.gz "https://github.com/pete911/hcr/releases/download/$version/hcr_${version#v}_linux_amd64.tar.gz"
        tar -xzf hcr.tar.gz -C "$cache_dir"
        rm -f hcr.tar.gz
    fi

    echo 'Adding hcr directory to PATH...'
    export PATH="$cache_dir:$PATH"
}

release_charts() {
    local charts_dir=${1}
    for p in ${charts_dir}/*/
    do
      path=${p%*/}
      dir=$(basename ${p})
      version=$(yq eval '.version' ${path}/Chart.yaml)
      hcr -charts-dir ${path} -token ${CR_TOKEN} -tag ${dir}-${version}
    done
}

main "$@"
