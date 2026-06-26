# Structured Logger / CLEF Viewer

Biblioteca Dart de logging estruturado com sinks CLEF (Seq-compatible) e webapp CLEF Viewer para ingestão, consulta e visualização de eventos de log.

## Language

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
Filtro no formato `chave=valor` aplicado via `json_extract` sobre `properties`.
_Avoid_: property query, k=v filter

**Empty Sentinel** (`__empty__`):
Valor interno do filtro para representar device ou property ausente/null; exibido ao usuário como `(empty)`.
_Avoid_: empty value, null filter

**Active Filter Chip**:
Indicador removível na FilterBar para um critério de filtro ativo (`levels`, `device_id`, `property`, `search`); `from`/`to` não viram chip.
_Avoid_: filter badge, filter tag

## Relationships

- Um **Log Event** tem opcionalmente um **Message Template**, um **Rendered Message**, e zero ou mais **Properties**
- O **Display Message** deriva do **Rendered Message** ou do **Message Template** + **Properties**
- Um **Log Event** tem no máximo um **Device Identifier**
- Um **Property Filter** referencia uma **Property** por chave e valor exato

## Example dialogue

> **Dev:** "O card mostra a mensagem renderizada — é o `@m`?"
> **Domain expert:** "Não necessariamente. **Rendered Message** é só o que veio no CLEF. O **Display Message** é o que o usuário vê: se `@m` existir, usamos; se não, montamos substituindo `{placeholders}` do **Message Template** pelas **Properties** — que é o caso normal do SinkSeq."

## Flagged ambiguities

- "mensagem renderizada" no requisito original misturava **Rendered Message** (`@m`) e **Display Message** — resolvido: Display Message é o termo canônico para o card.