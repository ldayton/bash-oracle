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

Use `just` commands, not raw make:

| Target        | macOS                      | Linux  |
| ------------- | -------------------------- | ------ |
| `build`       | native                     | fails  |
| `build-linux` | Docker                     | Docker |
| `release`     | uploads binaries + patch   | fails  |

Setup: `configure` · Cleanup: `clean`

## Downloads

```bash
# macOS
curl -sSfo bash-oracle http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/macos/bash-oracle
chmod +x bash-oracle

# Linux
curl -sSfo bash-oracle http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/linux/bash-oracle
chmod +x bash-oracle

# Patch
curl -sSfO http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/bash-oracle.patch
```
