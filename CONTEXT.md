# Structured Logger Monorepo

Monorepo de logging estruturado CLEF: pacote core Dart, pacotes de integração, apps (CLEF Viewer e futuros), documentação e site.

## Language

### Deliverables

**Structured Logger**:
Pacote Dart core de logging estruturado com sinks plugáveis; sem dependência do Flutter SDK.
_Avoid_: plugin, pacote Flutter (para o core)

**Dio Seq Interceptor** (`structured_logger_dio_interceptor`):
Pacote que intercepta requisições Dio e emite Log Events (REQUEST, RESPONSE, ON_ERROR) via um **Structure Logger** já configurado com sinks pelo consumidor.
_Avoid_: dio_interceptor_seq (nome legado do repositório externo)

**Structure Logger**:
Logger central que distribui Log Events para os **Sinks** registrados via `addSink`.
_Avoid_: logger, StructureLogger (ok em código)

**CLEF Viewer**:
App em `apps/clef_viewer` — servidor Dart VM + UI Flutter Web para ingestão, consulta e visualização de Log Events.
_Avoid_: clef view (grafia informal)

### CLEF & log events

**Log Event**:
Um registro de log persistido ou em trânsito, com campos CLEF reservados e propriedades estruturadas.
_Avoid_: log line, entry (ok em código, mas no domínio preferir Log Event)

**Message Template** (`@mt`):
String com placeholders `{Nome}` que descreve a forma da mensagem; propriedades ficam separadas em `properties`.
_Avoid_: message, template message

**Rendered Message** (`@m`):
Mensagem já computada pelo emissor (Seq/Serilog); texto final sem placeholders.
_Avoid_: rendered text, @m field

**Display Message**:
O texto que o card do Viewer mostra ao usuário: usa Rendered Message (`@m`) em texto plano se existir; senão, substituição client-side dos placeholders do Message Template pelos valores em `properties`, com destaque visual nos trechos substituídos.
_Avoid_: mensagem renderizada (ambíguo — pode significar `@m` ou Display Message)

**Property**:
Par chave-valor estruturado anexado ao Log Event, fora dos campos CLEF reservados (`@t`, `@mt`, `@l`, etc.).
_Avoid_: field, metadata

**Device Identifier** (`DeviceIdentifier`):
Identificador do dispositivo/app que gerou o log; indexado como `device_id` para filtro e agrupamento.
_Avoid_: device, client id

### Filtering

**Property Filter**:
Filtro no formato `chave=valor` aplicado via `json_extract` sobre `properties`; na UI, aplicado apenas por clique em chip de log (sem campo de texto dedicado).
_Avoid_: property query, k=v filter, campo Property na FilterBar

**Search**:
Busca textual livre nos Log Events, respeitando o intervalo de tempo ativo; cobre Message Template, Rendered Message, exception, JSON de properties e Device Identifier.
_Avoid_: full-text search (ok em código), campo Property na FilterBar

**Empty Sentinel** (`__empty__`):
Valor interno do filtro para representar device ou property ausente/null; exibido ao usuário como `(empty)`.
_Avoid_: empty value, null filter

**Active Filter Chip**:
Indicador removível na FilterBar para um critério de filtro ativo (`levels`, `device_id`, `property`, `search`); `from`/`to` não viram chip.
_Avoid_: filter badge, filter tag

**Clear Filters**:
Ação na FilterBar que remove todos os critérios ativos — Search, Device Identifier, Property Filters e intervalo de tempo — restaurando o Viewer ao estado live sem filtros.
_Avoid_: reset search, limpar busca

## Relationships

- O monorepo contém um **Structured Logger** (core), zero ou mais pacotes de integração (ex.: **Dio Seq Interceptor**), e um ou mais apps (ex.: **CLEF Viewer**)
- **Dio Seq Interceptor** depende de **Structured Logger**; recebe uma instância de **Structure Logger** já configurada e emite **Log Events** pelos sinks registrados (ex.: SinkSeq)
- **CLEF Viewer** ingere **Log Events** enviados por apps que usam **Structured Logger** ou **Dio Seq Interceptor**
- Um **Log Event** tem opcionalmente um **Message Template**, um **Rendered Message**, e zero ou mais **Properties**
- O **Display Message** deriva do **Rendered Message** ou do **Message Template** + **Properties**
- Um **Log Event** tem no máximo um **Device Identifier**
- Um **Property Filter** referencia uma **Property** por chave e valor exato
- **Search** e **Property Filter** são mecanismos distintos: Search é texto livre; Property Filter é match exato via chip
- **Search** aplica com debounce e reload silencioso (sem spinner full-page); indicador discreto no campo durante a busca
- **Search** é local ao Viewer; export/delete filtrados na Admin usam levels, Device Identifier, Property Filters e intervalo de tempo — não o texto de Search
- O intervalo de tempo ativo no Viewer é propagado para operações filtradas na Admin (export/delete)

## Example dialogue

> **Dev:** "O card mostra a mensagem renderizada — é o `@m`?"
> **Domain expert:** "Não necessariamente. **Rendered Message** é só o que veio no CLEF. O **Display Message** é o que o usuário vê: se `@m` existir, usamos; se não, montamos substituindo `{placeholders}` do **Message Template** pelas **Properties** — que é o caso normal do SinkSeq."

## Flagged ambiguities

- "mensagem renderizada" no requisito original misturava **Rendered Message** (`@m`) e **Display Message** — resolvido: Display Message é o termo canônico para o card.
- Versão do **Structured Logger** na migração Dart puro: **1.0.0** — marco de estabilidade Dart-first; API pública inalterada.
- Campo "Property" na FilterBar vs **Property Filter** via chip — resolvido: remover campo de texto; Property Filter só por clique em chip.
- **Search** na FilterBar vs campo Property — resolvido: Search unificado (escopo A); Property Filter só por chip.
- Time window no Viewer vs Admin filtered — resolvido: intervalo de tempo propagado para export/delete filtrados na Admin.