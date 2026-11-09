#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Recreate a checked source bundle for a configured ZapFast release."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import time
import tomllib
from urllib.request import Request, urlopen


def fetch(url, path, checksum):
    if path.exists():
        if hashlib.sha256(path.read_bytes()).hexdigest() != checksum:
            raise ValueError(f'Cached checksum mismatch: {path}')
        return
    for attempt in range(3):
        try:
            request = Request(url, headers={'User-Agent': 'esparto-source-bundle'})
            with urlopen(request, timeout=60) as response:
                content = response.read()
            if hashlib.sha256(content).hexdigest() != checksum:
                raise ValueError(f'Download checksum mismatch: {path.name}')
            temporary = path.with_suffix(path.suffix + '.partial')
            temporary.write_bytes(content)
            temporary.replace(path)
            return
        except OSError:
            if attempt == 2:
                raise
            time.sleep(2 ** attempt)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True)
    parser.add_argument('--workdir', required=True, type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r'[0-9]+(?:\.[0-9]+)+', args.version):
        parser.error('Expected a numeric release version')
    root = Path(__file__).resolve().parents[2]
    spec = json.loads((root / '.github/source-bundles' / f'zapfast-{args.version}.json').read_text())
    work = args.workdir.resolve()
    dist = work / 'distfiles'
    dist.mkdir(parents=True, exist_ok=True)
    source = work / 'source.tar.gz'
    fetch(spec['source_url'], source, spec['source_sha256'])
    with tarfile.open(source) as archive:
        lock = archive.extractfile(spec['lock_member']).read()
    lock_path = work / 'Cargo.lock'
    lock_path.write_bytes(lock)
    crates = [p for p in tomllib.loads(lock.decode())['package']
              if p.get('source') == 'registry+https://github.com/rust-lang/crates.io-index']

    def fetch_crate(crate):
        filename = f"{crate['name']}-{crate['version']}.crate"
        fetch(f"https://static.crates.io/crates/{crate['name']}/{filename}",
              dist / filename, crate['checksum'])

    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(fetch_crate, crates))
    output = work / spec['archive_name']
    if not output.exists():
        subprocess.run([sys.executable, str(root / '.github/scripts/bundle-crates.py'),
                        '--lock', str(lock_path), '--distdir', str(dist),
                        '--output', str(output)], check=True)
    if hashlib.sha256(output.read_bytes()).hexdigest() != spec['archive_sha256']:
        raise ValueError('Generated archive does not match the reviewed source bundle')
    (work / 'SHA256SUMS').write_text(f"{spec['archive_sha256']}  {spec['archive_name']}\n")
    print(f'Reviewed source bundle verified: {output}')


if __name__ == '__main__':
    main()
