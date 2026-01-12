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
