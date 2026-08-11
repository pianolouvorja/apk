#!/usr/bin/env python3
"""Remove arquivos com coverage:ignore-file do lcov.info."""
import sys
from pathlib import Path

lcov = Path('coverage/lcov.info')
if not lcov.exists():
    sys.exit(0)

content = lcov.read_text()
suffixes_to_remove = set()

for src in Path('lib').rglob('*.dart'):
    first_lines = src.read_text()[:500]
    if 'coverage:ignore-file' in first_lines:
        # lcov usa paths relativos: lib/core/services/player_native.dart
        suffixes_to_remove.add(str(src).replace('\\', '/'))

if not suffixes_to_remove:
    sys.exit(0)

blocks = content.split('end_of_record\n')
filtered = []
removed = 0
for block in blocks:
    skip = False
    for line in block.split('\n'):
        if line.startswith('SF:'):
            fpath = line[3:].strip().replace('\\', '/')
            for suffix in suffixes_to_remove:
                # suffix e tipo /home/.../lib/core/... 
                # fpath e tipo lib/core/...
                if fpath.endswith(suffix.split('lib/')[-1] if 'lib/' in suffix else suffix):
                    skip = True
                    removed += 1
                    break
            break
    if not skip:
        filtered.append(block)

lcov.write_text('end_of_record\n'.join(filtered))
print(f'Removed {removed} files from lcov.info')
