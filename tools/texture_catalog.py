"""Inspect repeated SignalTextures sections and retain state declaration order."""
import argparse
import base64
import html
import json
import mimetypes
from pathlib import Path


def sections(path):
    result, current = [], None
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        line = line.strip()
        if not line or line.startswith(('#', ';')):
            continue
        if line.startswith('[') and line.endswith(']'):
            current = {'section': line[1:-1], 'fields': []}
            result.append(current)
        elif current is not None and '=' in line:
            key, value = line.split('=', 1)
            current['fields'].append((key.strip(), value.strip()))
    return result


def catalog(root):
    root = root.resolve()
    result = []
    for section in sections(root/'mod.txt'):
        if section['section'] != 'SignalTextures':
            continue
        fields = section['fields']
        states = []
        for key, value in fields:
            if key != 'state':
                continue
            path = (root/value.replace('\\','/')).resolve()
            if not path.is_relative_to(root):
                raise ValueError(f'Texture outside mod: {value}')
            states.append({'index':len(states), 'relativePath':value,
                           'path':str(path), 'exists':path.is_file()})
        result.append({'id':dict(fields).get('id'),
                       'name':dict(fields).get('name_en'), 'states':states})
    return result


def render(items):
    cards = []
    for item in items:
        cards.append('<h2>'+html.escape(item['name'] or item['id'] or 'Sans nom')+'</h2><div class="grid">')
        for state in item['states']:
            path = Path(state['path'])
            image = 'Fichier absent'
            if state['exists']:
                mime = mimetypes.guess_type(path.name)[0] or ''
                if mime in ('image/svg+xml','image/png','image/jpeg','image/webp'):
                    data = base64.b64encode(path.read_bytes()).decode('ascii')
                    image = f'<img src="data:{mime};base64,{data}" alt="État {state["index"]}">'
            cards.append(f'<article>{image}<strong>Index {state["index"]}</strong><code>{html.escape(state["relativePath"])}</code></article>')
        cards.append('</div>')
    return '<!doctype html><meta charset="utf-8"><title>SFR · Catalogue des textures</title><style>body{font:16px system-ui;background:#101b2b;color:#e5eefb;padding:32px}.grid{display:flex;flex-wrap:wrap;gap:14px}article{width:180px;padding:14px;background:#20324b;display:grid;gap:12px}img{width:96px;height:96px;object-fit:contain}code{overflow-wrap:anywhere}</style><h1>Signalisation française réaliste</h1><p>Index dans le mod ; la signification ferroviaire doit être définie séparément.</p>'+''.join(cards)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('mod', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    items = catalog(args.mod)
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output/'textures.json').write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf8')
    (args.output/'index.html').write_text(render(items),encoding='utf8')
    missing = sum(not s['exists'] for item in items for s in item['states'])
    print(f'{len(items)} texture sets; {missing} missing files')
    raise SystemExit(1 if missing else 0)
