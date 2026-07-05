# Relatório de Garantia de Qualidade (QA Report) - Issue #7

**Projeto:** Meu Correspondente  
**Tarefa:** [App] Formulário do Simulador com Testes de Validação (Issue #7)  
**Status:** APROVADO  
**Data:** 2026-07-05  

---

## 1. Verificação de Arquivos e Implementações

Todos os arquivos criados e modificados pelo desenvolvedor front-end foram inspecionados individualmente e validados com relação aos requisitos do plano de execução:

### A. Formulário do Simulador ([simulator_form_screen.dart](file:///C:/repos/meu-correspondente/app/lib/screens/simulator_form_screen.dart))
- **Alinhamento ao Design System**: A tela utiliza cores da paleta oficial (como `#2EC4B6` para os sliders e botões, `#0D1B2A` como cor primária) e tipografia consistente.
- **Campos de Entrada (Inputs e Sliders)**:
  - **Valor do Imóvel**: Slider de R\$ 100.000 a R\$ 5.000.000 com campo de texto síncrono.
  - **Valor de Entrada**: Campo de texto com botões de atalho percentuais rápidos (20%, 30%, 40%, 50%) calculados dinamicamente com base no valor do imóvel.
  - **Renda Familiar Mensal**: Campo de texto numérico.
  - **Data de Nascimento**: Campo de texto formatado (DD/MM/AAAA) com seletor de calendário (DatePicker) integrado.
  - **Estado Civil**: Dropdown contendo as opções corretas.
  - **Tipo de Imóvel**: Dropdown contendo as opções corretas (Residencial, Comercial).
  - **Prazo do Financiamento**: Slider de 12 a 420 meses com campo de texto síncrono.
- **Regras de Validação de Interface**:
  - **Entrada Mínima**: Valida se o valor de entrada é de pelo menos 20% do valor do imóvel. Exibe erro amigável contendo o valor mínimo necessário em reais.
  - **Renda Familiar**: Garante que o valor informado seja estritamente maior que zero.
  - **Idade do Proponente**: Calcula a idade com base na data de nascimento e valida se o comprador tem entre 18 e 80 anos completos na data atual.
  - **Prazo do Financiamento**: Valida se está entre 12 e 420 meses.

### B. Tela de Resultado da Simulação ([simulation_result_screen.dart](file:///C:/repos/meu-correspondente/app/lib/screens/simulation_result_screen.dart))
- **Comparativo SAC vs PRICE**:
  - Exibe um resumo detalhado do financiamento (valor financiado, prazo, taxa de juros).
  - Apresenta um card dedicado para a tabela **SAC** (mostrando a primeira parcela, a última parcela decrescente, juros totais e custo total).
  - Apresenta um card dedicado para a tabela **PRICE** (mostrando o valor da parcela fixa, juros totais e custo total).
  - Destaca a economia real de juros obtida ao optar pelo sistema SAC através de um banner de destaque visual ("Economia no SAC").
- **Navegação**: O botão "Nova Simulação" (`result_back_button`) faz um pop na pilha de navegação, retornando o usuário ao formulário com os dados preenchidos anteriormente.

### C. Repositório de Simulação Mockado ([simulation_repository.dart](file:///C:/repos/meu-correspondente/app/lib/simulation/simulation_repository.dart))
- **Modelagem de Dados**: Define as classes `SimulationInput` e `SimulationResult` de forma robusta.
- **Regras de Cálculo**:
  - Simula um delay de rede de 600ms.
  - Calcula a taxa de juros mensal a partir da taxa anual (10,5% a.a.) utilizando a fórmula de juros compostos equivalentes.
  - Implementa as equações matemáticas para os amortecimentos SAC e parcelas PRICE corretamente, gerando totais de juros e custos acumulados coerentes.

### D. Fluxo de Navegação e Inicialização ([main.dart](file:///C:/repos/meu-correspondente/app/lib/main.dart))
- **Redirecionamento Pós-Login**: O `AuthWrapper` agora redireciona usuários autenticados diretamente para a tela `SimulatorFormScreen`, substituindo a antiga tela de styleguide e completando o fluxo principal do aplicativo.

---

## 2. Execução dos Testes Automatizados

A suíte de testes do frontend foi executada localmente utilizando o comando:
```bash
C:\src\flutter\bin\flutter.bat test
```

### Resultados obtidos:
Todos os testes foram executados com sucesso e cobrem todos os cenários de sucesso, validações e erros no formulário do simulador:

- **Testes de Widgets e Integração (`simulator_form_screen_test.dart`)**:
  - `Renders all inputs, sliders, and submit button` - **PASSOU**
  - `Shows error if entry value is less than 20% of property value` - **PASSOU**
  - `Shows error if monthly income is zero or negative` - **PASSOU**
  - `Shows error if birthdate represents age less than 18 or greater than 80` - **PASSOU**
  - `Shows error if birthdate has invalid format` - **PASSOU**
  - `Successful form submission calculates simulation and redirects to SimulationResultScreen` - **PASSOU**
  - `Quick percentage buttons update the entry value field` - **PASSOU**

**Resultado Geral**: **Todos os testes da tela do simulador e da suíte do frontend passaram com sucesso!**

---

## 3. Avaliação dos Critérios de Aceite (Acceptance Criteria)

- [x] **Identidade Visual**: A tela segue as diretrizes visuais do Design System, incluindo botões customizados, sliders na cor `#2EC4B6`, tipografia Poppins e cards limpos com bordas arredondadas.
- [x] **Validação de Entrada Mínima**: O formulário impede a submissão e exibe o erro visual se a entrada for inferior a 20% do valor do imóvel.
- [x] **Navegação do Formulário**: O clique em "Simular Financiamento" dispara a navegação para `SimulationResultScreen` com os dados corretos apenas se todas as validações de input passarem.
- [x] **Testes Automatizados**: A suíte de testes de widget cobre os cenários críticos de erro de validação (entrada < 20%, renda <= 0, idade fora de 18-80 anos, formato de data inválido) e de sucesso.

---

## 4. Conclusão e Parecer de QA

> [!NOTE]
> As validações solicitadas na Issue #7 foram completamente atendidas. Os inputs e sliders estão funcionando de forma integrada e síncrona. A navegação de ida e volta entre o formulário e a tela de resultado está perfeitamente funcional. Os testes unitários e de widget fornecem excelente cobertura para garantir que regressões não quebrem as regras de validação estabelecidas.

O status da tarefa está definido como **APROVADO POR QA** (Definition of Done atingido).
