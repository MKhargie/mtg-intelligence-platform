# Decision 0003: LLM boundary and failure behavior

## Status

Accepted

## Context

The deck-review experience needs qualitative reasoning about theme, game plan,
weaknesses, and possible improvements. An LLM can perform that reasoning, but it
is not an authoritative source for card identity or Commander legality and may
return incomplete, malformed, or invented information.

Players may also submit misspelled or ambiguous card names. A deterministic card
lookup cannot always infer the intended card safely, while an LLM may be useful
for proposing likely corrections. Because deck identity is important, no proposed
correction may silently change the player's submitted deck.

## Decision

Deterministic application code owns:

- deck-list parsing;
- authoritative card resolution through the card-data boundary;
- relevant Commander-legality evaluation;
- enforcement of protected-card and recommendation-count rules;
- validation of LLM request and response contracts;
- deciding whether a review is complete enough to show to the player.

The LLM owns qualitative reasoning from validated context:

- theme and intended-experience alignment;
- game-plan support;
- mana, draw, interaction, and protection analysis;
- likely gameplay weaknesses;
- prioritized, explained additions or swaps;
- refinement of advice using the player's latest feedback and constraints.

The LLM receives normalized application data, not raw Scryfall responses. It must
not override resolved card facts, determine authoritative legality, remove a
protected card, or silently alter the submitted deck.

### Human-approved card-name suggestions

When Scryfall reports an unknown or ambiguous submitted card name, the application
may ask the LLM for likely card-name suggestions. Each suggestion is labeled as a
guess and remains separate from the deck.

The player must select a suggestion or provide a correction. The selected name is
then submitted to Scryfall through the card-data boundary. It becomes part of the
deck only after Scryfall resolves it successfully. The review does not begin
before that verification succeeds.

This suggestion flow applies to unknown or ambiguous names. It does not replace
Scryfall during a timeout, rate limit, authentication problem, malformed provider
response, or unavailable service.

## Rationale

- Qualitative deck advice benefits from LLM reasoning, while card facts and
  contract enforcement require deterministic, reproducible behavior.
- Structured input limits the LLM to facts already resolved by the application.
- Structured, validated output prevents prompting from being the only enforcement
  mechanism for product rules.
- LLM suggestions can help a player recover from misspellings without silently
  changing the identity of the submitted deck.
- Human approval preserves player intent, and subsequent Scryfall verification
  preserves factual correctness.
- Limited retries permit recovery from transient generation defects without
  creating uncontrolled loops, duplicate costs, or hidden delays.

## Alternatives considered

### Allow the LLM to resolve a card authoritatively

Rejected because an LLM may invent a plausible card or confuse similar names. A
guess could corrupt legality checks and recommendations without a visible error.

### Accept the player's approved suggestion without Scryfall verification

Rejected because human approval establishes intent but does not establish that the
card identity and facts are valid. Scryfall verification remains required.

### Reject every unknown name without assistance

Rejected because it is safe and useful to offer clearly labeled candidate names
when the player retains control and the chosen candidate is verified afterward.

### Rely on prompt instructions without application validation

Rejected because an LLM can violate instructions or return malformed output.
Product invariants must be enforced outside the model.

### Retry indefinitely after an LLM failure

Rejected because it hides persistent faults, increases latency and cost, and may
repeat the same invalid result without progress.

## Review request contract

The LLM review request contains only the context needed for the current review:

- normalized, Scryfall-resolved deck entries and relevant card facts;
- deterministic legality findings that materially affect the advice;
- whether the deck is complete or an incomplete brew;
- the player's stated theme or intended experience;
- the current protected-card list;
- relevant refinement feedback and previously rejected recommendations;
- the required structured response shape and product constraints.

Unresolved card entries and raw provider errors are not sent as if they were valid
deck facts. Secrets, credentials, and unnecessary provider metadata are excluded.

## Review response contract

A successful response contains separate structured sections for:

- diagnosed strengths and weaknesses;
- theme and game-plan alignment;
- mana, draw, interaction, and protection findings;
- relevant gameplay risks;
- an ordered set of three to five recommendations, unless the response states why
  fewer responsible recommendations are possible;
- the diagnosed weakness addressed by each recommendation;
- an explanation of how each recommendation respects the stated theme;
- an addition and a specific non-protected cut for each complete-deck change;
- for an incomplete brew, whether an addition uses an open slot or includes a
  specific non-protected cut.

Application code validates the response before presentation. At minimum it checks
the response shape, protected-card constraint, recommendation count, required cuts,
and references to resolved submitted cards where the response discusses the
existing deck. Proposed additions follow the verification contract below. A
response that fails validation is not a completed review.

## Proposed-addition verification contract

The LLM may propose card names that are not in the submitted deck. Those names are
unverified suggestions when generated and are not shown as a completed review or
added to deck state immediately.

Before presentation, the application sends every proposed addition through the
card-data boundary. Each must resolve through Scryfall and pass deterministic
checks for the current commander configuration, including color identity, banned
status, and applicable copy-count rules. The application then validates the paired
cut, protected-card constraints, open-slot rules, and the remaining response.

If any addition is unknown, ambiguous, or illegal for the deck, the entire review
response is contract-invalid. The application may use its single automatic retry
with precise validation feedback. It does not show a partial review, silently
replace the card, or ask the player to approve an invalid addition. A second
invalid response ends generation under the existing failure contract.

## Card-name suggestion contract

The suggestion request contains the unresolved submitted name and only the minimum
context useful for proposing likely names. The response contains zero or more
candidate names, each explicitly marked as unverified.

Suggestions do not mutate deck state. The interface requires an explicit player
selection or correction. Every selected name returns to the deterministic
Scryfall-resolution path. If no suggestion is useful, the player may edit the
original entry directly.

## Failure contract

- **Timeout or unavailable LLM service:** no completed review or suggestion result
  is shown. The player receives a temporary failure message and may retry.
- **Authentication, permission, or quota failure:** do not retry automatically.
  Return an operational failure without exposing credentials or raw provider
  details.
- **Refusal:** do not present the refusal as a deck review. Explain that a review
  could not be generated and allow a deliberate retry when appropriate.
- **Malformed or contract-invalid output:** discard the result and allow at most
  one automatic retry with validation feedback that contains no secrets.
- **Second invalid result:** stop and report that a valid review could not be
  generated. Do not weaken validation to accept it.
- **Invented or unresolved card reference:** reject the entire response. A proposed
  addition must resolve and pass deterministic legality checks before presentation;
  the LLM cannot introduce an unverified card into the deck or authoritative
  findings.
- **Suggestion generation failure:** retain the original unresolved entry and let
  the player correct it manually. Do not block manual recovery.
- **Scryfall failure after player approval:** keep the suggestion unverified and do
  not begin the review.

Failures record enough internal context for diagnosis, but player-facing messages
do not expose prompts, secrets, stack traces, or raw provider responses.

## Verification examples

- Given a valid resolved deck and clear player intent, the LLM receives normalized
  context and a contract-valid response is presented as a review.
- Given a response that cuts a protected card, deterministic validation rejects it
  and permits at most one automatic retry.
- Given a complete deck recommendation without a cut, validation rejects the
  response even if its prose sounds reasonable.
- Given a proposed addition that resolves and passes deterministic legality checks,
  the application may present it after the complete response passes validation.
- Given any proposed addition that is unknown, ambiguous, off-color, banned, or
  otherwise invalid, the entire response is discarded and receives at most the
  existing single automatic retry.
- Given an unknown submitted name, the LLM may return candidate names, but none is
  added to the deck before explicit player selection and successful Scryfall
  resolution.
- Given an approved candidate that Scryfall cannot resolve, the review remains
  blocked and the player can provide another correction.
- Given a Scryfall outage, the LLM is not asked to replace missing card facts.
- Given two consecutive malformed review responses, generation stops with an
  actionable failure rather than retrying indefinitely or showing partial output.
