#!/usr/bin/env python3
"""Repo-Prüfung (läuft lokal und in der CI): Struktur, Versionen, Changelog, Locale-Schlüssel.

Aufruf:  python3 tools/check.py [--tag v0.2.1-alpha.1]
Ohne --tag wird die Version aus den TOCs genommen. Rückgabewert 0 = in Ordnung.
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TAG_RE = re.compile(r'^v(\d+)\.(\d+)\.(\d+)-(alpha|beta|latest)\.(\d+)$')
errors = []


def error(message):
    errors.append(message)


def addon_dirs():
    return sorted(p.parent for p in ROOT.glob('*/*.toc') if p.parent.name == p.stem)


def toc_version(toc):
    match = re.search(r'^## Version:\s*(\S+)', toc.read_text(encoding='utf-8'), re.M)
    return match.group(1) if match else None


def check_structure():
    for folder in sorted(p for p in ROOT.iterdir() if p.is_dir() and not p.name.startswith('.')):
        if folder.name in ('docs', 'tests', 'tools'):
            continue
        if not (folder / f'{folder.name}.toc').exists():
            error(f'{folder.name}: keine gleichnamige TOC ({folder.name}/{folder.name}.toc)')
    for dev in ('README.md', 'CHANGELOG.md', '.pkgmeta', '.luacheckrc'):
        if not (ROOT / dev).exists():
            error(f'{dev} fehlt im Repo-Stamm')
    for forbidden in ('README.md', 'CHANGELOG.md', 'docs', 'tests', 'tools', '.github'):
        for addon in addon_dirs():
            if (addon / forbidden).exists():
                error(f'{addon.name}/{forbidden}: Dev-Dateien gehören neben, nicht in den Addon-Ordner')


def check_versions(tag):
    versions = {a.name: toc_version(a / f'{a.name}.toc') for a in addon_dirs()}
    if len(set(versions.values())) != 1:
        error(f'## Version in den TOCs ist nicht überall gleich: {versions}')
    version = next(iter(versions.values()), None)
    if tag:
        match = TAG_RE.match(tag)
        if not match:
            error(f'Tag {tag}: erwartet vX.Y.Z-PHASE.N (PHASE alpha, beta oder latest)')
            return
        expected = tag[1:]
        if version != expected:
            error(f'TOC-Version {version} entspricht nicht dem Tag {tag}')
        z_version = '.'.join(match.groups()[:3])
        changelog = (ROOT / 'CHANGELOG.md').read_text(encoding='utf-8')
        if not re.search(rf'^##\s+v?{re.escape(z_version)}\b', changelog, re.M):
            error(f'CHANGELOG.md hat keinen Abschnitt für {z_version}')


def check_curse_id():
    for addon in addon_dirs():
        text = (addon / f'{addon.name}.toc').read_text(encoding='utf-8')
        if addon.name == 'CantPlayForever' and not re.search(r'^## X-Curse-Project-ID:\s*\d+', text, re.M):
            print('Hinweis: CantPlayForever.toc hat noch keine X-Curse-Project-ID (Upload wird übersprungen).')


def lua_files():
    return [p for p in ROOT.rglob('*.lua') if '/Libs/' not in p.as_posix()]


LUA_TOKEN = re.compile(
    r"--\[(=*)\[.*?\]\1\]|\[(=*)\[.*?\]\2\]|--[^\n]*|'(?:\\.|[^'\\\n])*'|\"(?:\\.|[^\"\\\n])*\"",
    re.S,
)


def strip_lua(text):
    def repl(match):
        token = match.group(0)
        return '' if token.startswith('--') else '""'
    return LUA_TOKEN.sub(repl, text)


def check_lua_balance():
    for path in lua_files():
        text = strip_lua(path.read_text(encoding='utf-8'))
        for open_c, close_c in ('()', '{}', '[]'):
            if text.count(open_c) != text.count(close_c):
                error(f'{path.relative_to(ROOT)}: {open_c}{close_c} nicht ausgeglichen')
        opens = len(re.findall(r'\b(?:function|if|for|while)\b', text)) + len(re.findall(r'(?m)^\s*do\b', text))
        if opens != len(re.findall(r'\bend\b', text)):
            error(f'{path.relative_to(ROOT)}: function/if/for/while und end passen nicht zusammen')


def locale_keys(path):
    return set(re.findall(r'^L\.(\w+)\s*=', path.read_text(encoding='utf-8'), re.M))


def check_locales():
    for folder in ROOT.rglob('Locales'):
        if '/Libs/' in folder.as_posix():
            continue
        sets = {n: locale_keys(folder / f'{n}.lua') for n in ('enUS', 'deDE', 'frFR') if (folder / f'{n}.lua').exists()}
        base = sets.get('enUS')
        for name, keys in sets.items():
            if base is not None and keys != base:
                missing, extra = sorted(base - keys), sorted(keys - base)
                error(f'{folder.relative_to(ROOT)}/{name}.lua: fehlt {missing} / zu viel {extra}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--tag')
    args = parser.parse_args()
    check_structure()
    check_versions(args.tag)
    check_curse_id()
    check_lua_balance()
    check_locales()
    for message in errors:
        print('FEHLER:', message)
    print('OK' if not errors else f'{len(errors)} Fehler')
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
