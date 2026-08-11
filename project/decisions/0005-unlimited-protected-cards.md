# Decision 0005: Unlimited protected cards

## Status

Accepted

## Context

The product promises to preserve the identity of a casual Commander deck. Players
express part of that identity by marking cards that recommendations must not
remove. The approved feature brief describes this as a short list but leaves the
maximum unresolved.

A fixed maximum would preserve more freedom for recommendations, but it could also
force a player to expose a personally important card as a cut candidate. The
product prioritizes player intent over producing an arbitrary number of changes.
The resulting constraint may make swaps impossible, especially when a player
protects most or all of a complete deck.

## Decision

There is no product-specific maximum number of protected cards. A player may
protect any number of cards in the submitted deck, including every card.

The commander is inherently protected and does not need to be added to the
player-managed protected-card collection. No recommendation may remove the
commander or another currently protected card.

Protected selections are normalized by resolved card identity. Repeating the same
selection does not create multiple protected entries. Each selected identity must
resolve through the card-data boundary and must occur in the current deck.

Protection is a hard constraint, not a preference. The review may explain that a
protected card appears inefficient, conflicts with the stated theme, or limits
improvement options, but it must not recommend removing that card.

If protection prevents responsible recommendations, the system returns the useful
diagnosis it can provide, explains the constraint, and invites the player to
unprotect cards voluntarily. It does not ignore protection to reach the normal
three-to-five recommendation target.

General request-size and abuse-prevention controls may still apply. They must not
introduce a smaller product-specific protected-card count than the number of unique
cards accepted in the deck itself.

## Rationale

- The player is the authority on which cards define the deck's identity.
- A hard maximum could force a false choice between receiving a review and
  preserving personally important cards.
- Explicitly allowing constrained or diagnosis-only outcomes is more honest than
  manufacturing swaps that violate the player's rules.
- Normalizing by resolved identity makes the constraint deterministic and prevents
  duplicate inputs from changing the result.
- Keeping protection hard and externally validated prevents an LLM from trading
  away identity constraints for apparently stronger recommendations.

## Alternatives considered

### Limit the player to 10 protected cards plus the commander

Rejected because the number is arbitrary and may not represent every player's
deck identity. It prioritizes recommendation flexibility over the stated product
goal.

### Treat protection as a soft preference

Rejected because the feature brief states that protected cards must not be
removed. A warning does not compensate for violating that promise.

### Refuse to review a deck with too many protected cards

Rejected because useful diagnosis may still be possible even when swaps are
constrained or impossible.

### Automatically unprotect cards that conflict with the theme

Rejected because the product must surface conflicts and ask the player to clarify
their priority rather than silently choosing for them.

## Request contract

The protected-card input contains zero or more card references associated with the
current deck. Each reference follows the same identity-resolution boundary used by
the deck list.

After resolution, the application creates a set of unique protected card
identities. The effective protected set is that player-managed set plus the
commander's identity.

An update replaces or deliberately modifies the current protected set according
to the refinement request. The next review uses the latest successfully validated
set; a failed update does not partially change it.

## Validation and failure contract

- **Card is not in the current deck:** reject that protected selection and identify
  it so the player can correct the deck or selection.
- **Unknown or ambiguous name:** use the established card-name clarification flow;
  no guessed identity becomes protected without player approval and Scryfall
  verification.
- **Duplicate selection:** normalize it to the existing protected identity rather
  than reporting an additional protected card.
- **Commander omitted:** keep the commander inherently protected; omission from the
  player-managed collection is not an error.
- **Deck update removes a protected card:** require the refinement request to
  reconcile that protected selection explicitly or return a clear validation
  result. Do not retain a hidden protected identity outside the current deck.
- **Every possible cut is protected:** return diagnosis and explain that no valid
  swap can be proposed under the current constraints. Invite, but do not require,
  the player to unprotect cards.
- **Fewer than three responsible recommendations remain:** return the useful
  recommendations available and explain why the normal target was not met.
- **LLM proposes a protected cut:** reject the response under the LLM response
  contract. Do not show the invalid recommendation or mutate protection.

## Verification examples

- Given zero player-selected cards, only the commander is inherently protected.
- Given one card selected repeatedly, the effective protected set contains one
  player-selected identity plus the commander.
- Given more than 10 unique valid selections, all are accepted; no product count
  limit is applied.
- Given every card protected in a complete deck, the review may diagnose weaknesses
  but provides no swap that requires removing a protected card.
- Given a protected card that conflicts with the stated theme, the review explains
  the tension without recommending that card as a cut.
- Given an LLM response naming a protected card as a cut, deterministic validation
  rejects the response.
- Given a protected selection absent from the current deck, validation identifies
  the selection and does not partially update the active protected set.
