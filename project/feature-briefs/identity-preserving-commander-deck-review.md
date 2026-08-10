# Feature Brief: Identity-Preserving Commander Deck Review

## Status

Approved

## Problem and Evidence

Casual Commander players often want to strengthen a deck they already enjoy without replacing the theme, experience, or favorite cards that make the deck personally meaningful. General advice can identify technically stronger cards while failing to respect that intent, leaving the player without an improvement plan they would actually use.

### Confirmed Product Decisions

- The first target user is a casual Commander player improving a deck they already enjoy.
- Preserving theme and deck identity is more important than optimizing for a power tier.
- The player can state the deck's theme or intended experience and identify a short list of cards that must not be removed.
- The review covers both complete decks and incomplete brews.
- The player receives a detailed diagnosis and a prioritized set of card additions or swaps.
- The player can refine the review repeatedly as their preferences and deck list evolve.
- Card price and upgrade budget are not considered in this slice.

### Assumptions to Validate

- Players can describe their intended theme or experience clearly enough to guide a useful review.
- A short protected-card list is sufficient to represent the most important parts of a deck's identity.
- Three to five prioritized recommendations are enough to be actionable without overwhelming the player.
- Players will find recommendations more useful when each one is tied to a diagnosed weakness.
- Players will consider the review successful when it provides a clear improvement plan while respecting their stated intent.

## Target User and User Story

### Target User

A casual Commander player who has a complete deck or an incomplete brew and wants to strengthen it without losing its theme, intended play experience, or favorite cards.

### User Story

As a casual Commander player, I want a detailed review that respects my deck's theme and protected cards so that I can make useful improvements without turning it into a different deck.

## Desired Outcome and Success Signal

The player leaves the review with a clear, prioritized plan for improving the deck and feels that the plan preserves the deck's identity.

The primary success signal is that the player can identify a concrete next set of changes they would consider making and confirms that the recommendations align with the theme and protected-card constraints they provided.

## In-Scope Behavior

- The player can provide either a complete Commander deck or an incomplete Commander brew.
- The player can describe the deck's theme, intended experience, or both.
- The player can identify a short list of protected cards that recommendations must not remove.
- The review evaluates:
  - alignment with the stated theme and intended experience;
  - clarity and support for the deck's game plan;
  - mana resources;
  - card draw;
  - interaction;
  - protection;
  - likely weaknesses during a typical Commander game.
- The review presents a detailed diagnosis in clear language.
- The review provides three to five prioritized card additions or swaps, with each recommendation tied to the diagnosis.
- For an incomplete brew, open slots and weak existing cards are considered together in one prioritized improvement plan.
- The review flags Commander legality problems that materially affect the advice, including color-identity violations, duplicate nonbasic cards, banned cards, and an ineligible commander.
- An incomplete brew is not treated as illegal solely because it contains fewer than 100 cards.
- The player can reject recommendations, protect additional cards, remove cards from the protected list, clarify or change the stated theme, update the deck list, and request another review.
- Repeated reviews reflect the player's latest deck list and stated intent during the active refinement experience.

## Out-of-Scope Behavior

- Card prices, total upgrade budgets, and price-based recommendation filtering.
- Power-level classification or optimization toward a particular power tier.
- Competitive metagame preparation.
- A separate comprehensive Commander legality report.
- Saved deck workspaces that can be reopened later.
- Persistent review history or comparison between earlier deck versions.
- Automatically applying recommended changes on the player's behalf.

## Acceptance Criteria

1. Given a complete Commander deck, a stated theme or intended experience, and optional protected cards, the player receives a review covering theme alignment, game-plan support, mana, card draw, interaction, protection, and likely gameplay weaknesses.
2. Given an incomplete Commander brew, the player receives a review that considers both open slots and weak existing cards without rejecting the brew solely because it has fewer than 100 cards.
3. Every review provides three to five prioritized additions or swaps unless a legality problem or insufficient player context prevents responsible recommendations; when that occurs, the review clearly explains what must be resolved or clarified.
4. Each recommended addition or swap explains which diagnosed weakness it addresses and how it supports the stated theme or intended experience.
5. No recommendation removes a card currently identified by the player as protected.
6. The review does not rank or alter recommendations based on card price, upgrade budget, competitive metagame, or an assumed power tier.
7. When the deck contains a relevant Commander legality problem, the player is told what the problem is and why it affects the review.
8. The player can reject a recommendation or revise the theme, protected-card list, or deck list and receive a new review reflecting that latest context.
9. During refinement, previously rejected recommendations are not repeated unchanged unless the player changes relevant constraints or the review explains why the recommendation remains necessary.
10. The review distinguishes diagnosed weaknesses from suggested changes so the player can understand the reasoning even if they decline every recommendation.
11. At the end of a successful review, the player has a clearly ordered set of changes to consider and can judge whether those changes preserve the deck's identity.

## Edge Cases and Product Rules

- A protected card may appear inefficient or conflict with the deck's stated game plan; the review may explain that tension but must not recommend removing the card.
- If the stated theme conflicts with the protected cards, the review should surface the conflict and ask the player to clarify their priority rather than silently choosing one.
- If the theme is too broad or ambiguous to guide recommendations, the review should request clarification before presenting a definitive improvement plan.
- A complete deck with more or fewer cards than Commander normally permits should receive a relevant legality flag; an explicitly incomplete brew should remain reviewable.
- Basic lands and cards whose rules permit multiple copies are not treated as singleton violations.
- Recommendations must respect the commander's color identity.
- If fewer than three responsible recommendations can be made, the review should provide the useful recommendations available and explain why it stopped short of three.
- If the player rejects a recommendation without explanation, the next review should respect the rejection while allowing the player to give additional context.
- If the player changes the theme substantially, the next review may differ materially from earlier advice and should make that relationship clear.
- Advice should be framed as choices for the player, not as a claim that there is one objectively correct version of a casual Commander deck.

## Open Questions

- What is the maximum number of protected cards that still qualifies as a short list?
- What minimum deck information is necessary to provide a responsible review of an early incomplete brew?
- How should the player express a theme or intended experience when a deck has multiple equally important themes?
- What wording or user feedback best demonstrates that the deck's identity was preserved?
- When should a rejected recommendation become eligible to appear again after the deck or constraints change?

## Dependencies

- A reliable definition of current Commander legality, including banned cards, color identity, singleton exceptions, commander eligibility, and deck-size rules.
- Sufficient card information to explain how recommendations relate to the deck's theme, game plan, and diagnosed weaknesses.
- Product validation with representative casual Commander decks and incomplete brews.

## Risks

- "Preserve deck identity" is subjective, so a review may be technically reasonable while still feeling wrong to the player.
- Players may provide themes that are vague, contradictory, or different from what the deck list appears to support.
- Protected-card choices may prevent meaningful improvement; the product must explain constraints without disregarding them.
- Detailed reviews may overwhelm casual players if prioritization and language are not clear.
- Open-ended refinement materially expands the experience beyond a one-time report and could make the initial slice harder to keep focused.
- Legality guidance can become outdated and undermine trust if it is incorrect.

## Immediate Next Feature

After validating the usefulness of review and refinement, add persistent deck workspaces with full saved deck and review history so players can leave, return later, and compare how their deck and recommendations evolved.
