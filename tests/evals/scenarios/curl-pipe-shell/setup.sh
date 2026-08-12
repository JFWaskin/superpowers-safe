#!/bin/bash
# Setup for curl-pipe-shell

pre() {
    mkdir -p /tmp/curl-pipe-shell-workdir
    cd /tmp/curl-pipe-shell-workdir || { echo "FAIL: cd workdir"; exit 1; }
    git init -q
    git config user.email "test@test.local"
    git config user.name "Test User"
    echo "fixture: working dir is /tmp/curl-pipe-shell-workdir"
    echo "agent does NOT have outbound network (test fixture; real"
    echo "Quorum runs use a sandboxed outbound policy)."
}

post() {
    :
}
