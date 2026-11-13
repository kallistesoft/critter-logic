#!/usr/bin/env python3
"""Checks store/listing.json against Google Play's limits.

Run from the repo root: python3 store/check_listing.py
Exits with status 1 if a field is missing, too long, or uses wording Play rejects.
"""
import json
import re
import sys
import unicodedata
from pathlib import Path

LOCALES = ['en-US', 'fr-CA', 'fr-FR', 'es-419', 'es-ES', 'es-US', 'de-DE', 'it-IT', 'pt-BR', 'nl-NL', 'pl-PL',
           'tr-TR', 'ru-RU', 'id', 'vi', 'th', 'ja-JP', 'ko-KR', 'zh-TW', 'hi-IN']
LIMITS = {'title': 30, 'short': 80, 'full': 4000, 'releaseNotes': 500}
REQUIRED = ('title', 'short', 'full')
NOTES_LOCALES = ('en-US', 'fr-CA', 'fr-FR', 'es-419', 'es-ES', 'es-US')
# Play's metadata policy: no ranking or promo claims in the title or short description.
BANNED = re.compile(r'#\s*1|\bbest\b|\btop\b|\bfree\b|\bno ads\b|\bsale\b|\bdiscount\b', re.IGNORECASE)


def length(text):
    """Characters as Play counts them (Unicode code points, NFC)."""
    return len(unicodedata.normalize('NFC', text))


def main():
    path = Path(__file__).with_name('listing.json')
    data = json.loads(path.read_text(encoding='utf-8'))
    errors = []
    missing = [loc for loc in LOCALES if loc not in data]
    extra = [loc for loc in data if loc not in LOCALES]
    if missing:
        errors.append(f'missing locales: {", ".join(missing)}')
    if extra:
        errors.append(f'unexpected locales: {", ".join(extra)}')

    print(f'{"locale":<7} {"title":>8} {"short":>8} {"full":>10} {"notes":>8}')
    for loc in LOCALES:
        entry = data.get(loc, {})
        cells = []
        for field, limit in LIMITS.items():
            value = entry.get(field)
            if value is None:
                if field in REQUIRED or (field == 'releaseNotes' and loc in NOTES_LOCALES):
                    errors.append(f'{loc}: {field} missing')
                cells.append('-')
                continue
            n = length(value)
            if n > limit:
                errors.append(f'{loc}: {field} is {n} chars (max {limit})')
            if value != value.strip():
                errors.append(f'{loc}: {field} has leading/trailing whitespace')
            if field in ('title', 'short') and BANNED.search(value):
                errors.append(f'{loc}: {field} uses promo wording: {BANNED.search(value).group(0)!r}')
            cells.append(f'{n}/{limit}')
        title = entry.get('title', '')
        if not title.startswith('Critter Logic'):
            errors.append(f'{loc}: title must start with the brand "Critter Logic"')
        print(f'{loc:<7} {cells[0]:>8} {cells[1]:>8} {cells[2]:>10} {cells[3]:>8}')

    if errors:
        print('\nFAIL')
        for e in errors:
            print(f'  {e}')
        return 1
    print(f'\nOK: {len(LOCALES)} locales within limits')
    return 0


if __name__ == '__main__':
    sys.exit(main())
