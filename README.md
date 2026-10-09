# Kepleræ iOS 1.2

Versão nativa em SwiftUI para iOS 27, com identidade visual Apple e conteúdo migrado do projeto Android.

## Destaques da 1.2

- Login real com Google via OAuth 2.0 + PKCE usando o Client ID iOS do projeto.
- Tela de login dedicada; sem campos manuais de e-mail/senha.
- Perfil com nome, e-mail e foto retornados pelo Google.
- Client ID iOS configurado para `com.aistudio.keplerae.stdy.ios`.
- Catálogo completo com mais de 1.000 materiais e navegação por pastas.
- Filtros Todos, Favoritos, Pendentes e Concluídos + formatos Aulas/PDFs/Áudios.
- Estado local de favoritos, concluídos e último conteúdo aberto.
- Home mais rica visualmente, mantendo SwiftUI/Liquid Glass em vez de copiar Material Design.
- Pomodoro redesenhado com artes originais, animações e sons ambientes convertidos para formatos compatíveis com iOS.
- Perfil/Ajustes com tema, Liquid Glass, Google, exportação/importação e desconectar.
- Versão 1.2, build 3.

## Google OAuth

Client ID iOS configurado no `Resources/Info.plist`:

`240965240632-re20f1uta49pcuorpveqabrvii76r8o9.apps.googleusercontent.com`

URL scheme reverso:

`com.googleusercontent.apps.240965240632-re20f1uta49pcuorpveqabrvii76r8o9`

O login usa o SDK oficial `GoogleSignIn-iOS` 10.0.0, que inclui suporte ao Xcode 27. O app solicita o escopo `drive.file` além do perfil básico do Google.
