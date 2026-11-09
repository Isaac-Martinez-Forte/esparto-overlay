#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Bundle cached registry crates for cargo.eclass; never download or change sources."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import tarfile
import tomllib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lock', required=True, type=Path)
    parser.add_argument('--distdir', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    packages = tomllib.loads(args.lock.read_text())['package']
    crates = sorted((p for p in packages if p.get('source', '').startswith('registry+')),
                    key=lambda p: (p['name'], p['version']))
    if not crates:
        parser.error('No registry crates found in the lockfile')
    if args.output.exists():
        parser.error('Output already exists; use another path to compare reproducibility')
    # Check every input before writing any output.
    for crate in crates:
        if crate['source'] != 'registry+https://github.com/rust-lang/crates.io-index':
            parser.error(f"Unsupported registry: {crate['source']}")
        path = args.distdir / f"{crate['name']}-{crate['version']}.crate"
        if hashlib.sha256(path.read_bytes()).hexdigest() != crate['checksum']:
            parser.error(f'Checksum mismatch: {path}')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_name(args.output.name + '.partial')
    if temporary.exists():
        parser.error('Partial output already exists; choose another output path')
    try:
        with temporary.open('xb') as output:
            compressor = subprocess.Popen(['xz', '-T2', '-3', '-c'], stdin=subprocess.PIPE,
                                          stdout=output)
            try:
                with tarfile.open(fileobj=compressor.stdin, mode='w|',
                                  format=tarfile.GNU_FORMAT) as bundle:
                    for crate in crates:
                        name = f"{crate['name']}-{crate['version']}"
                        with tarfile.open(args.distdir / f'{name}.crate') as source:
                            for member in sorted(source.getmembers(), key=lambda m: m.name):
                                path = PurePosixPath(member.name)
                                if (path.is_absolute() or '..' in path.parts
                                        or path.parts[0] != name
                                        or not (member.isfile() or member.isdir())):
                                    raise ValueError(f'Unexpected archive member: {member.name}')
                                if path.name == '.cargo-checksum.json':
                                    raise ValueError('Input already contains Cargo checksum metadata')
                                info = tarfile.TarInfo(f'cargo_home/gentoo/{path}')
                                info.type = member.type
                                info.mode = 0o755 if member.isdir() or member.mode & 0o111 else 0o644
                                info.size = member.size if member.isfile() else 0
                                # TarInfo defaults give deterministic timestamps and ownership.
                                bundle.addfile(info, source.extractfile(member) if member.isfile() else None)
                        data = json.dumps({'package': crate['checksum'], 'files': {}},
                                          sort_keys=True).encode() + b'\n'
                        info = tarfile.TarInfo(f'cargo_home/gentoo/{name}/.cargo-checksum.json')
                        info.mode, info.size = 0o644, len(data)
                        bundle.addfile(info, io.BytesIO(data))
            finally:
                compressor.stdin.close()
                status = compressor.wait()
            if status:
                raise RuntimeError(f'xz exited with status {status}')
        temporary.rename(args.output)
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise
    print(f'{len(crates)} verified crates: {args.output} ({args.output.stat().st_size:,} bytes)')
    print(f'SHA256 {hashlib.sha256(args.output.read_bytes()).hexdigest()}')


if __name__ == '__main__':
    main()
