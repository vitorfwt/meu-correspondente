# Plano de Execução - Issue #4: [Backend] Endpoints do Simulador com Testes de Negócio

## Objetivo
Implementar o endpoint `POST /api/simulate` na API Node.js. Este endpoint receberá os dados do proponente (valor do imóvel, entrada, renda, idade, prazo), buscará as taxas de juros vigentes das instituições no banco de dados, calculará as simulações nas modalidades SAC e Price, aplicará as restrições de crédito (comprometimento de renda de 30% e limite de idade + prazo <= 80 anos) e retornará os resultados estruturados.

## Dependências
- Conclusão da Issue #2 (Banco de dados) e Issue #3 (API Auth).

## Divisão de Tarefas

### DEV-BACK
1. Criar o endpoint `POST /api/simulate` exposto no arquivo `app.ts` (ou em rotas específicas).
2. Implementar a lógica matemática de financiamento para gerar as simulações:
   - **Tabela SAC**: Amortização constante, juros decrescentes sobre o saldo devedor, gerando parcelas decrescentes.
   - **Tabela PRICE**: Parcelas fixas calculadas pela fórmula de prestações da série uniforme.
   - Buscar as taxas de juros na tabela `interest_rates` filtrando pelas instituições ativas.
3. Aplicar as regras de restrição do MVP:
   - **Comprometimento de Renda**: Se a primeira parcela (ou prestação constante) exceder 30% da renda bruta familiar informada, adicionar alerta de restrição no retorno do banco.
   - **Limite de Idade**: Se a idade do comprador somada ao prazo de financiamento em anos for maior que 80 anos, adicionar alerta correspondente no retorno do banco.
4. Salvar opcionalmente a simulação no histórico de simulações (`simulations` no banco de dados) vinculada ao ID do usuário autenticado (se fornecido).
5. Escrever testes unitários para a classe/utilitário de cálculo matemático (SAC/Price).
6. Escrever testes de integração para o endpoint `POST /api/simulate` cobrindo cenários com e sem restrições.

### DEV-FRONT
- *Nenhuma tarefa nesta Issue.* (Standby).

### QA
- Validar se os cálculos de financiamento da API batem matematicamente.
- Testar cenários onde os limites de 30% de renda e 80 anos de idade são excedidos e garantir que os alertas de erro e códigos HTTP adequados são retornados.
- Executar os testes unitários e de integração de simulação no Vitest (`npm run test`) e garantir aprovação.

## Critérios de Aceite (Acceptance Criteria)
- Endpoint `/api/simulate` operacional.
- Retorno detalhado contendo dados de valor financiado, taxa de juros do banco, valor da primeira/última parcela (SAC) e parcela fixa (Price), custo total e indicativos de restrição (renda e idade).
- Testes unitários de cálculo e testes de integração de negócio implementados e passando.

## Definition of Done (DoD)
- Endpoint, cálculos e testes implementados.
- Testes passando localmente.
- QA aprovou e registrou o relatório da simulação.
- Alterações enviadas à branch `main` no GitHub.
