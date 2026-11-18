"""Tests of the binary and compressed disclosure scan, including its refusals.

Each test builds a throwaway git repository, so that the scan is exercised through git
as the gate runs it. The planted term is a made-up word, never a real listed term.
"""
import gzip
import importlib.util
import pathlib
import subprocess
import tempfile
import unittest
from unittest import mock

PATH = pathlib.Path(__file__).resolve().parents[1] / "scan_binary_terms.py"
SPEC = importlib.util.spec_from_file_location("scan_binary_terms", PATH)
scanner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scanner)

TERM = "zorbleword"


def git(repo, *args):
    subprocess.run(["git", "-C", str(repo), *args], check=True, capture_output=True)


class Repository:
    """A throwaway repository with a terms file outside it."""

    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = pathlib.Path(self.tmp.name)
        self.repo = root / "repo"
        self.repo.mkdir()
        git(self.repo, "init", "-q")
        git(self.repo, "config", "user.email", "test@example.invalid")
        git(self.repo, "config", "user.name", "Test")
        self.terms = root / "terms.txt"
        self.terms.write_text("# comment\n\n" + TERM.upper() + "\n", encoding="utf-8")

    def add(self, name, data):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        git(self.repo, "add", name)

    def commit(self):
        git(self.repo, "commit", "-q", "-m", "test")

    def run(self, *flags):
        result = subprocess.run(
            ["python3", "-I", "-B", str(PATH), str(self.terms), *flags],
            cwd=self.repo, capture_output=True, text=True)
        return result.returncode, result.stderr

    def close(self):
        self.tmp.cleanup()


class ScanTests(unittest.TestCase):
    def setUp(self):
        self.r = Repository()

    def tearDown(self):
        self.r.close()

    def test_clean_repository_passes(self):
        self.r.add("a.bin", b"\0\1\2 nothing here")
        self.r.add("b.txt", b"plain text")
        self.assertEqual(self.r.run()[0], 0)

    def test_term_in_binary_file_fails_and_names_only_the_path(self):
        self.r.add("tools/cache/x.pyc", b"\0\0header /home/" + TERM.encode() + b"/x.py")
        status, err = self.r.run()
        self.assertEqual(status, 1)
        self.assertIn("tools/cache/x.pyc", err)
        self.assertNotIn(TERM, err.lower(), "the output must not disclose the term")

    def test_term_inside_gzip_fails(self):
        self.r.add("data/log.jsonl.gz", gzip.compress(b'{"note":"' + TERM.encode() + b'"}\n'))
        status, err = self.r.run()
        self.assertEqual(status, 1)
        self.assertIn("data/log.jsonl.gz", err)

    def test_text_files_are_left_to_the_text_scan(self):
        self.r.add("notes.md", TERM.encode())
        self.assertEqual(self.r.run()[0], 0)

    def test_exclusion_skips_a_path(self):
        self.r.terms.write_text(TERM + "\n:!vendor/*\n", encoding="utf-8")
        self.r.add("vendor/blob.bin", b"\0" + TERM.encode())
        self.assertEqual(self.r.run()[0], 0)

    def test_history_finds_a_deleted_binary(self):
        self.r.add("old.bin", b"\0" + TERM.encode())
        self.r.commit()
        git(self.r.repo, "rm", "-q", "old.bin")
        self.r.commit()
        self.assertEqual(self.r.run()[0], 0, "no longer tracked")
        status, err = self.r.run("--history")
        self.assertEqual(status, 1)
        self.assertIn("old.bin (blob ", err)

    def test_accepted_historical_blob_passes_but_not_when_tracked(self):
        data = b"\0" + TERM.encode()
        self.r.add("old.bin", data)
        self.r.commit()
        oid = subprocess.run(["git", "-C", str(self.r.repo), "rev-parse", "HEAD:old.bin"],
                             capture_output=True, text=True, check=True).stdout.strip()
        self.r.terms.write_text(TERM + "\nblob:" + oid + "\n", encoding="utf-8")
        self.assertEqual(self.r.run()[0], 1, "a tracked copy is always scanned")
        git(self.r.repo, "rm", "-q", "old.bin")
        self.r.commit()
        status, err = self.r.run("--history")
        self.assertEqual(status, 0)
        self.assertIn("1 known historical blobs are accepted", err)

    def test_acceptance_covers_only_the_named_blob(self):
        self.r.add("a.bin", b"\0" + TERM.encode() + b" one")
        self.r.add("b.bin", b"\0" + TERM.encode() + b" two")
        self.r.commit()
        oid = subprocess.run(["git", "-C", str(self.r.repo), "rev-parse", "HEAD:a.bin"],
                             capture_output=True, text=True, check=True).stdout.strip()
        self.r.terms.write_text(TERM + "\nblob:" + oid + "\n", encoding="utf-8")
        status, err = self.r.run("--history")
        self.assertEqual(status, 1)
        self.assertIn("b.bin", err)
        self.assertNotIn("a.bin", err)

    def test_malformed_acceptance_fails_closed(self):
        self.r.add("a.bin", b"\0 clean")
        for bad in ("blob:1234", "blob:" + "g" * 40, "blob:"):
            self.r.terms.write_text(TERM + "\n" + bad + "\n", encoding="utf-8")
            self.assertEqual(self.r.run("--history")[0], 2, bad)

    def test_bad_arguments_and_missing_terms_file_fail_closed(self):
        self.assertEqual(self.r.run("--bogus")[0], 2)
        self.r.terms.unlink()
        self.assertEqual(self.r.run()[0], 2)

    def test_oversized_gzip_fails_closed(self):
        with mock.patch.object(scanner, "MAX_DECOMPRESSED", 10):
            with self.assertRaises(ValueError):
                scanner.expand(gzip.compress(b"x" * 11))
            self.assertEqual(scanner.expand(gzip.compress(b"x" * 10)), b"x" * 10)

    def test_corrupt_gzip_is_searched_raw(self):
        data = b"\x1f\x8bnot a real stream " + TERM.encode()
        self.assertEqual(scanner.expand(data), data)
        self.assertTrue(scanner.matches(scanner.expand(data), [TERM]))


if __name__ == "__main__":
    unittest.main()
