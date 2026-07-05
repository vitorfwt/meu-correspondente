# Plano de Execução - Issue #7: [App] Formulário do Simulador com Testes de Validação

## Objetivo
Implementar a tela de entrada de dados do simulador de financiamento no app Flutter (`app/`), contendo campos de texto, sliders, validações de interface e testes de widget correspondentes. A comunicação com a API será mockada nesta etapa.

## Dependências
- Conclusão da Issue #9 (Design System) e Issue #6 (Tela de Login).

## Divisão de Tarefas

### DEV-FRONT
1. Criar a tela de formulário (`lib/screens/simulator_form_screen.dart`) de acordo com a identidade visual (mockups):
   - Campos de input/sliders para:
     - Valor do Imóvel (ex: slider de 100k a 5M)
     - Valor de Entrada
     - Renda Familiar Mensal
     - Tipo de Imóvel e Estado Civil (Dropdowns)
     - Prazo do Financiamento (em meses)
     - Data de Nascimento ou Idade do comprador
2. Configurar validações de formulário na interface:
   - Entrada mínima obrigatória (ex: pelo menos 20% do valor do imóvel).
   - Renda familiar maior que zero.
   - Idade válida do proponente.
3. Criar uma camada de serviço mockada (`lib/simulation/simulation_repository.dart`) que simule o cálculo básico do financiamento para retornar dados para a próxima tela de resultados (SAC/Price, taxas de juros médias).
4. Configurar a navegação para levar o usuário à tela de formulário após login com sucesso.
5. Criar testes de Widget em `test/screens/simulator_form_screen_test.dart` cobrindo:
   - Presença de todos os inputs e botões de ação.
   - Comportamento das mensagens de erro na validação dos campos (ex: entrada menor que 20% deve exibir erro visual).
   - Clique em "Simular/Próximo" disparando o fluxo correto se o formulário for válido.

### QA
- Validar visualmente os campos, sliders e alinhamento visual com base no mockup do Design System.
- Testar cenários extremos de input (ex: valores nulos, letras em campos numéricos, prazos negativos).
- Validar a cobertura de Widget Tests do formulário.
- Anexar capturas de tela das mensagens de erro e do formulário preenchido no relatório final.

## Critérios de Aceite (Acceptance Criteria)
- Tela de formulário estilizada conforme o Design System (cards, cores `#2EC4B6` nos sliders, tipografia Poppins).
- Validação ativa impedindo simulação caso a entrada seja menor que 20% do valor do imóvel.
- Botão "Próximo/Simular" redireciona apenas com dados válidos.
- Testes automatizados cobrindo os cenários de erro e sucesso no formulário.

## Definition of Done (DoD)
- Código fonte e testes do formulário implementados.
- Testes locais passando via CLI.
- QA aprovou a fidelidade ao design e validações.
- Alterações enviadas à branch `main`.
