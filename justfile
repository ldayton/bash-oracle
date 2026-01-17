# Configure (run once, or after Makefile.in changes)
configure:
    ./configure

# Build macOS binary (fails on Linux)
build:
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "Error: 'just build' is macOS-only. Use 'just build-linux' instead."
        exit 1
    fi
    make -j$(sysctl -n hw.ncpu) CFLAGS="-DBASH_ORACLE -O2"
    strip bash-oracle

# Build Linux binary via Docker
build-linux:
    docker build -t bash-oracle-linux .
    docker run --rm bash-oracle-linux > bash-oracle-linux
    chmod +x bash-oracle-linux

# Clean build artifacts
clean:
    make clean

# Check macOS binary is up to date
check-binary:
    #!/usr/bin/env bash
    if [[ ! -f bash-oracle ]]; then
        echo "Error: bash-oracle not found (run 'just build')"
        exit 1
    fi
    newest_src=$(find . -name '*.c' -o -name '*.h' | xargs stat -f %m | sort -rn | head -1)
    binary_time=$(stat -f %m bash-oracle)
    if [[ "$newest_src" -gt "$binary_time" ]]; then
        echo "Error: binary is stale (run 'just build')"
        exit 1
    fi
    echo "macOS binary up to date"

# Check Linux binary exists
check-binary-linux:
    #!/usr/bin/env bash
    if [[ ! -f bash-oracle-linux ]]; then
        echo "Error: bash-oracle-linux not found (run 'just build-linux')"
        exit 1
    fi
    echo "Linux binary exists"

# Release all artifacts to S3 (macOS only)
release: check-binary check-binary-linux
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "Error: 'just release' is macOS-only"
        exit 1
    fi
    git diff master..HEAD > bash-oracle.patch
    aws s3 cp bash-oracle s3://ldayton-parable/bash-oracle/macos/
    aws s3 cp bash-oracle-linux s3://ldayton-parable/bash-oracle/linux/bash-oracle
    aws s3 cp bash-oracle.patch s3://ldayton-parable/bash-oracle/
    rm bash-oracle.patch
    echo "Uploaded macos/bash-oracle, linux/bash-oracle, bash-oracle.patch"
