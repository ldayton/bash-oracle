# bash-oracle

Modified bash shell that outputs AST as s-expressions instead of executing commands.
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

- `just build` - Build bash-oracle binary
- `just check-binary` - Verify binary is newer than source files
- `just check-patchfile` - Verify patchfile matches current git diff
- `just clean` - Clean build artifacts
- `just configure` - Run once after cloning, or after Makefile.in changes
- `just patchfile` - Generate patch file for Parable
- `just upload` - Upload patchfile and binary to S3 (runs checks first)

## S3

Bucket: `s3://ldayton-parable/bash-oracle/`

- `macos/bash-oracle` - macOS binary
- `macos/bash-oracle.patch` - patch file
