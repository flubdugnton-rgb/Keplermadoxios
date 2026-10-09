#!/bin/bash
set -euo pipefail
for path in project.yml Sources/App/KepleraeApp.swift Sources/App/RootView.swift Sources/Views/Pomodoro/PomodoroView.swift Sources/Views/Questions/QuestionsView.swift Sources/Views/Notes/NotesView.swift Sources/Views/Profile/ProfileSettingsView.swift Resources/catalog.json Resources/Info.plist Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png Resources/Assets.xcassets/KepleraeLogo.imageset/keplerae_logo.png Resources/Assets.xcassets/PomodoroRest.imageset/pomo_rest.png Resources/Assets.xcassets/PomodoroFishing.imageset/pomo_fishing.png; do
  test -e "$path" || { echo "Faltando: $path"; exit 1; }
done
python3 - <<'PY'
import json
from pathlib import Path
p=Path('Resources/catalog.json')
data=json.loads(p.read_text(encoding='utf-8'))
assert isinstance(data,list) and len(data)>=1000, 'catálogo incompleto'
print('Catálogo:',len(data),'itens')
PY
echo "Estrutura Kepleræ 1.2 validada."
