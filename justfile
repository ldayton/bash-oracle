# Run tests
test:
    python3 -m unittest test_bash_oracle -v

# Configure (run once, or after Makefile.in changes)
configure:
    ./configure

# Build mac binary
build-mac:
    make -j$(sysctl -n hw.ncpu) CFLAGS="-DBASH_ORACLE -O2"
    strip bash-oracle

# Build linux binary via Docker (x86-64)
build-linux:
    docker build --platform linux/amd64 -t bash-oracle-build .
    docker create --name bash-oracle-tmp bash-oracle-build
    docker cp bash-oracle-tmp:/src/bash-oracle bash-oracle-linux
    docker rm bash-oracle-tmp

# Build for convenience (alias for build-mac)
build: build-mac

# Build both platforms in parallel
build-all:
    just build-mac & just build-linux & wait

# Check both binaries exist
check-binary:
    #!/usr/bin/env bash
    err=0
    if [[ ! -x bash-oracle ]]; then
        echo "Error: bash-oracle not found (run 'just build-mac')"
        err=1
    fi
    if [[ ! -f bash-oracle-linux ]]; then
        echo "Error: bash-oracle-linux not found (run 'just build-linux')"
        err=1
    fi
    if [[ $err -eq 0 ]]; then
        echo "Mac binary: $(file -b bash-oracle)"
        echo "Linux binary: $(file -b bash-oracle-linux)"
    fi
    exit $err

# Clean build artifacts
clean:
    make clean
    rm -f bash-oracle-linux
    -docker rmi bash-oracle-build 2>/dev/null

# Release mac binary to S3
release-mac: check-binary
    #!/usr/bin/env bash
    patch=$(mktemp)
    git diff master..HEAD > "$patch"
    aws s3 cp bash-oracle s3://ldayton-parable/bash-oracle/macos/
    aws s3 cp "$patch" s3://ldayton-parable/bash-oracle/macos/bash-oracle.patch
    rm "$patch"
    echo "Uploaded macos/bash-oracle and macos/bash-oracle.patch"

# Release linux binary to S3
release-linux: check-binary
    #!/usr/bin/env bash
    patch=$(mktemp)
    git diff master..HEAD > "$patch"
    aws s3 cp bash-oracle-linux s3://ldayton-parable/bash-oracle/linux/bash-oracle
    aws s3 cp "$patch" s3://ldayton-parable/bash-oracle/linux/bash-oracle.patch
    rm "$patch"
    echo "Uploaded linux/bash-oracle and linux/bash-oracle.patch"

# Release both platforms in parallel
release:
    just release-mac & just release-linux & wait
