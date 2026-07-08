# Diretriz de Delegação de Tarefas do AI-DOS

Esta regra define o protocolo obrigatório de delegação de tarefas de desenvolvimento do agente orquestrador para subagentes especialistas.

## Regra de Delegação Obrigatória

> [!IMPORTANT]
> O agente orquestrador **NUNCA** deve implementar, corrigir ou refatorar código diretamente no repositório. Toda e qualquer ação de modificação de código fonte, escrita de testes automatizados ou refatoração deve ser obrigatoriamente delegada a subagentes especialistas (`dev-back` ou `dev-front`) usando a ferramenta `invoke_subagent`.

### Protocolo de Execução

1. **Classificação da Demanda**:
   - Analisar o tipo de tarefa no início (New Feature, Bugfix, Refactor, Spike, Hotfix) para associá-la ao workflow apropriado.
2. **Identificação do Especialista**:
   - **Backend / APIs / DB / Testes Backend**: Sempre delegar ao subagente `dev-back`.
   - **Frontend / Telas / Layouts / Interação / Browser Tests**: Sempre delegar ao subagente `dev-front`.
   - **Homologação / Testes Gerais / Regressão**: Sempre delegar ao subagente `qa`.
   - **Code Review / Validação Estática**: Sempre delegar ao subagente `reviewer`.
3. **Instanciação e Acompanhamento**:
   - Usar `invoke_subagent` com a definição correta do prompt de sistema sugerida para o papel do agente (conforme definido em `.ai/agents/<agente>.md`).
   - Monitorar a conclusão do subagente sem pollar em loops, aguardando a notificação de finalização do sistema de mensageria.

### Exceções
- Apenas tarefas de orquestração geral, leitura inicial de arquivos para planejamento, ou merges e releases rápidos podem ser executados diretamente pelo orquestrador.
- Spikes de investigação rápida que não alteram a base de código de produção podem ser realizados diretamente pelo orquestrador, embora a prototipação ainda possa ser delegada.

Qualquer violação deste protocolo de delegação constitui uma falha operacional nas políticas de desenvolvimento atômico do AI-DOS.
