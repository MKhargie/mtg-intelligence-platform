# Decision 0002: Card-data and legality source

## Status

Accepted

## Context

The deck review must resolve submitted names to real Magic cards and identify
Commander legality problems that materially affect its advice. Card identity,
color identity, commander eligibility, banned status, and copy-count exceptions
are deterministic facts. Allowing a language model to supply or verify those
facts would make legality results difficult to reproduce and could produce
confident but incorrect guidance.

The first product slice should use current card data without taking on the
storage, indexing, and refresh workflow required by a local card database.
External access nevertheless introduces latency, rate limits, and availability
failures that the application must expose deliberately.

## Decision

Scryfall is the external source for card identity and the card data needed to
evaluate Commander legality. The application accesses Scryfall through an
application-owned card-data interface rather than allowing review or LLM code to
call Scryfall directly.

Card resolution is batched. The application must not make one independent live
request per card when the provider supports resolving multiple identifiers in a
request. Requests must follow Scryfall's published API guidance, including
identifying the client and respecting rate limits.

The card-data interface returns normalized application data. Downstream review
logic depends on that normalized contract, not on Scryfall response objects.
Scryfall identifiers may be retained for traceability, but Scryfall-specific
transport details do not cross the interface.

The language model may reason from resolved card data supplied by the
application. It must not invent, resolve, or override card identity, color
identity, legality, or commander eligibility.

## Rationale

- Scryfall provides structured card and legality data suitable for deterministic
  validation.
- A live lookup avoids building a bulk-data refresh and indexing system in the
  first slice.
- Batching avoids unnecessary requests and reduces exposure to latency and rate
  limits.
- An application-owned interface isolates the rest of the system from provider
  response shapes and permits a future provider or local cache without changing
  review behavior.
- Keeping factual resolution outside the LLM boundary makes failures explicit and
  results testable.

## Alternatives considered

### Store and query Scryfall bulk data locally

Deferred. Bulk data would reduce runtime dependence on Scryfall and is appropriate
for large or repetitive lookup workloads. It also requires download scheduling,
freshness policy, storage, indexing, and atomic refresh behavior that the first
slice does not yet need.

### Perform one live request per card

Rejected because a Commander deck can contain approximately 100 card entries.
Independent requests would add avoidable latency and provider load and make
partial transport failures harder to reason about.

### Let the language model provide card and legality facts

Rejected because language-model output is probabilistic and may be incomplete or
out of date. It is not an authoritative legality source.

### Couple review logic directly to Scryfall responses

Rejected because provider fields, errors, and transport behavior would spread
through the application and make replacement and isolated testing more difficult.

## Request contract

The application-owned card-data interface receives a collection of parsed card
references. Each reference contains:

- the source deck-list line number;
- the submitted card name;
- the parsed quantity;
- optional set code and collector number.

The caller supplies the complete collection for one resolution operation. The
interface is responsible for grouping that collection into the minimum practical
number of provider requests while obeying provider limits. The caller does not
construct Scryfall URLs or Scryfall request objects.

## Response contract

For every successfully resolved reference, the interface returns normalized data
containing at least:

- source line number and submitted values for traceability;
- a stable gameplay identity shared by all printings of the same Oracle card;
- a separate printing identity when a specific printing resolves;
- canonical card name;
- card layout and card faces when applicable;
- type line;
- Oracle rules text;
- mana cost and mana value;
- colors and color identity;
- keywords and mana-production facts;
- Commander legality status;
- information needed to determine commander eligibility;
- information needed to identify basic lands or card-specific copy-count
  exceptions.

The response preserves the association between each submitted entry and its
resolution result. Response order must not be the only means of establishing that
association.

Rules, singleton checks, incomplete-brew distinct-identity counts, protected-card
normalization, and rejected-recommendation comparisons use gameplay identity.
Printing identity preserves the player's requested set/collector selection but
does not make two printings of the same Oracle card distinct for those behaviors.

The exact normalized application types will be defined during implementation,
but they must satisfy this behavioral contract without exposing raw provider
objects to review logic.

## Legality-evaluation contract

After every entry and commander designation resolves, an application-owned
legality evaluator receives the normalized deck entries and quantities, the
explicit commander configuration, the complete-deck or incomplete-brew
designation, and the resolved facts required by the checks below.

The evaluator returns structured findings. Each finding contains a stable finding
code, affected submitted lines or card identities when applicable, a player-facing
explanation, and a severity stating whether it blocks review or is informational.

The evaluator checks at least:

- eligibility of every designated commander;
- whether a multi-card commander configuration is permitted together;
- the commanders' combined color identity;
- cards outside that color identity;
- banned cards;
- duplicate nonbasic cards;
- basic-land and card-specific copy-count exceptions;
- deck size above the permitted Commander total for every submission;
- deck size below the permitted Commander total for a submission designated as
  complete.

An incomplete brew is not illegal solely because it contains fewer than the
permitted Commander total. An incomplete brew above that total still receives a
deck-size finding. Other material legality findings still apply. Findings
correlate to submitted entries by stable identity and source line rather than
response order alone.

If rules or card data required by any check is absent or internally inconsistent,
evaluation fails explicitly. It does not report the deck as legal from partial
data and no LLM review begins.

## Failure contract

Card-data failures are reported separately from parsing failures. The system must
not begin a deck review using invented facts or silently omit unresolved entries.

The interface distinguishes at least these outcomes:

- **Unknown card:** no provider card matches the submitted identity. Report the
  source line and submitted values so the player can correct them.
- **Ambiguous card:** the submitted identity cannot select one card safely. Report
  the source line and request clarification; do not choose silently.
- **Invalid printing metadata:** the name may exist, but the supplied set and
  collector number do not resolve together. Report the conflicting values.
- **Rate limited:** report temporary provider unavailability and preserve enough
  information for a controlled retry. Do not retry without a defined limit.
- **Timeout or network failure:** report temporary card-data unavailability. Do
  not fall back to the language model.
- **Malformed or incomplete provider response:** treat the resolution operation as
  failed and record an internal diagnostic without presenting raw provider
  details as player-facing guidance.

If any submitted entry cannot be resolved, the resolution operation returns all
known per-entry problems but does not produce a partially validated deck for
review. This lets the player correct multiple entries in one pass without allowing
an incomplete deck model to reach legality or recommendation logic.

## Verification examples

- Given multiple valid card references, the interface resolves them in batches
  and returns one correlated normalized result per reference.
- Given an accented or double-faced card name, the normalized result preserves and
  resolves the intended identity.
- Given two entries for different printings of the same Oracle card, they have the
  same gameplay identity and different printing identities; singleton, protected-
  card, minimum-brew, and rejected-recommendation logic treat them as one card.
- Given a successfully resolved card, the normalized result contains the gameplay
  facts needed for theme, game-plan, mana, draw, interaction, and protection
  analysis without requiring the LLM to invent card text.
- Given an unknown name among otherwise valid entries, the response identifies its
  source line and no review begins.
- Given mismatched set and collector metadata, the response reports an invalid
  printing instead of silently resolving by name alone.
- Given a provider timeout, rate limit, or unavailable service, no card facts are
  requested from or supplied by the language model.
- Given a valid provider response, downstream legality and review code can operate
  on normalized application data without importing Scryfall response types.
- Given an ineligible commander or invalid multi-commander combination, the
  evaluator returns a blocking finding correlated to the designation.
- Given an off-color, banned, or impermissibly duplicated card, the evaluator
  returns a stable finding correlated to each affected entry.
- Given a complete deck below or above the permitted total, size produces a
  finding; given an explicitly incomplete brew below that total, size alone does
  not; given an incomplete brew above that total, size produces a finding.
- Given missing rules data required by any check, evaluation fails without
  declaring the deck legal or starting an LLM review.

## Operational reference

Scryfall's published guidance asks API clients to remain below 10 requests per
second, use appropriate request headers, avoid redundant calls, and prefer bulk
data for large lookup workloads:
https://scryfall.com/docs/faqs/i-m-having-trouble-accessing-the-scryfall-api-or-i-m-blocked-17
