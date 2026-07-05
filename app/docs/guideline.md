\# Guia de Identidade Visual — Meu Correspondente



\*\*Versão:\*\* 1.0

\*\*Produto:\*\* Meu Correspondente

\*\*Plataforma:\*\* Flutter (Android e iOS)



\---



\# Conceito da Marca



O Meu Correspondente deve transmitir:



\* Confiança

\* Segurança

\* Transparência

\* Agilidade

\* Simplicidade

\* Tecnologia



O usuário está realizando uma das decisões financeiras mais importantes da vida (financiamento imobiliário). Toda a interface deve reduzir ansiedade e transmitir credibilidade.



\*\*Palavras-chave\*\*



\* Clean

\* Premium

\* Bancário

\* Minimalista

\* Moderno

\* Humanizado



\---



\# Referências Visuais



Inspirar-se em interfaces como:



\* Nubank

\* Inter

\* XP Investimentos

\* BTG Pactual

\* QuintoAndar

\* Loft

\* Zillow

\* Revolut



Evitar aparência de ERP ou sistema legado.



\---



\# Estilo Visual



Utilizar bastante espaço em branco.



Layouts devem ser arejados.



Priorizar poucos elementos por tela.



Utilizar cartões (Cards) para agrupar informações.



Bordas suaves.



Poucas sombras.



Gradientes discretos.



Ícones simples.



Sem excesso de cores.



\---



\# Paleta de Cores



\## Primária



Azul Escuro



```

\#0D1B2A

```



Uso:



\* Barra superior

\* Splash

\* Login

\* Botões principais escuros



\---



Azul Médio



```

\#1B4965

```



Uso:



\* Ícones

\* Links

\* Destaques

\* Gráficos



\---



Turquesa



```

\#2EC4B6

```



Uso:



\* CTA

\* Botões principais

\* Sliders

\* Estados ativos



\---



Cinza Claro



```

\#E0E7EF

```



Uso:



\* Bordas

\* Cards

\* Separadores



\---



Background



```

\#F7F9FC

```



Uso:



\* Fundo padrão



\---



\## Cores de Feedback



Sucesso



```

\#22C55E

```



Alerta



```

\#F59E0B

```



Erro



```

\#EF4444

```



Informação



```

\#3B82F6

```



\---



\# Gradientes



Primário



```

\#1B4965

↓



\#2EC4B6

```



Nunca utilizar gradientes muito saturados.



\---



\# Tipografia



Fonte principal:



\*\*Poppins\*\*



Pesos:



\* Medium 500

\* SemiBold 600

\* Bold 700



Não utilizar fontes serifadas.



\---



\# Hierarquia



Título



32px



Bold



\---



Subtítulo



24px



SemiBold



\---



Título de seção



20px



SemiBold



\---



Texto



16px



Regular



\---



Legenda



14px



Regular



\---



Texto auxiliar



12px



Medium



\---



\# Ícones



Estilo:



\* Outline

\* Rounded

\* Espessura 2px



Preferência:



Material Symbols Rounded



Ícones devem ser minimalistas.



\---



\# Border Radius



Cards



```

20px

```



Botões



```

16px

```



Campos



```

14px

```



Bottom Sheets



```

28px

```



\---



\# Sombras



Muito discretas.



Exemplo



```

Blur: 20



Opacity: 8%

```



Nunca usar sombras pesadas.



\---



\# Botões



\## Primário



Fundo



Turquesa



Texto branco



Altura



56px



Radius



16px



\---



\## Secundário



Fundo branco



Borda turquesa



Texto turquesa



\---



\## Terciário



Sem fundo



Texto azul



\---



\# Campos de Entrada



Background branco



Radius 14px



Borda cinza clara



Altura



56px



Placeholder em cinza.



Ícone opcional à esquerda.



\---



\# Cards



Todos os blocos devem utilizar Cards.



Características:



\* Fundo branco

\* Radius 20px

\* Padding 20\~24px

\* Sombra leve



Nunca utilizar bordas pesadas.



\---



\# Espaçamento



Sistema de espaçamento baseado em múltiplos de 8.



```

4

8

16

24

32

40

48

64

```



Nunca utilizar valores aleatórios.



\---



\# Componentes



O Design System deverá possuir:



\* PrimaryButton

\* SecondaryButton

\* TextButton

\* AppTextField

\* SearchField

\* Card

\* LoanCard

\* PropertyCard

\* BankCard

\* SimulationCard

\* StepIndicator

\* BottomNavigation

\* AppBar

\* LoadingIndicator

\* EmptyState

\* ErrorState

\* InfoBanner

\* Toast

\* Modal

\* BottomSheet



\---



\# Navegação



Bottom Navigation fixa com quatro itens:



\* Início

\* Simulações

\* Parceiros

\* Perfil



Ícone ativo em Turquesa.



Ícones inativos em Cinza.



\---



\# Dashboard



A Home deve conter:



\* Saudação

\* Card principal "Nova Simulação"

\* Resumo

\* Últimas simulações

\* Status

\* Atalhos



Tudo organizado em Cards.



\---



\# Fluxo de Simulação



Fluxo em etapas:



1\. Dados do imóvel

2\. Dados do comprador

3\. Resultado

4\. Comparação entre bancos

5\. Resumo

6\. Compartilhar



Sempre utilizar indicador de progresso.



\---



\# Comparação de Bancos



Cada banco deve ser um Card.



Exibir:



\* Logo

\* Taxa

\* Parcela

\* CET

\* Entrada

\* Destaques



Botão:



"Ver detalhes"



\---



\# Gráficos



Utilizar:



\* Linha

\* Pizza

\* Barras



Estilo clean.



Sem grades pesadas.



Poucas cores.



\---



\# Animações



As animações devem ser rápidas.



Entre:



200 ms



e



300 ms



Utilizar:



\* Fade

\* Scale

\* Slide



Evitar animações exageradas.



\---



\# Ilustrações



Fotografias devem mostrar:



\* Casas modernas

\* Apartamentos

\* Famílias

\* Corretores

\* Pessoas felizes



Sempre utilizar imagens claras.



\---



\# Acessibilidade



Contraste mínimo AA.



Área mínima de toque:



48x48.



Suporte ao aumento de fonte.



Não depender apenas da cor para indicar estados.



\---



\# Responsividade



Desenvolver utilizando LayoutBuilder e MediaQuery.



Suporte para:



\* Android

\* iPhone

\* Tablets



\---



\# Arquitetura do Design System (Flutter)



```

lib/



design\_system/



&#x20;   colors.dart



&#x20;   typography.dart



&#x20;   spacing.dart



&#x20;   radius.dart



&#x20;   shadows.dart



&#x20;   icons.dart



&#x20;   theme.dart



components/



&#x20;   buttons/



&#x20;   cards/



&#x20;   inputs/



&#x20;   dialogs/



&#x20;   navigation/



&#x20;   charts/



screens/



```



\---



\# Experiência Desejada



Ao abrir o aplicativo, o usuário deve sentir que está utilizando um aplicativo financeiro moderno, comparável aos melhores bancos digitais do mercado. A experiência deve transmitir confiança, simplicidade e eficiência, reduzindo o esforço necessário para simular um financiamento imobiliário. Cada tela deve ser objetiva, com foco em concluir a jornada rapidamente, mantendo um visual elegante e consistente em toda a aplicação.



