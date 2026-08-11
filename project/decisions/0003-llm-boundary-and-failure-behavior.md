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
- the explicit, legality-validated commander configuration and its resolved card
  facts;
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
- an ordered set of three to five recommendations, unless the application's
  deterministic recommendation gate permits fewer;
- when fewer than three are permitted, a `reduced_count_reason_code` matching the
  deterministic gate supplied by the application;
- the diagnosed weakness addressed by each recommendation;
- an explanation of how each recommendation respects the stated theme;
- an optional `necessity_justification` field that is otherwise empty and is
  required when repeating a previously rejected recommendation under unchanged
  relevant constraints;
- a `fact_basis` for every player-facing card-mechanics claim, whether it concerns
  a submitted card or recommended addition, containing structured references to
  the normalized card facts used by that claim;
- an addition and a specific non-protected cut for each complete-deck change;
- for an incomplete brew, whether an addition uses an open slot or includes a
  specific non-protected cut.

Application code validates the response before presentation. At minimum it checks
the response shape, protected-card constraint, recommendation count, required cuts,
and references to resolved submitted cards where the response discusses the
existing deck. Proposed additions follow the verification contract below. A
response that fails validation is not a completed review.

Before enforcing the recommendation-count target, the application normalizes every
recommendation in the current response to its gameplay addition identity and,
when present, gameplay cut identity. Two recommendations with the same normalized
addition/cut pair are duplicates. Any duplicate pair invalidates the response; it
does not count again toward the three-to-five target.

The application determines whether fewer than three recommendations are permitted
before generation. It derives a `recommendation_limit` and reason code from
deterministic legality findings, available open slots, and the quantities of
eligible unprotected cut candidates. If that limit is at least three, the response
must contain three to five recommendations. If it is below three, the response may
contain no more than the limit and its `reduced_count_reason_code` must exactly
match the supplied gate. An LLM-authored explanation alone cannot reduce the count.

The application then validates the ordered recommendations as one cumulative
change set. Starting from the resolved submitted deck, each recommendation is
applied to a simulated deck in order. A cut must still exist in sufficient
quantity, must remain eligible and unprotected, and consumes that quantity. A
standalone addition consumes one available open slot. Each addition is checked
against the simulated post-cut state for color identity, banned status, and
copy-count rules. A plan that reuses an exhausted cut, exceeds its open slots, or
creates an impermissible duplicate is rejected even when every individual pair
would be valid in isolation.

During refinement, the application also normalizes each recommendation to its
resolved addition identity and, when present, resolved cut identity. It compares
those identities with previously rejected recommendations retained in the active
session. With unchanged relevant deck and player constraints, an unchanged repeat
is rejected unless its `necessity_justification` explicitly explains why the
recommendation remains necessary. A change in ordinary recommendation prose alone
does not create a new recommendation or satisfy that field.

For this comparison, relevant constraints are the normalized deck identities and
quantities, commander configuration, complete/incomplete designation, stated theme
or intended experience, protected-card identities, and explicit player feedback
that changes a review constraint. A bare rejection without explanatory feedback is
recorded for comparison but does not by itself count as a changed constraint.

## Proposed-addition verification contract

The LLM may propose card names that are not in the submitted deck. Those names are
unverified suggestions when generated and are not shown as a completed review or
added to deck state immediately.

Before presentation, the application sends every proposed addition through the
card-data boundary. Each must resolve through Scryfall and pass deterministic
checks for the current commander configuration, including color identity, banned
status, and applicable copy-count rules. The application then validates the paired
cut, protected-card constraints, open-slot rules, and the remaining response.

After proposed additions resolve, the application performs a grounding pass that
supplies their normalized gameplay facts, including Oracle text and face data, to
the LLM. The final recommendation explanations are generated or revised from those
facts. For each addition, the grounding response cites the supporting normalized
fact keys and values in `fact_basis`. Deterministic validation requires every cited
fact to match the resolved card identity and normalized value.

Player-facing card-mechanics claims are rendered from the validated `fact_basis`;
free-form LLM prose is not treated as an additional source of card facts. Missing,
mismatched, or unsupported fact references invalidate the response.

The same rule applies to diagnosis and explanation claims about cards already in
the submitted deck. Their `fact_basis` references the normalized gameplay identity
and exact fact keys and values supplied in the original review request. Proposed
additions reference the normalized facts returned after their resolution.

The grounding pass may not change addition or cut identities. An identity change
invalidates the attempt, consumes the single automatic retry, and does not trigger
resolution within that attempt. If the retry is available, the complete sequence
restarts with proposal generation, then Scryfall resolution, then a new grounding
pass. A second invalid attempt ends generation. Only the grounded, fully validated
response may be shown to the player.

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
- **Ungrounded or identity-changing recommendation:** reject a response with a
  missing, mismatched, or unsupported `fact_basis`, or whose grounding pass changes
  selected addition or cut identities. This consumes the attempt under the single-
  retry limit.
- **Ungrounded submitted-card claim:** reject a diagnosis or explanation containing
  a card-mechanics claim without a `fact_basis` that exactly matches the submitted
  card's normalized gameplay facts.
- **Unjustified repeated rejection:** when relevant constraints are unchanged,
  reject a recommendation with the same normalized addition/cut identities as a
  previous rejection unless its `necessity_justification` explains why it remains
  necessary.
- **Duplicate current recommendation:** reject a response containing the same
  normalized gameplay addition/cut pair more than once, before evaluating the
  recommendation count.
- **Unsupported reduced count:** reject fewer than three recommendations unless the
  deterministic `recommendation_limit` is below three and the response carries its
  matching `reduced_count_reason_code`.
- **Invalid cumulative plan:** reject an ordered set that reuses an exhausted cut,
  consumes more open slots than exist, or becomes illegal when its changes are
  applied sequentially to the simulated deck.
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
- Given the same normalized addition/cut pair repeated in one response, validation
  rejects the response and the repeated pair does not satisfy the recommendation
  count.
- Given a deterministic recommendation limit of at least three, a one-item response
  is rejected regardless of the LLM's explanation.
- Given a deterministic limit below three, a reduced response is accepted only up
  to that limit and with the exact supplied reason code.
- Given distinct recommendation pairs that reuse a cut beyond its available
  quantity, exhaust open slots, or create an illegal cumulative copy count, ordered
  simulation rejects the complete response.
- Given unchanged deck and player constraints, a previously rejected addition/cut
  pair repeated without a necessity explanation is rejected; changed wording alone
  does not make it new.
- Given changed relevant constraints or an explicit structured necessity
  explanation, a previously rejected recommendation may be considered again.
- Given a complete deck recommendation without a cut, validation rejects the
  response even if its prose sounds reasonable.
- Given a proposed addition that resolves and passes deterministic legality checks,
  its normalized gameplay facts return to the LLM for the grounding pass; the
  application may present it only after the grounded response passes validation.
- Given a `fact_basis` reference that does not exactly match the resolved card's
  normalized fact, deterministic validation rejects the response.
- Given a diagnosis that attributes a mechanic to a submitted card, its
  `fact_basis` must exactly match that card's normalized gameplay identity and fact
  value or deterministic validation rejects the response.
- Given a grounding pass that changes an addition or cut identity, the response is
  invalid, consumes the attempt, and the changed identity is not resolved within
  that attempt; an available retry restarts the complete sequence.
- Given a deck containing multiple commander-eligible cards, the LLM receives the
  player's explicit legality-validated commander configuration rather than
  inferring commanders from the deck entries.
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
