# Decision 0004: Unsaved refinement-session lifetime

## Status

Accepted

## Context

The first deck-review slice lets a player refine a review repeatedly as their deck,
theme, protected cards, and feedback change. Saved deck workspaces and persistent
review history are explicitly outside this slice, but a player still needs enough
time to leave and return to an active refinement experience.

Without an explicit lifetime, the application cannot give predictable resume and
expiration behavior or test cleanup reliably. A short lifetime would make the
experience fragile for casual players, while permanent storage would create the
saved-workspace behavior intentionally deferred from this feature.

## Decision

An unsaved refinement session expires after 24 consecutive hours without a
successful player-initiated review or refinement action.

Each successful qualifying action resets the expiration deadline to 24 hours after
that action. There is no absolute maximum lifetime: continued successful use may
extend the session indefinitely.

Qualifying activity includes:

- completing the initial deck review;
- completing a requested refinement after the player changes the deck list, theme,
  intended experience, or protected-card list;
- completing a requested refinement after the player rejects a recommendation or
  supplies relevant feedback.

The following do not extend the session:

- opening, refreshing, or merely viewing the page;
- polling or background health checks;
- starting a request that fails or is abandoned;
- validation failures that do not produce a completed review;
- automatic retries that do not produce a completed review.

A refresh may resume the session only when the client still has the session
identifier and the session has not expired. The product does not promise recovery
if the player loses that identifier, clears browser state, or changes devices.

## Rationale

- A 24-hour inactivity window lets a casual player leave and return the next day
  without implying permanent storage.
- Sliding expiration supports ongoing refinement without interrupting an active
  player because of an unrelated absolute deadline.
- Resetting only after successful player-initiated work prevents passive traffic
  and failing retry loops from retaining sessions indefinitely.
- Explicit non-recovery behavior keeps persistent workspaces and account-based
  history outside the first slice.

## Alternatives considered

### Eight-hour sliding inactivity timeout

Rejected because it may expire during a normal overnight break and force the
player to reconstruct context too soon.

### Separate inactivity and absolute lifetime limits

Rejected for this slice because an absolute limit could terminate a session that
the player is still actively refining. The additional rule is not needed to
express the selected temporary-session behavior.

### Fixed lifetime that activity cannot extend

Rejected because it can expire during active use and makes the remaining session
time depend on when the initial review began rather than whether the player is
still engaged.

### Permanent or account-based storage

Deferred. Saved deck workspaces and persistent review history are planned for a
later feature and require separate product and data-retention decisions.

## Session contract

On successful completion of the initial review, the application returns an opaque
session identifier and an expiration timestamp. The expiration timestamp is 24
hours after the successful completion time.

Each successful qualifying refinement response returns the same logical session
identifier and a new expiration timestamp 24 hours after that success. The latest
successful response determines the current deadline.

Requests identify the session using the opaque identifier. Clients do not derive,
modify, or depend on information encoded inside that identifier.

The active session retains only the context required for refinement, including the
latest accepted deck list, player intent, protected cards, and relevant feedback or
rejected recommendations. It does not promise a browsable or permanent history of
earlier review versions.

## Expiration and failure contract

The session is active strictly before its expiration timestamp. At or after that
timestamp it is expired and cannot accept further refinement.

Active identifiers resume normally. Expired, physically deleted, malformed, and
unknown identifiers all return the same player-facing `session unavailable`
outcome. That response tells the player to start a new review and resubmit the
latest deck and preferences. It does not reconstruct context from an LLM, logs, or
partial provider data and does not reveal whether the identifier ever existed.

The application may distinguish these causes internally for diagnostics while the
information exists. A temporary session-storage service failure remains a separate
retryable operational error because it does not disclose identifier history.

A qualifying request accepted strictly before expiry may finish after the prior
deadline. The session remains reserved while that request is in flight. Success
sets a new deadline 24 hours after completion; failure leaves the prior deadline
unchanged and therefore leaves the session expired. Cleanup must not remove an
in-flight session before this result is committed.

Expiration makes the session unavailable to the player. Physical deletion may
occur asynchronously, but expired data must not be usable for review or refinement.
Operational retention and deletion timing beyond that access rule require a
separate data-retention decision before production use.

## Verification examples

- Given a session created at 10:00, with no qualifying activity, a refinement at
  09:59 the next day may proceed and one at 10:00 is rejected as expired.
- Given a successful refinement at 09:00 the next day, the new expiration is 09:00
  on the following day.
- Given repeated successful refinements less than 24 hours apart, the session may
  remain active without an absolute maximum lifetime.
- Given page refreshes or polling but no successful qualifying action, the original
  expiration timestamp does not change.
- Given a failed refinement request, the expiration timestamp does not change.
- Given a qualifying request accepted before expiry that succeeds after the prior
  deadline, the session remains active and expires 24 hours after completion.
- Given a qualifying request accepted before expiry that fails after the prior
  deadline, the session is expired.
- Given an expired session, possessing its identifier does not restore access and
  the player is directed to start a new review.
- Given an expired, deleted, malformed, or unknown identifier, the player observes
  the same `session unavailable` outcome.
- Given a temporary storage-service failure, the player receives a retryable
  service error rather than a claim about the identifier.
- Given lost browser state or use of another device, the product does not promise
  recovery of the unsaved session.
