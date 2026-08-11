# Decision 0001: Deck-list input contract

## Status

Accepted

## Context

The identity-preserving Commander deck review needs a predictable text input so
that it can distinguish card entries from malformed or ambiguous data without
silently changing the player's deck. The input must preserve exact card names,
including punctuation, accented characters, and double-faced card names.

Archidekt text exports provide a familiar format for the initial target user and
include useful printing and category metadata. Requiring every exported field,
however, would reject otherwise understandable entries when only a card name is
needed to identify a card. Parsing the submitted text and deciding whether the
resulting deck is Commander-legal are separate responsibilities.

## Decision

The review accepts an Archidekt-style plain-text deck list containing one card
entry per nonblank line. A card name is the only required value. A quantity is
optional and defaults to exactly `1` when omitted.

The supported full line shape is:

```text
<quantity>x <card name> (<set code>) <collector number> [<category>]
```

The category is independently optional. Set code and collector number are optional
as a pair: either both are present or neither is. When metadata is present, it must
use the positions and delimiters shown below. The parser preserves the submitted
card name and metadata; it does not infer a printing or a quantity greater than
one.

An explicitly supplied quantity must be a positive whole number. The input parser
may accept quantities greater than one. A later legality check determines whether
that quantity is allowed for the identified card in Commander.

Blank lines are ignored. The input is interpreted as UTF-8 so names such as
`Dáin, Lord of the Iron Hills` and `Thrór's Map` remain intact. The separator
` // ` is part of a double-faced card's name and does not split the entry.

## Rationale

- Archidekt-style input gives the first version one predictable, user-recognizable
  format instead of requiring a general-purpose deck-list parser.
- Requiring only the card name keeps valid input usable when printing or category
  metadata is absent.
- Defaulting an omitted quantity to one is deterministic and does not invent
  additional cards.
- Separating parsing from legality keeps syntax rules independent from Commander
  rules, including basic lands and cards whose rules allow multiple copies.
- Preserving metadata leaves room to identify a requested printing without making
  that metadata necessary for a deck review.

## Alternatives considered

### Require every Archidekt export field

Rejected because set, collector number, and category are not necessary to express
which card belongs in the deck. This would reject understandable input without
improving the initial review.

### Require a quantity on every line

Rejected because an omitted quantity has one safe interpretation: one copy.

### Infer quantities from card identity

Rejected because the parser cannot safely guess how many copies the player meant.
Card identity affects legality, not the submitted quantity.

### Accept multiple deck-site and free-form formats

Deferred because format detection and ambiguity handling expand the initial scope.
The first version supports only the contract defined here.

## Request contract

The deck-list value is UTF-8 plain text. Each nonblank line represents one card.
The following forms are accepted:

```text
<card name>
<quantity>x <card name>
<card name> [<category>]
<quantity>x <card name> [<category>]
<card name> (<set code>) <collector number>
<quantity>x <card name> (<set code>) <collector number>
<card name> (<set code>) <collector number> [<category>]
<quantity>x <card name> (<set code>) <collector number> [<category>]
```

For each accepted line, parsing produces:

- `name`: the submitted card name;
- `quantity`: the submitted positive whole number, or `1` when omitted;
- `set_code`: the submitted set code, or no value;
- `collector_number`: the submitted collector number, or no value;
- `category`: the submitted Archidekt category, or no value.

Card lookup and Commander-legality validation occur after parsing and are outside
this decision's parsing contract.

## Commander designation contract

Every complete-deck or incomplete-brew review request explicitly designates one or
more parsed entries as its commander configuration. Archidekt category metadata,
including `[Commander{top}]`, may prefill that selection in the user interface but
does not become authoritative until represented in the normalized request.

Each designated commander must occur in the submitted deck. One designated card is
the common case; multiple designations continue to legality evaluation, which
determines whether their specific combination is permitted. All valid designated
commanders are inherently protected and excluded from cut candidates.

If no commander is designated, the request asks the player to select one before
review. If explicit designations conflict with Archidekt category metadata, the
request asks the player to clarify rather than silently preferring either source.

## Failure contract

The whole request is not silently corrected when a nonblank line cannot be parsed.
The response identifies each failing line by line number, includes the submitted
line, and gives a reason the player can act on. No deck review begins until all
input lines satisfy the parsing contract.

A line fails parsing when:

- it has no card name;
- it supplies a quantity that is zero, negative, fractional, or not a whole number;
- it includes only part of the printing metadata, such as a set code without a
  collector number or a collector number without a set code;
- delimiters are unbalanced or metadata appears outside the supported order;
- text outside the supported Archidekt-style entry makes the card name ambiguous.

A missing or conflicting commander designation is a review-request validation
failure rather than a deck-list parsing failure.

A syntactically valid but unknown or ambiguous card name passes parsing and then
fails card lookup. That later failure must identify the line and ask the player to
correct or clarify the card rather than selecting a card silently.

## Examples

Accepted:

```text
Ark of Hunger
1x Ark of Hunger
Sol Ring [Artifact]
Sol Ring (cmm) 396
4x Mountain (trk) 323 [Land]
1x Thorin, King of Durin's Folk (hoc) 3 [Commander{top}]
1x Smaug, the Great Calamity // Spew Flame (hob) 109 [Creature]
1x Dáin, Lord of the Iron Hills (hob) 8 [Creature]
```

Rejected during parsing:

```text
0x Mountain
-1x Mountain
1.5x Mountain
1x (trk) 323 [Land]
Mountain (trk)
Mountain [Land] (trk) 323
```

The following is syntactically valid but requires a later card-lookup result:

```text
1x A Card Name That May Not Exist
```

Given a list containing `[Commander{top}]`, the interface may preselect that entry
as commander. Given a conflicting explicit selection, it asks the player to
clarify before review.
