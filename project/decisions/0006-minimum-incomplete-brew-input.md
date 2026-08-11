# Decision 0006: Minimum incomplete-brew input

## Status

Accepted

## Context

The product supports both complete Commander decks and early incomplete brews. An
incomplete brew must not be rejected merely because it contains fewer than the
normal Commander deck size, but the system still needs enough player intent and
deck-specific evidence to produce a responsible identity-preserving review.

Without a minimum contract, the system might guess a strategy from a commander
alone, mistake an accidentally truncated submission for an intentional brew, or
present generic recommendations as though they were grounded in the player's
choices.

## Decision

An incomplete brew is eligible for review only when all of the following are
provided and validated:

- the player explicitly identifies the submission as an incomplete brew;
- one or more designated commanders resolve successfully and form a legal
  Commander configuration;
- the player states a theme, intended experience, or both;
- at least 10 distinct noncommander card identities resolve successfully.

The minimum counts distinct resolved card identities, not quantities or repeated
text entries. Ten copies of one identity therefore count as one identity for this
threshold. Designated commander identities do not count toward the 10-card
minimum.

Protected cards are optional. Any supplied protected card must satisfy the
protected-card contract and occur in the submitted brew.

Meeting the minimum permits a review; it does not guarantee that every diagnostic
category is supported equally well. The review distinguishes findings grounded in
submitted cards from areas that remain uncertain because the brew is incomplete.
It asks for clarification instead of inventing a theme, game plan, or missing deck
composition.

## Rationale

- A legal designated commander configuration establishes color identity and a
  primary strategic anchor.
- Stated intent is necessary because the same commander may support several
  different themes and experiences.
- Ten distinct noncommander identities provide evidence of the player's actual
  direction while keeping the feature useful early in brewing.
- Counting distinct identities prevents repeated quantities from creating a false
  impression of strategic breadth.
- An explicit incomplete designation separates a deliberate brew from a malformed
  or accidentally truncated complete-deck submission.
- Allowing qualified uncertainty is more honest than treating missing slots as
  diagnosed weaknesses.

## Alternatives considered

### Accept a commander with no other cards

Rejected because recommendations would be based primarily on common commander
patterns rather than the player's deck choices and would not constitute a detailed
review of their brew.

### Require a complete 100-card deck

Rejected because reviewing incomplete brews is explicitly in scope and additions
may use open slots without requiring cuts.

### Count total quantity rather than distinct identities

Rejected because repeated copies, including basic lands, could satisfy the number
without providing comparable evidence about the brew's game plan.

### Infer theme from the submitted cards

Rejected because inferred intent may conflict with the experience the player wants
to preserve. The system may discuss apparent tensions only after the player states
their intent.

### Use no numeric minimum and let the LLM decide

Rejected because eligibility would become nondeterministic and difficult to test.
The LLM may still explain uncertainty after deterministic eligibility is met.

## Request contract

An incomplete-brew review request contains:

- an explicit incomplete-brew designation;
- a deck list satisfying Decision 0001;
- one or more submitted commander designations;
- a nonblank statement of theme or intended experience;
- an optional protected-card collection;
- optional additional player context.

All submitted card entries pass through the card-data boundary before eligibility
is evaluated. Every designated commander must resolve as eligible for the role,
and multiple commanders must form a permitted configuration under authoritative
card and legality data. The remaining entries must contain at least 10 distinct
resolved identities excluding all designated commanders.

The deck may contain quantities and may be far below 100 cards. Being incomplete
is not itself a legality failure. Other material legality problems are still
reported under the established legality contract.

## Review contract

For an eligible incomplete brew:

- diagnosis is limited to evidence supported by the current cards and stated
  intent;
- missing slots are treated as opportunities, not automatically as weaknesses;
- a recommended addition may stand alone while an open slot exists;
- no more standalone additions are offered than available open slots;
- additions after all open slots are allocated include a specific non-protected
  cut;
- recommendations explain which grounded weakness or stated goal they address;
- uncertain categories are labeled as uncertain rather than filled with invented
  assumptions.

## Failure and clarification contract

- **Incomplete designation missing:** do not infer it solely from deck size. Ask
  whether the player intended an incomplete brew or submitted a truncated deck.
- **Commander designation missing:** request at least one designation before
  review.
- **Commander configuration ineligible, incompatible, or unresolved:** report the
  authoritative resolution or legality problem; do not ask the LLM to choose or
  repair the configuration.
- **Intent missing or blank:** ask for a theme or intended experience before review.
- **Fewer than 10 distinct resolved noncommander identities:** report the current
  count, the required count, and how many more distinct cards are needed.
- **Card resolution failures:** complete the established correction flow before
  counting identities or beginning review.
- **Contradictory theme and protected cards:** surface the tension and ask the
  player to clarify their priority rather than silently choosing one.

Eligibility failures may be returned together so the player can correct multiple
problems in one pass. No LLM deck review begins until the deterministic minimum is
satisfied.

## Verification examples

- Given a legal designated commander configuration, stated intent, explicit
  incomplete status, and 10 distinct resolved noncommander identities, the brew is
  eligible for review.
- Given multiple designated commanders that are not permitted together, the brew
  is not eligible until the configuration is corrected.
- Given the same request with nine distinct noncommander identities, the response
  says that one more distinct card is required and no review begins.
- Given 10 submitted copies of one noncommander identity, the threshold count is
  one, not 10.
- Given 10 distinct noncommander identities but no stated intent, the system asks
  for intent and does not infer it from the cards.
- Given 10 distinct noncommander identities but no incomplete designation, the
  system asks whether the deck is an incomplete brew or a truncated complete deck.
- Given an incomplete brew below 100 total cards that satisfies the minimum, deck
  size alone does not cause a legality rejection.
- Given open slots, standalone additions do not exceed those slots; later additions
  require non-protected cuts.
