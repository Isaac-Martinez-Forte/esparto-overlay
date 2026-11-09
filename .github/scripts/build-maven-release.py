#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Recreate the reviewed AutoFirma Maven dependency archive for a Release."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--version', required=True)
parser.add_argument('--workdir', required=True, type=Path)
args = parser.parse_args()
if not re.fullmatch(r'[0-9]+(?:\.[0-9]+)+', args.version):
    parser.error('Expected a numeric release version')
root = Path(__file__).resolve().parents[2]
inventory = root / '.github/maven-bundles' / f'autofirma-{args.version}.json'
spec = json.loads(inventory.read_text())
work = args.workdir.resolve()
work.mkdir(parents=True, exist_ok=True)
output = work / f'autofirma-{args.version}-maven-deps.tar.xz'
if not output.exists():
    subprocess.run([sys.executable, str(root / '.github/scripts/bundle-maven.py'),
                    '--inventory', str(inventory), '--repository', str(work / 'repository'),
                    '--output', str(output), '--fetch'], check=True)
if hashlib.sha256(output.read_bytes()).hexdigest() != spec['bundle_sha256']:
    raise ValueError('Generated Maven repository differs from the reviewed archive')
(work / 'SHA256SUMS').write_text(f"{spec['bundle_sha256']}  {output.name}\n")
print(f'Reviewed Maven dependency archive verified: {output}')
