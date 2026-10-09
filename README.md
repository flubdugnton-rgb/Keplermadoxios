# Kepleræ iOS

Port nativo em SwiftUI do Kepleræ para iOS 27.

## Implementado nesta etapa

- Estrutura modular SwiftUI.
- Navegação por Início, Biblioteca, Progresso e Ajustes.
- Matérias: Fisioterapia, Português, Matemática e Raciocínio Lógico, HU — Legislação e SUS.
- Áreas de Aulas, PDFs e Áudios.
- Player interno baseado em `WKWebView` para links de preview do Google Drive.
- Liquid Glass com `glassEffect` e `GlassEffectContainer`.
- Controle em roda de 0% a 100% para intensidade visual do vidro.
- Versão 1.0.
- Workflow GitHub Actions em `xcode-27` para gerar `Keplerae-1.0-unsigned.ipa`.

## Importante

O catálogo real, IDs de arquivos, regras de navegação e demais comportamentos ainda precisam ser importados da versão Android `Keplerae-1.0.1`. Esta etapa evita inventar dados que não foram lidos do projeto Android.

## Build

O GitHub Actions gera o projeto Xcode com XcodeGen, compila para `iphoneos` com assinatura desabilitada e empacota o `.app` dentro de `Payload` para produzir o IPA sem assinatura.
