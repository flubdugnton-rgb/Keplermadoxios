# Kepleræ iOS 1.3

Versão 1.3 do Kepleræ para iOS 27 em SwiftUI.

## Correções principais

- recursos agora entram de verdade no bundle do app via XcodeGen: catálogo, Assets.xcassets e áudios;
- catálogo completo com 1.022 materiais: 703 aulas, 306 PDFs e 13 áudios;
- ícone oficial Kepleræ aplicado ao app e à tela de login;
- nova tela de login com composição Apple/Liquid Glass e Google Sign-In oficial;
- barra inferior com Liquid Glass nativo, seleção interativa e morphing via `glassEffectID`;
- tocar novamente em **Início** reinicia a NavigationStack e volta à tela principal;
- Pomodoro com artes `PomodoroRest` e `PomodoroFishing`, movimento, estrelas e órbita animada;
- sons ambientes empacotados e com prévia imediata nos ajustes;
- tema claro/escuro/sistema aplicado também à folha de Perfil, sem aparência dividida;
- animações próprias do sol e da lua ao trocar tema;
- fundos reimplementados com gradientes radiais para reduzir custo de blur e melhorar fluidez;
- espaçamento inferior reforçado para conteúdo não ficar escondido atrás da barra.

## Conteúdo

O `Resources/catalog.json` contém os dados consolidados das planilhas usadas no projeto:

- Português: 356 materiais;
- Profisio: 311 materiais;
- Fisioterapia: 170 materiais;
- SUS: 135 materiais;
- HU Legislação: 33 materiais;
- Matemática e Raciocínio Lógico: 17 materiais.

Total: **1.022** materiais.

## Build

- Bundle ID: `com.aistudio.keplerae.stdy.ios`
- Versão: 1.3
- Build: 4
- Target mínimo: iOS 27
- Swift 6
- GoogleSignIn 10.0.0
