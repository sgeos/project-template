"""Scan binary and gzip-compressed files in git for listed disclosure terms.

The gate's text scan uses `git grep -I`, which skips binary files, so compiled and
compressed files were never scanned. This script closes that gap. It reads every tracked file, or with
--history every blob reachable from any reference, that is binary or gzip-compressed,
decompresses gzip up to a fixed cap, and matches the terms as case-insensitive fixed
strings, as the text scan does.

A line of the form `blob:<object name>`, with the full hexadecimal name, accepts one
historical blob that is known to match and cannot be removed without rewriting
published history. Acceptance applies only to the history scan. A tracked file is
always scanned, so a known blob that returns to the tree fails the gate again. A
malformed acceptance line fails the scan, so that a typing error cannot accept a blob
silently.

Output names only the path of each matching file, never the term or its context, so
that the gate's own output discloses nothing. A path from the history is printed with
the blob's abbreviated object name, since a deleted file has no current copy.

Exit status. 0 when nothing matches, 1 when a file matches, 2 on any error, so that
the gate fails closed when the scan cannot run.

Usage: scan_binary_terms.py TERMS_FILE [--history]
"""
import fnmatch
import gzip
import io
import subprocess
import sys

# Decompressed bytes read from one gzip stream. The cap bounds a hostile or corrupt
# archive while leaving a wide margin for ordinary compressed records. Raise it for a
# project that tracks larger compressed files.
MAX_DECOMPRESSED = 256 * 1024 * 1024
# Bytes inspected for a NUL to classify a file as binary, as git does.
SNIFF = 8000
GZIP_MAGIC = b"\x1f\x8b"


HEX = frozenset("0123456789abcdef")
# Object names are 40 hexadecimal digits under SHA-1 and 64 under SHA-256.
OBJECT_NAME_LENGTHS = (40, 64)


def parse_terms(text):
    """Return (terms, exclusions, accepted) from the terms file's text.

    Terms and exclusions are parsed as check.sh parses them. Raises ValueError on a
    malformed acceptance line."""
    terms, exclusions, accepted = [], [], set()
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith(":!"):
            exclusions.append(line[2:])
        elif line.startswith("blob:"):
            name = line[5:].strip().lower()
            if len(name) not in OBJECT_NAME_LENGTHS or not set(name) <= HEX:
                raise ValueError("an acceptance line does not hold a full object name")
            accepted.add(name)
        else:
            terms.append(line.lower())
    return terms, exclusions, accepted


def is_scannable(data):
    """True for gzip streams and for files git would treat as binary."""
    return data[:2] == GZIP_MAGIC or b"\0" in data[:SNIFF]


def expand(data):
    """Return the bytes to search, decompressing gzip within the cap.

    A gzip stream that fails to decompress is searched as it stands, since its raw
    bytes may still hold a term. A stream larger than the cap raises ValueError."""
    if data[:2] != GZIP_MAGIC:
        return data
    try:
        with gzip.GzipFile(fileobj=io.BytesIO(data)) as stream:
            out = stream.read(MAX_DECOMPRESSED + 1)
    except (OSError, EOFError):
        return data
    if len(out) > MAX_DECOMPRESSED:
        raise ValueError("a gzip stream exceeds the decompression cap")
    return out


def matches(data, terms):
    """True when any term occurs in the data, ignoring case."""
    text = data.decode("utf-8", errors="replace").lower()
    return any(term in text for term in terms)


def excluded(path, exclusions):
    return any(fnmatch.fnmatch(path, pattern) for pattern in exclusions)


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, check=True).stdout


def tracked_files(exclusions):
    """Yield (label, bytes) for each tracked file in the working tree's index."""
    for name in git("ls-files", "-z").split(b"\0"):
        path = name.decode("utf-8", errors="replace")
        if not path or excluded(path, exclusions):
            continue
        with open(path, "rb") as handle:
            yield path, handle.read()


def history_blobs(exclusions, accepted=frozenset()):
    """Yield (label, bytes) for each blob reachable from any reference, once each,
    leaving out accepted blobs."""
    seen = set()
    for line in git("rev-list", "--all", "--objects").decode("utf-8", "replace").splitlines():
        oid, _, path = line.partition(" ")
        if not path or oid in seen or oid in accepted or excluded(path, exclusions):
            continue
        if git("cat-file", "-t", oid).strip() != b"blob":
            continue
        seen.add(oid)
        yield f"{path} (blob {oid[:10]})", git("cat-file", "blob", oid)


def scan(source, terms):
    """Return the labels of scannable files whose content holds a term."""
    hits = []
    for label, data in source:
        if is_scannable(data) and matches(expand(data), terms):
            hits.append(label)
    return hits


def main(argv):
    if len(argv) not in (1, 2) or (len(argv) == 2 and argv[1] != "--history"):
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    try:
        with open(argv[0], encoding="utf-8") as handle:
            terms, exclusions, accepted = parse_terms(handle.read())
        if not terms:
            return 0
        if len(argv) == 2:
            source = history_blobs(exclusions, accepted)
            if accepted:
                print(f"scan_binary_terms.py: note: {len(accepted)} known historical blobs "
                      "are accepted", file=sys.stderr)
        else:
            source = tracked_files(exclusions)
        hits = scan(source, terms)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"scan_binary_terms.py: could not complete the scan: {type(error).__name__}",
              file=sys.stderr)
        return 2
    for label in hits:
        print(label, file=sys.stderr)
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
