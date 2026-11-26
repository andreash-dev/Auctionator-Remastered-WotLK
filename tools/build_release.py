#!/usr/bin/env python3
"""Build an installable addon-only ZIP from committed Git content."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile


def git(*args):
    return subprocess.check_output(["git", *args])


ADDON_FOLDERS = ("AuctionatorRemastered_Startup", "AuctionatorRemastered")
RELEASE_FILES = ("README.md",)


def build(output_dir, ref="HEAD"):
    paths = git("ls-tree", "-r", "--name-only", ref, "--", *(name + "/" for name in ADDON_FOLDERS), *RELEASE_FILES).decode().splitlines()
    for name in ADDON_FOLDERS:
        if f"{name}/{name}.toc" not in paths:
            raise ValueError(f"Required addon folder is missing from Git: {name}")
    contents = {path: git("show", f"{ref}:{path}") for path in paths}
    for path in paths:
        if (Path(path).parts[0] not in ADDON_FOLDERS and path not in RELEASE_FILES) or ".." in Path(path).parts:
            raise ValueError(f"Unexpected archive path: {path}")
        if any(part.lower() in {"wtf", "savedvariables", "backups", ".git"} for part in Path(path).parts):
            raise ValueError(f"Private/generated directory in package: {path}")
        if Path(path).suffix.lower() in {".bak", ".old", ".zip", ".log", ".pyc"}:
            raise ValueError(f"Unexpected generated file: {path}")
    toc = contents["AuctionatorRemastered/AuctionatorRemastered.toc"].decode("utf-8-sig")
    version_match = re.search(r"^## Version:\s*([A-Za-z0-9._-]+)\s*$", toc, re.MULTILINE)
    if not version_match:
        raise ValueError("TOC version is missing or invalid")
    version = version_match.group(1)
    if any(path not in contents for path in RELEASE_FILES):
        raise ValueError("README is missing from the release")
    startup_toc = contents["AuctionatorRemastered_Startup/AuctionatorRemastered_Startup.toc"].decode("utf-8-sig")
    startup_version = re.search(r"^## Version:\s*(\S+)\s*$", startup_toc, re.MULTILINE)
    if not startup_version or startup_version.group(1) != version:
        raise ValueError("Startup and main module versions must match")
    for name in ADDON_FOLDERS:
        addon_toc = contents[f"{name}/{name}.toc"].decode("utf-8-sig")
        for line in addon_toc.splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                reference = name + "/" + line.replace("\\", "/")
                if reference not in contents:
                    raise ValueError(f"TOC dependency absent from package: {reference}")
    output_dir.mkdir(parents=True, exist_ok=True)
    archive = output_dir / f"Auctionator-Remastered-WotLK-{version}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in sorted(contents):
            info = zipfile.ZipInfo(path, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            bundle.writestr(info, contents[path], compresslevel=9)
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None or set(bundle.namelist()) != set(contents):
            raise ValueError("Archive verification failed")
    return {
        "version": version,
        "tag": "v" + version,
        "archive": str(archive),
        "commit": git("rev-parse", ref).decode().strip(),
        "files": len(contents),
        "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=Path("dist"))
    parser.add_argument("--github-output", type=Path)
    parser.add_argument("--ref", default="HEAD", help="Git commit/tree to package (default: HEAD)")
    args = parser.parse_args()
    result = build(args.output_dir, args.ref)
    if args.github_output:
        with args.github_output.open("a", encoding="utf-8") as stream:
            for key in ("version", "tag", "archive", "commit"):
                stream.write(f"{key}={result[key]}\n")
    print(json.dumps(result, indent=2))
