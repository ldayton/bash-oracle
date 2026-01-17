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

| Target          | macOS                            | Linux                |
| --------------- | -------------------------------- | -------------------- |
| `build`         | native                           | fails                |
| `build-linux`   | Docker                           | Docker               |
| `release`       | uploads macOS binary + patchfile | fails                |
| `release-linux` | uploads Linux binary             | uploads Linux binary |

Setup: `configure` · Cleanup: `clean`

## Downloads

- [macOS binary](http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/macos/bash-oracle)
- [Linux binary](http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/linux/bash-oracle)
- [Patch file](http://ldayton-parable.s3-website-us-east-1.amazonaws.com/bash-oracle/macos/bash-oracle.patch)

S3 bucket: `s3://ldayton-parable/bash-oracle/`
