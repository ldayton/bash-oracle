# Build bash-oracle
build:
    make -j$(nproc) CFLAGS="-DBASH_ORACLE -O2"
    strip bash-oracle

# Clean build artifacts
clean:
    make clean

# Generate patch file for Parable
patchfile:
    git diff master..HEAD > ~/source/Parable/tools/bash-oracle/bash-oracle.patch
    @echo "Wrote ~/source/Parable/tools/bash-oracle/bash-oracle.patch"
