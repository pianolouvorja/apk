#!/usr/bin/env python3
"""Remove arquivos e linhas com coverage:ignore-* do lcov.info.

Processa:
1. coverage:ignore-file -- remove o arquivo inteiro do lcov
2. coverage:ignore-start/end -- remove linhas dentro do bloco
3. coverage:ignore-line -- remove a linha SEGUINTE (commento acima do alvo)
"""
import re
import sys
from pathlib import Path

lcov_path = Path('coverage/lcov.info')
if not lcov_path.exists():
    sys.exit(0)

content = lcov_path.read_text()

# --- Phase 1: Collect ignore ranges per source file ---
# {filepath: set of line numbers to remove}
ignore_lines = {}

for src in Path('lib').rglob('*.dart'):
    fpath = str(src)
    text = src.read_text()
    lines = text.splitlines()

    lines_to_ignore = set()

    # coverage:ignore-file -> skip entire file
    if 'coverage:ignore-file' in text[:500]:
        # Mark all DA lines for this file
        ignore_lines[fpath] = 'ALL'
        continue

    # coverage:ignore-start / coverage:ignore-end
    in_block = False
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if 'coverage:ignore-start' in stripped:
            in_block = True
            continue
        if 'coverage:ignore-end' in stripped:
            in_block = False
            continue
        if in_block:
            lines_to_ignore.add(i)

    # coverage:ignore-line -> remove the NEXT non-comment line
    for i, line in enumerate(lines):
        if 'coverage:ignore-line' in line.strip():
            # Find the next code line (not a comment, not empty)
            for j in range(i + 1, min(i + 5, len(lines))):
                next_stripped = lines[j].strip()
                if next_stripped and not next_stripped.startswith('//'):
                    lines_to_ignore.add(j + 1)  # 1-indexed
                    break

    if lines_to_ignore:
        ignore_lines[fpath] = lines_to_ignore

if not ignore_lines:
    sys.exit(0)

# --- Phase 2: Filter lcov.info ---
blocks = content.split('end_of_record\n')
filtered = []
removed_files = 0
removed_lines = 0

for block in blocks:
    sf_match = None
    for line in block.split('\n'):
        if line.startswith('SF:'):
            sf_match = line[3:].strip()
            break

    if sf_match is None:
        filtered.append(block)
        continue

    # Check if this file should be fully removed
    skip_file = False
    matched_key = None
    for key in ignore_lines:
        # Normalize paths for comparison
        norm_sf = sf_match.replace('\\', '/')
        norm_key = key.replace('\\', '/')
        if norm_sf.endswith(norm_key.split('lib/')[-1] if 'lib/' in norm_key else norm_key):
            matched_key = key
            if ignore_lines[key] == 'ALL':
                skip_file = True
                removed_files += 1
            break

    if skip_file:
        continue

    # Filter individual DA lines
    if matched_key and isinstance(ignore_lines[matched_key], set):
        lines_set = ignore_lines[matched_key]
        new_lines = []
        for line in block.split('\n'):
            if line.startswith('DA:'):
                lineno = int(line[3:].split(',')[0])
                if lineno in lines_set:
                    removed_lines += 1
                    continue  # Skip this line
            new_lines.append(line)
        block = '\n'.join(new_lines)

    filtered.append(block)

lcov_path.write_text('end_of_record\n'.join(filtered))
print(f'Removed {removed_files} files and {removed_lines} lines from lcov.info')
