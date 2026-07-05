# Plano de Execução - Issue #9: [Design System] Implementar a Identidade Visual do App no Flutter

## Objetivo
Implementar a identidade visual base no aplicativo Flutter (`app/`), configurando o tema (`ThemeData`), fontes, cores e componentes de botões reutilizáveis (Primary, Secondary, Teal/Accent), além da validação via Widget Tests.

## Dependências
- Conclusão da Issue #1 (Monorepo Setup).

## Divisão de Tarefas

### DEV-FRONT
1. Adicionar o pacote `google_fonts` (para utilizar a fonte **Poppins**) no arquivo `pubspec.yaml` do app.
2. Criar a pasta `lib/theme/` e adicionar:
   - `app_colors.dart`: Contendo a paleta de cores em formato hexadecimal (`#0D1B2A`, `#1B4965`, `#2EC4B6`, `#E0E7EF`, `#F7F9FC`).
   - `app_theme.dart`: ThemeData configurando cores primárias/secundárias, tipografia Poppins e estilos globais de inputs.
3. Criar a pasta `lib/widgets/` e adicionar:
   - `custom_button.dart`: Um widget de botão customizado que aceite tipos (ex: `CustomButtonType.primary`, `.secondary`, `.accent`) e configure as cores, bordas arredondadas e textos apropriados.
4. Ajustar o `lib/main.dart` para exibir uma tela temporária de catálogo (Styleguide) que liste as cores, tipografias e botões implementados.
5. Criar testes de Widget em `test/widgets/custom_button_test.dart` para validar se os botões renderizam com os estilos corretos do tema.

### QA
1. Rodar `flutter test` na pasta `app/` para validar a implementação técnica dos testes criados.
2. Validar visualmente o catálogo de componentes para confirmar se as cores e fontes condizem com a imagem fornecida.
3. Emitir o relatório de QA atestando a qualidade e fidelidade ao design.

## Critérios de Aceite (Acceptance Criteria)
- Cores hexadecimais configuradas conforme a imagem da identidade visual.
- Fonte Poppins integrada e configurada no tema.
- Widget de botão implementado com suporte aos 3 estilos visuais.
- Tela de catálogo exibindo todos os componentes e variações.
- Testes de Widgets implementados e cobrindo os botões e tema.
- Todos os testes passando sem erros.

## Definition of Done (DoD)
- Código fonte e testes criados.
- Testes locais passando via CLI.
- QA aprovou a implementação.
- Alterações enviadas à branch `main` do GitHub.
