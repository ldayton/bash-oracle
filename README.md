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

# Generate .tests files from a directory of scripts
./bash-oracle --write-tests /path/to/scripts /path/to/output
```

## Building

```bash
just configure    # run once
just build        # build for current platform
just check-binary # verify binary exists
just clean        # remove build artifacts
just release      # upload to S3 (run on each platform)
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
