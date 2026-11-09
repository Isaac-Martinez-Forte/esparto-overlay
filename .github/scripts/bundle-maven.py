#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Build a verified, deterministic offline Maven repository from an inventory."""
import argparse
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import tarfile
import time
from urllib.request import urlopen
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inventory', required=True, type=Path)
    parser.add_argument('--repository', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--fetch', action='store_true', help='Fetch missing artifacts from Maven Central')
    args = parser.parse_args()
    spec = json.loads(args.inventory.read_text())
    if spec['repository'] != 'https://repo.maven.apache.org/maven2/':
        parser.error('Only the reviewed Maven Central repository is supported')
    if spec['prefix'] != 'maven-repository':
        parser.error('Unexpected archive prefix')
    entries = spec['artifacts']
    paths = [e['path'] for e in entries]
    if len(paths) != len(set(paths)):
        parser.error('Duplicate artifact paths')
    for name in paths:
        p = PurePosixPath(name)
        if p.is_absolute() or '..' in p.parts or p.suffix not in ('.jar', '.pom'):
            parser.error(f'Unexpected artifact path: {name}')
        if (p.parts[:3] == ('es', 'gob', 'afirma') and p.parts[3] not in ('lib', 'jmulticard')
                or p.parts[:3] == ('org', 'java-websocket', 'Java-WebSocket')):
            parser.error(f'Application build output must not be bundled: {name}')
    temporary = args.output.with_name(args.output.name + '.partial')
    if args.output.exists() or temporary.exists():
        parser.error('Output or partial output already exists')

    def prepare(entry):
        path = args.repository / entry['path']
        if not path.exists() and args.fetch:
            for attempt in range(3):
                try:
                    with urlopen(spec['repository'] + entry['path'], timeout=60) as response:
                        data = response.read()
                    if hashlib.sha256(data).hexdigest() != entry['sha256']:
                        raise ValueError(f'Download checksum mismatch: {path}')
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(data)
                    break
                except OSError:
                    if attempt == 2:
                        raise
                    time.sleep(2 ** attempt)
        if hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
            raise ValueError(f'Artifact checksum mismatch: {path}')

    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(prepare, entries))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    try:
        with temporary.open('xb') as destination:
            compressor = subprocess.Popen(['xz', '-T2', '-3', '-c'], stdin=subprocess.PIPE,
                                          stdout=destination)
            try:
                with tarfile.open(fileobj=compressor.stdin, mode='w|', format=tarfile.GNU_FORMAT) as archive:
                    for entry in sorted(entries, key=lambda e: e['path']):
                        path = args.repository / entry['path']
                        info = tarfile.TarInfo(f"maven-repository/{entry['path']}")
                        info.size, info.mode = path.stat().st_size, 0o644
                        with path.open('rb') as source:
                            archive.addfile(info, source)
                    # Supply fixed version-range metadata from reviewed versions only.
                    # No mutable Maven Central metadata is fetched or bundled.
                    groups = defaultdict(set)
                    for entry in entries:
                        path = PurePosixPath(entry['path'])
                        groups[path.parent.parent.as_posix()].add(path.parent.name)
                    for name, versions in sorted(groups.items()):
                        path = PurePosixPath(name)
                        metadata = ET.Element('metadata')
                        ET.SubElement(metadata, 'groupId').text = '.'.join(path.parts[:-1])
                        ET.SubElement(metadata, 'artifactId').text = path.name
                        versioning = ET.SubElement(metadata, 'versioning')
                        values = ET.SubElement(versioning, 'versions')
                        for version in sorted(versions):
                            ET.SubElement(values, 'version').text = version
                        ET.SubElement(versioning, 'lastUpdated').text = '19700101000000'
                        data = ET.tostring(metadata, encoding='utf-8', xml_declaration=True)
                        info = tarfile.TarInfo(f'maven-repository/{name}/maven-metadata-local.xml')
                        info.size, info.mode = len(data), 0o644
                        archive.addfile(info, io.BytesIO(data))
            finally:
                compressor.stdin.close()
                status = compressor.wait()
            if status:
                raise RuntimeError(f'xz exited with status {status}')
        temporary.rename(args.output)
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise
    print(f'{len(entries)} verified external Maven artifacts: {args.output}')
    print(f'SHA256 {hashlib.sha256(args.output.read_bytes()).hexdigest()}')


if __name__ == '__main__':
    main()
