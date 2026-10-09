#!/bin/bash
set -euo pipefail

for path in \
  project.yml \
  Sources/App/KepleraeApp.swift \
  Sources/App/RootView.swift \
  Sources/Auth/GoogleAuthStore.swift \
  Sources/Views/Auth/LoginView.swift \
  Sources/Views/Pomodoro/PomodoroView.swift \
  Sources/Views/Questions/QuestionsView.swift \
  Sources/Views/Notes/NotesView.swift \
  Sources/Views/Profile/ProfileSettingsView.swift \
  Resources/catalog.json \
  Resources/Info.plist \
  Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
  Resources/Assets.xcassets/KepleraeLogo.imageset/keplerae_logo.png \
  Resources/Assets.xcassets/PomodoroRest.imageset/pomo_rest.png \
  Resources/Assets.xcassets/PomodoroFishing.imageset/pomo_fishing.png \
  Resources/Sounds/ambient_clock.m4a \
  Resources/Sounds/ambient_wind.m4a \
  Resources/Sounds/ambient_rain.m4a \
  Resources/Sounds/ambient_storm.m4a \
  Resources/Sounds/ambient_fire.m4a \
  Resources/Sounds/ambient_library.m4a \
  Resources/Sounds/ambient_room.m4a; do
  test -e "$path" || { echo "Faltando: $path"; exit 1; }
done

python3 - <<'PY'
import json
from collections import Counter
from pathlib import Path

p=Path('Resources/catalog.json')
data=json.loads(p.read_text(encoding='utf-8'))
assert isinstance(data,list), 'catálogo inválido'
assert len(data)==1022, f'catálogo incompleto: {len(data)}'
assert Counter(x['type'] for x in data)==Counter({'VIDEO':703,'PDF':306,'AUDIO':13})
assert Counter(x['subjectId'] for x in data)==Counter({
    'portugues':356,
    'profisio':311,
    'fisioterapia':170,
    'sus':135,
    'hu_legislacao':33,
    'matematica':17,
})
print('Catálogo: 1.022 itens (703 aulas, 306 PDFs, 13 áudios)')
PY

echo "Estrutura Kepleræ 1.3 validada."
