#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Create a separate ebuild candidate using a registry crate source archive."""
import argparse
from pathlib import Path
import re
from urllib.parse import urlsplit

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ebuild', required=True, type=Path)
parser.add_argument('--archive-uri', required=True)
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
uri = args.archive_uri
if (urlsplit(uri).scheme not in ('https', 'http') or not urlsplit(uri).hostname
        or not re.fullmatch(r'[A-Za-z0-9._~:/%+?=&-]+', uri)):
    parser.error('Expected an HTTP(S) URL without shell metacharacters')
text = args.ebuild.read_text()
text, count = re.subn(r'^CRATES="\n.*?^"\n\n', '', text, flags=re.M | re.S)
if count != 1:
    parser.error('Expected exactly one multiline CRATES assignment')
needle = '\t${CARGO_CRATE_URIS}'
if text.count(needle) != 1:
    parser.error('Expected one CARGO_CRATE_URIS entry in SRC_URI')
package = re.sub(r'-r[0-9]+$', '', args.ebuild.stem)
archive_name = f'{package}-crates.tar.xz'
entry = uri.replace(package, '${P}')
if urlsplit(uri).path.rsplit('/', 1)[-1] != archive_name:
    entry += ' -> ${P}-crates.tar.xz'
text = text.replace(needle, f'\t{entry}\n' + needle)
args.output.parent.mkdir(parents=True, exist_ok=True)
with args.output.open('x') as output:
    output.write(text)
print(args.output)
