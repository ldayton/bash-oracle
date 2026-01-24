"""Tests for bash-oracle CLI modes and flags."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

BASH_ORACLE = Path(__file__).parent / "bash-oracle"


def run(args: list[str], input: str | None = None) -> subprocess.CompletedProcess:
    """Run bash-oracle with given arguments."""
    return subprocess.run(
        [str(BASH_ORACLE)] + args,
        input=input,
        capture_output=True,
        text=True,
    )


class TestNoArgs(unittest.TestCase):
    """No arguments should show usage and exit non-zero."""

    def test_no_args_shows_usage(self):
        result = run([])
        self.assertEqual(result.returncode, 1)
        self.assertIn("Usage:", result.stdout)


class TestHelp(unittest.TestCase):
    """--help flag should show usage and exit zero."""

    def test_help_shows_usage(self):
        result = run(["--help"])
        self.assertEqual(result.returncode, 0)
        self.assertIn("Usage:", result.stdout)
        self.assertIn("-e BASH", result.stdout)
        self.assertIn("--extglob", result.stdout)
        self.assertIn("--write-tests", result.stdout)


class TestExpressionFlag(unittest.TestCase):
    """-e flag parses expression from argument."""

    def test_e_flag_parses_expression(self):
        result = run(["-e", "echo hello"])
        self.assertEqual(result.returncode, 0)
        self.assertIn("echo", result.stdout)
        self.assertIn("hello", result.stdout)

    def test_e_flag_missing_argument(self):
        result = run(["-e"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_e_flag_extra_argument(self):
        result = run(["-e", "echo hello", "extra"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_e_flag_syntax_error_exits_with_code_2(self):
        """Bug fix: -e previously exited 0 on syntax errors."""
        result = run(["-e", "if then"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("syntax error", result.stderr)

    def test_e_flag_multiline_with_comments(self):
        """Bug fix: comments caused early exit in multiline input."""
        result = run(["-e", "# comment\necho hello\n# another comment\necho world"])
        self.assertEqual(result.returncode, 0)
        self.assertIn("hello", result.stdout)
        self.assertIn("world", result.stdout)

    def test_e_flag_comment_only_input(self):
        """Bug fix: comment-only input should succeed, not crash."""
        result = run(["-e", "# just a comment"])
        self.assertEqual(result.returncode, 0)


class TestExtglobFlag(unittest.TestCase):
    """--extglob flag enables extended globbing."""

    def test_extglob_with_e_flag(self):
        result = run(["--extglob", "-e", "echo @(foo|bar)"])
        self.assertEqual(result.returncode, 0)
        self.assertIn("@(foo|bar)", result.stdout)

    def test_extglob_with_file(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".sh", delete=False) as f:
            f.write("echo @(a|b)\n")
            f.flush()
            try:
                result = run(["--extglob", f.name])
                self.assertEqual(result.returncode, 0)
                self.assertIn("@(a|b)", result.stdout)
            finally:
                os.unlink(f.name)

    def test_extglob_disabled_by_default(self):
        result = run(["-e", "echo @(foo)"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("syntax error", result.stderr)


class TestWriteTestsFlag(unittest.TestCase):
    """--write-tests generates .tests files from scripts."""

    def test_write_tests_creates_output(self):
        with tempfile.TemporaryDirectory() as indir, tempfile.TemporaryDirectory() as outdir:
            script = Path(indir) / "example.sh"
            script.write_text("echo hello\n")
            result = run(["--write-tests", indir, outdir])
            self.assertEqual(result.returncode, 0)
            output_file = Path(outdir) / "example.tests"
            self.assertTrue(output_file.exists())

    def test_write_tests_missing_outdir(self):
        result = run(["--write-tests", "/tmp"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_write_tests_missing_both_args(self):
        result = run(["--write-tests"])
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)


class TestFileInput(unittest.TestCase):
    """Positional argument parses file."""

    def test_parse_file(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".sh", delete=False) as f:
            f.write("echo test\n")
            f.flush()
            try:
                result = run([f.name])
                self.assertEqual(result.returncode, 0)
                self.assertIn("echo", result.stdout)
            finally:
                os.unlink(f.name)

    def test_nonexistent_file(self):
        result = run(["/nonexistent/path/file.sh"])
        self.assertNotEqual(result.returncode, 0)


class TestStdinInput(unittest.TestCase):
    """Reading from /dev/stdin."""

    def test_stdin_via_dev_stdin(self):
        result = run(["/dev/stdin"], input="echo hello")
        self.assertEqual(result.returncode, 0)
        self.assertIn("echo", result.stdout)


class TestInfiniteLoopRegression(unittest.TestCase):
    """Regression tests for infinite loop bugs (issue #1)."""

    def test_process_substitution_with_bad_command_sub(self):
        """Bug fix: >( $?()) caused infinite loop printing syntax errors."""
        result = subprocess.run(
            [str(BASH_ORACLE), "-e", ">( $?())"],
            capture_output=True,
            text=True,
            timeout=5,  # Should complete instantly; timeout catches infinite loop
        )
        self.assertEqual(result.returncode, 2)
        # Should have exactly one syntax error, not repeated infinitely
        self.assertEqual(result.stderr.count("syntax error"), 1)

    def test_process_substitution_with_bad_for(self):
        """Bug fix: >( for ) caused infinite loop printing syntax errors."""
        result = subprocess.run(
            [str(BASH_ORACLE), "-e", ">( for )"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stderr.count("syntax error"), 1)


class TestExitCodeConsistency(unittest.TestCase):
    """Exit codes should be consistent between -e flag and file mode (issue #3)."""

    def test_parse_error_exit_code_matches_file_mode(self):
        """Bug: -e flag returns exit code 1, file mode returns 2 for same parse error."""
        invalid_input = "arr=(>.\ntxt)"
        # Get exit code from file mode
        with tempfile.NamedTemporaryFile(mode="w", suffix=".sh", delete=False) as f:
            f.write(invalid_input)
            f.flush()
            try:
                file_result = run([f.name])
            finally:
                os.unlink(f.name)
        # Get exit code from -e flag
        e_flag_result = run(["-e", invalid_input])
        self.assertEqual(
            e_flag_result.returncode,
            file_result.returncode,
            f"-e flag returned {e_flag_result.returncode}, file mode returned {file_result.returncode}",
        )


class TestNoExecution(unittest.TestCase):
    """Verify commands are parsed but not executed."""

    def test_touch_does_not_create_file(self):
        """Commands should be parsed, not executed."""
        with tempfile.TemporaryDirectory() as tmpdir:
            testfile = Path(tmpdir) / "should_not_exist.txt"
            result = run(["-e", f"touch {testfile}"])
            self.assertEqual(result.returncode, 0)
            self.assertFalse(testfile.exists())

    def test_rm_does_not_delete_file(self):
        """Destructive commands should not execute."""
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b"test content")
            f.flush()
            try:
                result = run(["-e", f"rm {f.name}"])
                self.assertEqual(result.returncode, 0)
                self.assertTrue(Path(f.name).exists())
            finally:
                os.unlink(f.name)


if __name__ == "__main__":
    unittest.main()
