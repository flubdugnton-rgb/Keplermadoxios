#!/bin/bash
set -euo pipefail

required=(
  project.yml
  Sources/App/KepleraeApp.swift
  Sources/App/RootView.swift
  Sources/Design/GlassStyle.swift
  Sources/Data/CatalogStore.swift
  Sources/Views/Home/HomeView.swift
  Sources/Views/Settings/SettingsView.swift
)

for file in "${required[@]}"; do
  test -f "$file" || { echo "Arquivo ausente: $file"; exit 1; }
done

echo "Estrutura do projeto OK."
