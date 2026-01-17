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

# Generate patch file for Parable
patchfile:
    @echo "# Base: $(git rev-parse master)" > ~/source/Parable/tools/bash-oracle/bash-oracle.patch
    @git diff master..HEAD >> ~/source/Parable/tools/bash-oracle/bash-oracle.patch
    @echo "Wrote ~/source/Parable/tools/bash-oracle/bash-oracle.patch (base: $(git rev-parse --short master))"

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

# Release macOS binary + patchfile to S3 (fails on Linux)
release: patchfile check-binary
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "Error: 'just release' is macOS-only. Use 'just release-linux' instead."
        exit 1
    fi
    aws s3 cp bash-oracle s3://ldayton-parable/bash-oracle/macos/
    aws s3 cp ~/source/Parable/tools/bash-oracle/bash-oracle.patch s3://ldayton-parable/bash-oracle/macos/
    echo "Uploaded to s3://ldayton-parable/bash-oracle/macos/"

# Release Linux binary to S3
release-linux: check-binary-linux
    aws s3 cp bash-oracle-linux s3://ldayton-parable/bash-oracle/linux/bash-oracle
    echo "Uploaded to s3://ldayton-parable/bash-oracle/linux/"
