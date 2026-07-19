from pathlib import Path
import re

app_path = Path(r'd:\smartex_work\sitelink\lib\core\constants\app_strings.dart')
text = app_path.read_text(encoding='utf-8')
entries = []
for line in text.splitlines():
    if 'static const String' not in line:
        entries.append((line, None, None, None, None))
        continue
    left, right = line.split('=', 1)
    old = left.replace('static const String', '').strip()
    val = right.strip().rstrip(';').strip()
    if val.startswith("'") and val.endswith("'"):
        val = val[1:-1]
    if not val:
        new = old
    else:
        val_mod = val
        if val_mod[0].isdigit():
            for digit, word in [('1','One'),('2','Two'),('3','Three'),('4','Four'),('5','Five'),('6','Six'),('7','Seven'),('8','Eight'),('9','Nine'),('0','Zero')]:
                val_mod = re.sub(rf'\b{digit}\b', word, val_mod)
        parts = re.findall(r'[A-Za-z0-9]+', val_mod)
        new = ''.join((p[0].upper()+p[1:]) if p else '' for p in parts) or old
    entries.append((line, old, new, val, right))

new_names = {}
used = {}
for line, old, new, val, right in entries:
    if old is None:
        continue
    if new in used:
        new_names[old] = used[new]
    else:
        used[new] = new
        new_names[old] = new

seen_new = set()
new_lines = []
for line, old, new, val, right in entries:
    if old is None:
        new_lines.append(line)
        continue
    if new in seen_new:
        continue
    seen_new.add(new)
    prefix = line.split('=')[0].replace(old, new, 1)
    new_line = prefix + '= ' + right.strip()
    new_lines.append(new_line)

backup = app_path.with_suffix('.dart.bak')
backup.write_text(text, encoding='utf-8')
app_path.write_text('\n'.join(new_lines) + '\n', encoding='utf-8')

root = Path(r'd:\smartex_work\sitelink')
repl_files = 0
for file in root.rglob('*.dart'):
    if any(part in ('build','generated') for part in file.parts):
        continue
    content = file.read_text(encoding='utf-8')
    updated = content
    for old, new in new_names.items():
        if old == new:
            continue
        updated = updated.replace(f'AppStrings.{old}', f'AppStrings.{new}')
    if updated != content:
        file.write_text(updated, encoding='utf-8')
        repl_files += 1

print('Done')
print('Total constants', len(new_names))
print('Touched Dart files', repl_files)
print('Mappings:')
for old, new in new_names.items():
    if old != new:
        print(f'{old} -> {new}')
