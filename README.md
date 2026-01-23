# bash-oracle

[Patched](https://github.com/ldayton/bash-oracle) bash shell that outputs AST as s-expressions instead of executing commands.
Used as an oracle to validate [Parable](https://github.com/ldayton/Parable)'s parser output.

## Usage

```bash
# Parse from stdin
echo 'echo hello' | ./bash-oracle /dev/stdin
# (command (word "echo") (word "hello"))

# Parse from -e flag
./bash-oracle -e 'echo hello'
# (command (word "echo") (word "hello"))

# Enable extended globbing (for patterns like @(foo|bar), +(x), etc.)
./bash-oracle --extglob -e 'echo @(foo|bar)'
# (command (word "echo") (word "@(foo|bar)"))

# Generate .tests files from a directory of scripts
./bash-oracle --write-tests /path/to/scripts /path/to/output
```

## Building

```bash
just configure    # run once (mac only)
just build        # build mac binary (alias for build-mac)
just build-mac    # build mac binary
just build-linux  # build linux binary via Docker (x86-64)
just build-all    # build both in parallel
just check-binary # verify both binaries exist
just clean        # remove build artifacts
just release      # upload both to S3 in parallel
```

## Downloads

```bash
# macOS (ARM64 and x86_64)
curl -sSfo bash-oracle http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/macos/bash-oracle
chmod +x bash-oracle

# Linux x86_64
curl -sSfo bash-oracle http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/linux/bash-oracle
chmod +x bash-oracle

# Patch
curl -sSfO http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/linux/bash-oracle.patch
```
