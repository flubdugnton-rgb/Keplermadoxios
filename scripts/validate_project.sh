#!/bin/bash
set -euo pipefail

for path in \
  project.yml \
  Sources/App/KepleraeApp.swift \
  Sources/App/RootView.swift \
  Sources/Auth/GoogleAuthStore.swift \
  Sources/Data/DriveContentLoader.swift \
  Sources/Views/Player/DrivePlayerView.swift \
  Sources/Views/Components/AnimatedPNGView.swift \
  Sources/Views/Auth/LoginView.swift \
  Sources/Views/Pomodoro/PomodoroView.swift \
  Sources/Views/Questions/QuestionsView.swift \
  Sources/Views/Notes/NotesView.swift \
  Sources/Views/Profile/ProfileSettingsView.swift \
  Resources/catalog.json \
  Resources/Info.plist \
  Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
  Resources/Assets.xcassets/KepleraeLogo.imageset/keplerae_logo.png \
  Resources/Animations/pomodoro_rest.png \
  Resources/Animations/pomodoro_fishing.png \
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
assert isinstance(data,list)
assert len(data)==1022, len(data)
assert Counter(x['type'] for x in data)==Counter({'VIDEO':703,'PDF':306,'AUDIO':13})
assert Counter(x['subjectId'] for x in data)==Counter({'portugues':356,'profisio':311,'fisioterapia':170,'sus':135,'hu_legislacao':33,'matematica':17})
print('Catálogo validado:', len(data))
PY

grep -q 'tabViewStyle(.page' Sources/App/RootView.swift
grep -q 'glassEffect(.regular.interactive()' Sources/App/RootView.swift
grep -q 'Text("Perfil")' Sources/App/RootView.swift
if grep -q 'case subjects' Sources/App/RootView.swift; then echo 'ERRO: Biblioteca ainda está na barra'; exit 1; fi
if grep -q 'Tab("Biblioteca"' Sources/App/RootView.swift; then echo 'ERRO: Biblioteca ainda está na TabView'; exit 1; fi

grep -q 'AnimatedPNGView(resourceName: "pomodoro_rest")' Sources/Views/Pomodoro/PomodoroView.swift
grep -q 'AnimatedPNGView(resourceName: "pomodoro_fishing")' Sources/Views/Pomodoro/PomodoroView.swift
if find Resources/Animations -name '*.gif' | grep -q .; then echo 'ERRO: GIF antigo com matte preto ainda presente'; exit 1; fi

grep -q 'Authorization' Sources/Data/DriveContentLoader.swift
grep -q 'AVURLAssetHTTPHeaderFieldsKey' Sources/Views/Player/DrivePlayerView.swift
grep -q 'preferredForwardBufferDuration' Sources/Views/Player/DrivePlayerView.swift
grep -q 'fullScreenCover' Sources/Views/Player/DrivePlayerView.swift

echo 'Estrutura Kepleræ 1.5.1 validada.'
