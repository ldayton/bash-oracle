# Configure (run once, or after Makefile.in changes)
configure:
    ./configure

# Build bash-oracle
build:
    make -j$(sysctl -n hw.ncpu) CFLAGS="-DBASH_ORACLE -O2"
    strip bash-oracle

# Clean build artifacts
clean:
    make clean

# Generate patch file for Parable
patchfile:
    @echo "# Base: $(git rev-parse master)" > ~/source/Parable/tools/bash-oracle/bash-oracle.patch
    @git diff master..HEAD >> ~/source/Parable/tools/bash-oracle/bash-oracle.patch
    @echo "Wrote ~/source/Parable/tools/bash-oracle/bash-oracle.patch (base: $(git rev-parse --short master))"

# Check patchfile matches current git diff
check-patchfile:
    #!/usr/bin/env bash
    expected=$(echo "# Base: $(git rev-parse master)" && git diff master..HEAD)
    actual=$(cat ~/source/Parable/tools/bash-oracle/bash-oracle.patch)
    if [[ "$expected" != "$actual" ]]; then
        echo "Error: patchfile is stale (run 'just patchfile')"
        exit 1
    fi
    echo "Patchfile up to date"

# Check binary is newer than source files
check-binary:
    #!/usr/bin/env bash
    if [[ ! -f bash-oracle ]]; then
        echo "Error: bash-oracle binary not found (run 'just build')"
        exit 1
    fi
    newest_src=$(find . -name '*.c' -o -name '*.h' | xargs stat -f %m | sort -rn | head -1)
    binary_time=$(stat -f %m bash-oracle)
    if [[ "$newest_src" -gt "$binary_time" ]]; then
        echo "Error: binary is stale (run 'just build')"
        exit 1
    fi
    echo "Binary up to date"

# Upload patchfile and binary to S3 (macOS only)
upload: check-patchfile check-binary
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "Error: upload only supported on macOS"
        exit 1
    fi
    aws s3 cp ~/source/Parable/tools/bash-oracle/bash-oracle.patch s3://ldayton-parable/bash-oracle/macos/
    aws s3 cp bash-oracle s3://ldayton-parable/bash-oracle/macos/
    echo "Uploaded to s3://ldayton-parable/bash-oracle/macos/"
