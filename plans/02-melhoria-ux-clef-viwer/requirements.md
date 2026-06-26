# Requirements Document: Melhorias de UI — CLEF Viewer

## Overview

Melhorias na interface Flutter Web em `apps/clef_viewer/ui` para facilitar leitura, filtragem e cópia de logs estruturados. Hoje os cards exibem o template bruto (`Hello {name}`) quando não há `@m`, o filtro de device é texto livre, não há cópia de eventos, e o filtro por propriedade exige digitar `chave=valor` manualmente.

**Estado atual relevante:**

- `LogEntry.displayMessage` retorna `renderedMessage ?? messageTemplate ?? exception ?? '(no message)'`
- `FilterBar` usa `TextField` simples para Device ID e Property (`k=v`)
- `LogRow` expande para mostrar properties como JSON monolítico

**Escopo:** apenas a UI (`apps/clef_viewer/ui`), com alterações mínimas no servidor se necessário.

**Decisões de grilling (resumo):** Display Message client-side (#1–3), cópia texto legível (#4), apply imediato (#5), group API para devices (#6–7), clique único em property chip (#8), chips parciais sem event_id (#9), placeholder ausente vermelho (#10), copiar hover/expanded (#11), property complexa não filtra (#12), parser template básico (#13).

---

## User Roles

| Role | Descrição |
|------|-----------|
| **Developer** | Inspeciona logs em tempo real, filtra por device/propriedade, copia eventos para compartilhar ou debugar |
| **Operator** | Usa os mesmos fluxos na área Viewer; filtros são compartilhados com Admin |

---

## Requirement 1: Display Message com destaque de propriedades

**User Story:** Como desenvolvedor, quero ver o Display Message do log com os valores das propriedades aplicados ao template, com destaque visual nos trechos que eram placeholders, para entender o evento sem expandir o card.

> **Decisão (grilling #1):** quando `@m` está ausente (caso padrão do `SinkSeq`), o Display Message é computado client-side substituindo `{placeholders}` do Message Template pelos valores das Properties, com destaque nos trechos substituídos. Ver `CONTEXT.md`.

**Acceptance Criteria:**

1. WHEN um log possui `messageTemplate` e propriedades correspondentes AND `renderedMessage` (`@m`) está ausente THEN a UI SHALL computar o Display Message substituindo cada placeholder `{Nome}` pelo valor de `properties['Nome']`, com destaque nos valores substituídos
2. WHEN um log possui `renderedMessage` (`@m`) THEN a UI SHALL exibir `renderedMessage` como Display Message em texto plano, sem destaque de propriedades — **decisão grilling #2**
3. WHEN um placeholder no template não possui propriedade correspondente THEN a UI SHALL exibir o placeholder literal (ex.: `{country}`) com destaque de erro: fundo vermelho suave e borda tracejada — **decisão grilling #10**
4. WHEN um valor substituído era um placeholder THEN a UI SHALL renderizá-lo com `colorScheme.primary` (ou `tertiary`) e `fontWeight: w600`, distinto do texto estático — **decisão grilling #3**
5. WHEN o card está colapsado THEN a UI SHALL exibir a mensagem renderizada em uma linha com ellipsis
6. WHEN o card está expandido THEN a UI SHALL exibir a mensagem renderizada completa, preservando quebras de linha se existirem
7. WHEN o log não possui template nem mensagem renderizada THEN a UI SHALL exibir `exception` ou `(no message)` conforme comportamento atual

**Regras de renderização:**

| Cenário | Comportamento |
|---------|---------------|
| Template `User {id} logged in`, `properties: {id: 42}` | Exibir `User ` + **`42`** + ` logged in` |
| Template com `@m` preenchido | Usar `@m` como Display Message em texto plano, sem destaque |
| Valor numérico/booleano/objeto | Converter para string legível (`42`, `true`, JSON compacto para objetos) |
| Propriedades com chaves aninhadas (`Source.Context`) | Suportar apenas placeholders flat `{Source.Context}` alinhado ao formato CLEF flat |

**Edge Cases:**

- WHEN template contém `{{literal}}` THEN a UI SHALL exibir como texto literal `{literal}` (escape básico por regex, não parser Serilog completo) — **decisão grilling #13**
- WHEN placeholder usa chave dotted (`{Source.Context}`) THEN a UI SHALL resolver contra `properties['Source.Context']` (flat key, alinhado ao `PropertyKeyValidator`)
- WHEN propriedade existe mas valor é `null` THEN a UI SHALL exibir o placeholder literal com o mesmo estilo de erro (grilling #10)
- WHEN mensagem é muito longa (> 500 caracteres) THEN a UI SHALL truncar no modo colapsado sem perder legibilidade do início

---

## Requirement 2: Autocomplete no filtro de Device ID

**User Story:** Como desenvolvedor, quero selecionar device IDs existentes via autocomplete, para filtrar sem memorizar ou digitar IDs completos.

**Acceptance Criteria:**

1. WHEN o usuário foca ou digita no campo Device ID THEN a UI SHALL exibir sugestões de device IDs distintos, obtidas via group API com filtro vazio (todos os devices do banco, até 100) — **decisão grilling #7**
2. WHEN o usuário digita no campo THEN a UI SHALL filtrar sugestões de forma case-insensitive por substring
3. WHEN o usuário seleciona uma sugestão THEN a UI SHALL preencher o campo e aplicar o filtro imediatamente — **decisão grilling #5**, alinhado ao painel de grupos
4. WHEN existem logs com `device_id` vazio/null THEN a UI SHALL incluir opção `(empty)` nas sugestões, compatível com `FilterConstants.emptySentinel`
5. WHEN não há device IDs no dataset THEN a UI SHALL exibir campo de texto sem sugestões (comportamento degradado)
6. WHEN novos logs chegam via SSE com device_id ainda não listado THEN a UI SHALL acrescentar o device às sugestões locais (merge com cache da group API)

**Fonte de dados (decisão grilling #6):** reutilizar `GET /api/events/group?group_by=device_id` — sem novo endpoint no servidor.

**Edge Cases:**

- WHEN há mais de 200 device IDs distintos THEN a UI SHALL limitar sugestões exibidas (ex.: top 50 matches) e refinar por digitação
- WHEN a requisição de sugestões falha THEN a UI SHALL manter o campo como texto livre sem bloquear filtros

---

## Requirement 3: Copiar log

**User Story:** Como desenvolvedor, quero copiar um log individual para a área de transferência, para colar em issues, chats ou ferramentas externas.

**Acceptance Criteria:**

1. WHEN o usuário aciona "Copiar" em um card de log THEN a UI SHALL copiar o conteúdo do evento para o clipboard
2. WHEN a cópia é bem-sucedida THEN a UI SHALL exibir feedback visual (SnackBar ou tooltip) confirmando "Copiado"
3. WHEN a cópia falha (permissão negada, ambiente sem clipboard) THEN a UI SHALL exibir mensagem de erro clara
4. WHEN o log é copiado THEN o conteúdo SHALL incluir no mínimo: timestamp, level, mensagem renderizada (ou template), device ID (se houver), exception (se houver), e properties como JSON
5. WHEN o usuário aciona copiar THEN a ação SHALL NOT expandir/colapsar o card (evitar conflito com tap no card)
6. WHEN o card está colapsado THEN o botão copiar SHALL aparecer apenas no hover; WHEN expandido SHALL permanecer visível — **decisão grilling #11**

**Formato de cópia (decisão grilling #4):** texto legível multi-linha:

```
2024-01-01T12:00:01Z [info] User 42 logged in
device: my-app-dev
properties: {"UserId":42,"Screen":"Home"}
```

**Edge Cases:**

- WHEN o usuário clica copiar em log com exception longa THEN a UI SHALL copiar o conteúdo integral
- WHEN múltiplas cópias rápidas THEN a UI SHALL sobrescrever clipboard sem erro

---

## Requirement 4: Filtrar por propriedade escolhida no log

**User Story:** Como desenvolvedor, quero clicar em uma propriedade de um log e usá-la como filtro, para investigar eventos com o mesmo valor sem digitar `chave=valor`.

**Acceptance Criteria:**

1. WHEN o usuário clica em um property chip no card expandido THEN a UI SHALL aplicar imediatamente o filtro `property` como `chave=valor` — **decisão grilling #8** (clique único, sem menu de confirmação)
2. WHEN o filtro é aplicado por property chip THEN a UI SHALL refletir o valor no campo Property da FilterBar e recarregar eventos e grupos
3. WHEN o valor da propriedade é `null` ou ausente THEN a UI SHALL usar Empty Sentinel (`__empty__`, exibido como `(empty)`) no filtro
4. WHEN um filtro de propriedade já está ativo e o usuário escolhe outra propriedade THEN a UI SHALL substituir o filtro anterior (não acumular múltiplas propriedades)

**Interação (decisão grilling #8):**

- Properties expandidas como chips `chave: valor`; clique único aplica Property Filter imediatamente
- Copiar valor individual de property: fora de escopo (usar copiar log inteiro — Req 3)

**Edge Cases:**

- WHEN propriedade tem valor complexo (Map/List) THEN o chip SHALL ser exibido mas NOT clicável para filtro — **decisão grilling #12** (somente valores primitivos: string, number, bool)
- WHEN chave contém caracteres especiais (`.`, `-`) THEN a UI SHALL respeitar validação `PropertyKeyValidator` do servidor
- WHEN valor contém `=` THEN a UI SHALL tratar apenas o primeiro `=` como separador chave/valor (mesma regra do `LogFilter`)

---

## Requirement 5: Melhorias gerais de UX

**User Story:** Como desenvolvedor, quero uma interface mais clara e eficiente para inspecionar logs, para reduzir fricção no fluxo de debug diário.

**Acceptance Criteria:**

1. WHEN filtros estão ativos nos campos `levels`, `device_id`, `property` ou `search` THEN a UI SHALL exibir chip removível por filtro ativo — **decisão grilling #9** (`from`/`to` permanecem só nos campos da FilterBar)
2. WHEN o usuário remove um chip de filtro THEN a UI SHALL limpar aquele critério, aplicar imediatamente e recarregar eventos
3. WHEN a UI for refatorada THEN o campo `event_id` SHALL ser removido da FilterBar — **decisão grilling #9** (filtro não exposto na UI; API server-side permanece)
4. WHEN o card está colapsado THEN a UI SHALL exibir hierarquia visual clara: hora → badge de level → Display Message
5. WHEN o usuário passa o mouse sobre um card colapsado THEN a UI SHALL exibir ícone de copiar; WHEN o card está expandido o ícone de copiar SHALL permanecer visível — **decisão grilling #11**
6. WHEN não há eventos THEN a UI SHALL manter empty state atual com mensagem orientativa
7. WHEN a FilterBar tem erro de validação THEN a UI SHALL manter mensagem de erro visível próxima ao botão Apply

**Melhorias de layout sugeridas (não prescritivas):**

- Properties expandidas como chips em vez de bloco JSON monolítico
- Ícone de copiar sempre visível no hover do card
- Autocomplete e property picker integrados à FilterBar existente

---

## Non-Functional Requirements

| Categoria | Requisito |
|-----------|-----------|
| **Performance** | WHEN a lista tem até 100 eventos em memória THEN renderização de mensagens com destaque SHALL NOT causar jank perceptível (< 16ms por frame em scroll) |
| **Performance** | WHEN autocomplete é acionado THEN sugestões SHALL aparecer em < 300ms após digitação (com cache local) |
| **Acessibilidade** | WHEN ações de copiar/filtrar existem THEN SHALL ter `tooltip` ou `Semantics` label descritivo |
| **Compatibilidade** | WHEN em Flutter Web THEN copiar SHALL usar `Clipboard` API com fallback para browsers sem permissão |
| **Consistência** | Terminologia SHALL seguir padrões existentes: `device_id`, `property (k=v)`, `(empty)` sentinel |

---

## Out of Scope

- Edição ou exclusão individual de logs pela UI Viewer (permanece no Admin)
- Filtro por múltiplas propriedades simultâneas (AND de várias chaves)
- Highlight syntax em exceptions
- Temas customizáveis / dark mode dedicado (herda `ThemeData` atual)
- Export de log individual como arquivo (apenas clipboard neste escopo)
- Cópia em formato CLEF JSON (fase 2)
- Re-renderização server-side de templates (lógica fica no cliente)

---

## Open Questions

_Todas resolvidas na sessão de grilling._

| # | Tema | Decisão |
|---|------|---------|
| 1 | Formato de cópia | Texto legível multi-linha |
| 2 | Apply automático | Imediato (device autocomplete, property chip); Apply manual na FilterBar |
| 3 | Endpoint de devices | Group API `group_by=device_id` |
| 4 | Destaque com `@m` | Texto plano, sem destaque |
| 5 | Cor dos placeholders | `colorScheme.primary` + `fontWeight: w600` |
| 6 | Chips de filtro | `levels`, `device_id`, `property`, `search` — sem `event_id` |
| 7 | Escopo devices autocomplete | Todos do banco (query sem filtros ativos) |
| 8 | Property chip | Clique único aplica filtro |
| 9 | Placeholder ausente | Literal `{nome}` com fundo vermelho + borda tracejada |
| 10 | Botão copiar | Hover quando colapsado; sempre visível quando expandido |
| 11 | Property complexa | Chip visível, não clicável (só primitivos filtram) |
| 12 | Parser de template | Placeholders `{name}` + escape `{{literal}}`; sem formatos Serilog (`{n:fmt}`) |

---

## Validação (checklist)

| Critério | Status |
|----------|--------|
| Todos os pedidos do usuário cobertos | ✅ |
| Cenários normais + edge cases | ✅ |
| Requisitos testáveis (EARS) | ✅ |
| Sem termos vagos ("melhorar UX" decomposto em critérios observáveis) | ✅ |
| Compatível com API/filtros existentes | ✅ |
| Escopo delimitado | ✅ |

---

## Próximos passos

1. ~~Revisar Open Questions~~ — concluído na sessão de grilling
2. Escrever **design técnico** (`design.md` nesta pasta)
3. Implementar e cobrir com **testes widget** em `apps/clef_viewer/ui/test/`