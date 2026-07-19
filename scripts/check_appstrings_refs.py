from pathlib import Path
import re

app_path = Path(r'd:\smartex_work\sitelink\lib\core\constants\app_strings.dart')
text = app_path.read_text(encoding='utf-8')
constants = set(re.findall(r"static const (?:String|List<[^>]+>) ([A-Za-z0-9_]+)\s*=", text))

root = Path(r'd:\smartex_work\sitelink')
refs = {}
for file in root.rglob('*.dart'):
    if any(part in ('build', 'generated') for part in file.parts):
        continue
    content = file.read_text(encoding='utf-8')
    for match in re.finditer(r'AppStrings\.([A-Za-z0-9_]+)', content):
        name = match.group(1)
        if name == '_':
            continue
        if name not in constants:
            refs.setdefault(name, []).append(str(file) + ':' + str(match.start()))

print('Missing references:')
for name, locs in refs.items():
    print(name)
    for loc in locs[:10]:
        print('  ', loc)
print('Total missing:', len(refs))
