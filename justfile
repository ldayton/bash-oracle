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

# Check binary exists and is current
check-binary:
    #!/usr/bin/env bash
    if [[ ! -x bash-oracle ]]; then
        echo "Error: bash-oracle not found (run 'just build')"
        exit 1
    fi
    echo "Binary OK: $(file -b bash-oracle)"

# Clean build artifacts
clean:
    make clean

# Release binary to S3 for current platform
release: check-binary
    #!/usr/bin/env bash
    case "$(uname -s)" in
        Darwin) DIR="macos" ;;
        Linux)  DIR="linux" ;;
        *) echo "Unsupported OS"; exit 1 ;;
    esac
    git diff master..HEAD > bash-oracle.patch
    aws s3 cp bash-oracle s3://ldayton-parable/bash-oracle/$DIR/
    aws s3 cp bash-oracle.patch s3://ldayton-parable/bash-oracle/$DIR/
    rm bash-oracle.patch
    echo "Uploaded $DIR/bash-oracle and $DIR/bash-oracle.patch"
