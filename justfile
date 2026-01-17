# Configure (run once, or after Makefile.in changes)
configure:
    ./configure

# Build binary for current platform
build:
    #!/usr/bin/env bash
    case "$(uname -s)" in
        Darwin) make -j$(sysctl -n hw.ncpu) CFLAGS="-DBASH_ORACLE -O2" ;;
        Linux)  make -j$(nproc) CFLAGS="-DBASH_ORACLE -O2" ;;
        *) echo "Unsupported OS"; exit 1 ;;
    esac
    strip bash-oracle

# Clean build artifacts
clean:
    make clean

# Release macOS binary to S3 (run on macOS)
release-mac:
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "Error: run this on macOS"
        exit 1
    fi
    git diff master..HEAD > bash-oracle.patch
    aws s3 cp bash-oracle s3://ldayton-parable/bash-oracle/macos/
    aws s3 cp bash-oracle.patch s3://ldayton-parable/bash-oracle/macos/
    rm bash-oracle.patch
    echo "Uploaded macos/bash-oracle and macos/bash-oracle.patch"

# Release Linux binary to S3 (run on Linux x86_64)
release-linux:
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "Error: run this on Linux"
        exit 1
    fi
    git diff master..HEAD > bash-oracle.patch
    aws s3 cp bash-oracle s3://ldayton-parable/bash-oracle/linux/
    aws s3 cp bash-oracle.patch s3://ldayton-parable/bash-oracle/linux/
    rm bash-oracle.patch
    echo "Uploaded linux/bash-oracle and linux/bash-oracle.patch"
