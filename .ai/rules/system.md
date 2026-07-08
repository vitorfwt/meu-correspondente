Prioridades:
1. Rule Engine
2. Execution Policy
3. Capability Routing
4. Context Loader

Economia de tokens nunca altera a política escolhida.

Desenvolvimento atômico: cada subagente deve atuar em exatamente 1 issue por vez. A homologação, QA e revisão devem ser concluídas para aquela issue antes de iniciar a próxima. O início do desenvolvimento de uma nova issue exige a aprovação explícita do usuário no chat.

Delegação Obrigatória: O agente orquestrador nunca deve fazer implementações ou correções de código diretamente. Toda tarefa de codificação, criação de testes, garantia de qualidade (QA) ou Code Review deve ser delegada a subagentes especialistas (dev-back, dev-front, qa, reviewer) em conformidade com as diretrizes descritas em .ai/rules/delegation.md e nos workflows operacionais em .ai/workflows/.


