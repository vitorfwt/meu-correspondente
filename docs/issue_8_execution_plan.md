# Plano de Execução - Issue #8: [App] Resultado e Restrições com Testes de Renderização

## Objetivo
Integrar o aplicativo Flutter com a API de simulação do backend, substituindo a lógica local mockada do repositório por chamadas HTTP reais para o endpoint `POST /api/simulate`. Adicionar tratamento visual de restrições de crédito (renda comprometida e idade limite) e testes de widget correspondentes mockando o serviço HTTP.

## Dependências
- Conclusão da Issue #9 (Design System), Issue #6 (Login), Issue #7 (Formulário do Simulador) no frontend e Issue #4 (API do Simulador) no backend.

## Divisão de Tarefas

### DEV-FRONT
1. Adicionar o pacote `http` (ou similar) no `pubspec.yaml` do app.
2. Atualizar o repositório de simulação (`lib/simulation/simulation_repository.dart`) para fazer uma chamada HTTP real `POST /api/simulate` enviando os dados do formulário e o token JWT do usuário logado (passado através do `AuthProvider`).
3. Atualizar a tela de resultados (`lib/screens/simulation_result_screen.dart`) para exibir a lista de bancos retornada pelo backend.
4. Implementar a renderização visual das restrições:
   - Bancos sem restrição: Exibir normalmente (conforme o design, destacando a melhor opção).
   - Bancos com restrição (comprometimento de renda ou idade limite): Exibir com um layout visual de alerta (ex: borda laranja/vermelha, tag "Restrição: Parcela > 30% da renda" ou "Restrição: Idade Limite Ultrapassada", opacidade reduzida).
5. Implementar tratamento de estados de carregamento (shimmer ou spinner) e erros de rede na tela de resultados.
6. Escrever testes de widget em `test/screens/simulation_result_screen_test.dart` mockando o cliente HTTP para testar:
   - Renderização correta dos cards de bancos com dados da API.
   - Renderização dos alertas visuais de restrição de crédito (renda e idade).
   - Comportamento ao ocorrer erro de conexão com a API (exibição de botão para tentar novamente).

### QA
- Validar se os dados exibidos na tela de resultados batem exatamente com as simulações retornadas pela API.
- Testar a renderização visual dos alertas de restrição gerando simulações com renda muito baixa ou idade elevada no emulador.
- Executar os testes de widget e integração criados (`C:\src\flutter\bin\flutter.bat test`) e validar se passam.
- Capturar prints das telas de resultados (com e sem restrições) para anexar ao relatório.

## Critérios de Aceite (Acceptance Criteria)
- A tela de resultados deve consumir a API real via HTTP.
- Os alertas visuais de restrição (renda e idade) devem ser exibidos de forma clara nos cards dos bancos correspondentes.
- Testes automatizados mockando chamadas HTTP implementados e passando sem falhas.

## Definition of Done (DoD)
- Integração da API, tratamento visual de restrições e testes de widget implementados.
- Testes passando com sucesso localmente.
- QA validou a tela de resultados e alertas visuais no emulador e registrou o relatório com prints.
- Alterações enviadas à branch `main` no GitHub.
