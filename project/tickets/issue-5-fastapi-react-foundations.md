# Issue #5 Microtickets: FastAPI and React TypeScript Foundations

## Status

Ready for developer implementation, one microticket at a time.

## Source and scope

- GitHub issue: #5, `Engineering: Establish FastAPI and React TypeScript foundations`
- Parent feature: #3, `Feature: Identity-preserving Commander deck review`
- Dependency: #4, complete
- Feature brief: `project/feature-briefs/identity-preserving-commander-deck-review.md`
- Branch: `feat/5-fastapi-react-foundations`

These tickets cover health/startup behavior and local development wiring only. They
must not introduce deck-review behavior, card data, legality rules, LLM calls,
session storage, deployment infrastructure, or other external integrations.

Complete the tickets in order. Keep commits small enough that each commit has one
clear reason to exist. Before starting each ticket, explain the intended change
and how its evidence will show that the goal was met.

## Microticket 5.1: Define the backend project boundary

### Narrow goal

Create only the minimum backend project and dependency metadata needed for a
Python application to be installed in a clean local environment.

### Why it exists

The backend needs a repeatable foundation before application behavior or tests can
be added.

### Acceptance criteria

- A clearly named backend area exists in the repository.
- Its declared runtime dependencies support the planned FastAPI service.
- Its declared development dependencies support the later test, format, and type
  checks required by Issue #5.
- A developer can install the declared dependencies from repository instructions.

### Constraints and interfaces

- Do not add an application endpoint, frontend files, or deck-review behavior.
- Do not add dependencies without being able to explain their role.
- Keep generated artifacts, virtual environments, and local caches out of version
  control.

### Likely risk areas

- Mixing runtime and development concerns without a clear contract.
- Creating multiple competing sources of dependency truth.
- Relying on undeclared globally installed tools.

### Completion evidence

- Show the clean-environment install command and successful result.
- Show the dependency/configuration diff.
- Confirm `git status` contains no generated environment or cache files.

### Dependencies

- Issue #4

### Definition of done

The backend dependency boundary is committed on the feature branch, its install
evidence has been recorded for review, and no application behavior was added.

## Microticket 5.2: Add backend startup and health behavior

### Narrow goal

Make the backend application start and expose one health check with a small,
stable HTTP contract.

### Why it exists

Developers and later automation need a deterministic way to tell whether the
service is running.

### Acceptance criteria

- The backend starts through one documented development command.
- One health request returns a successful HTTP status and a stable JSON body.
- The application exposes no deck-review workflow.

### Constraints and interfaces

- State the intended health path, status, and response body before implementation.
- Keep the health response independent of external providers and product data.
- Do not add frontend wiring or production deployment configuration.

### Likely risk areas

- Treating process startup as proof that the HTTP application is reachable.
- Allowing health behavior to depend on services outside this issue.
- Adding framework structure for hypothetical future needs.

### Completion evidence

- Show the exact startup command.
- Show one real HTTP request and its status/body.
- Show that an intentional invalid path does not masquerade as healthy.

### Dependencies

- Microticket 5.1

### Definition of done

The minimal backend starts locally, the health contract is demonstrated, and the
change is committed without unrelated behavior.

## Microticket 5.3: Automate the backend health check

### Narrow goal

Add an automated test for the backend health contract.

### Why it exists

Manual requests are useful during development, but they do not protect the startup
contract from later regressions.

### Acceptance criteria

- An automated test reaches the application through its HTTP boundary.
- The test verifies the agreed health status and complete response contract.
- The test fails when that contract is intentionally broken.

### Constraints and interfaces

- Test only behavior introduced by Microticket 5.2.
- Do not test FastAPI itself or private implementation details.
- Do not require external network access or long-lived manual processes.

### Likely risk areas

- A test that imports data without exercising the HTTP application.
- Assertions too weak to detect a changed response.
- Tests that leak ports, processes, or resources.

### Completion evidence

- Show the focused test passing.
- Briefly report how the failure behavior was checked.
- Show the test and application diff together for review.

### Dependencies

- Microticket 5.2

### Definition of done

The backend health contract has a deterministic automated regression test and the
focused test passes from a clean checkout setup.

## Microticket 5.4: Define and verify backend quality commands

### Narrow goal

Make the backend format, type-check, and test commands explicit and repeatable.

### Why it exists

Contributors and CI need the same definition of a healthy backend change.

### Acceptance criteria

- Repository documentation names one backend formatting command, one backend type
  check command, and one backend test command.
- Configuration for those commands is version controlled.
- All three commands pass on the backend foundation.

### Constraints and interfaces

- Do not add a CI service or deployment workflow.
- Avoid overlapping tools unless each has a distinct, documented purpose.
- Do not weaken checks merely to make the initial scaffold pass.

### Likely risk areas

- Commands behaving differently depending on the working directory.
- Tools silently ignoring the actual source or test paths.
- Formatting and lint rules contradicting each other.

### Completion evidence

- Capture the exact commands and successful outputs.
- Demonstrate which files each command covers.
- Show any configuration changes in the review diff.

### Dependencies

- Microticket 5.3

### Definition of done

The documented backend format, type, and test commands run successfully and the
configuration is committed.

## Microticket 5.5: Define the frontend project boundary

### Narrow goal

Create the minimum Vite-powered React TypeScript client that can install and start
locally.

### Why it exists

The browser client needs a repeatable, typed foundation before it communicates
with the backend.

### Acceptance criteria

- A clearly named frontend area exists in the repository.
- Its package metadata declares the dependencies needed for Vite, React, and
  TypeScript development.
- A documented command starts the client and serves a page.
- The page contains no deck-review workflow.

### Constraints and interfaces

- Do not connect to the backend yet.
- Do not add a design system, router, state library, or production hosting setup.
- Review generated scaffold files and retain only what serves this issue.

### Likely risk areas

- Committing dependency installation output.
- Keeping unexplained sample behavior that obscures the real foundation.
- Adding speculative frontend architecture.

### Completion evidence

- Show a clean dependency installation.
- Show the development startup command and the served page in a browser.
- Confirm generated dependency and build directories are ignored.

### Dependencies

- Microticket 5.4

### Definition of done

The minimal typed client installs and starts locally, browser evidence is recorded,
and the focused scaffold is committed.

## Microticket 5.6: Add a frontend render smoke test

### Narrow goal

Add one automated test proving the root frontend application renders.

### Why it exists

A buildable scaffold can still fail at runtime; a render test provides a small
regression boundary before backend communication is introduced.

### Acceptance criteria

- An automated test renders the root application.
- It verifies one stable, user-visible element owned by the application.
- The test does not require the backend or external network access.

### Constraints and interfaces

- Do not test generated framework internals or implementation details.
- Do not add backend mocking before backend communication exists.
- Keep the test focused on application startup/render behavior.

### Likely risk areas

- An assertion that passes even when the application renders nothing useful.
- Test environment configuration that differs materially from browser behavior.
- Large snapshots that make failures difficult to interpret.

### Completion evidence

- Show the focused test passing.
- Briefly report how an intentional render break was detected.
- Show the test configuration and test diff.

### Dependencies

- Microticket 5.5

### Definition of done

The client root has a small deterministic render test and the focused test passes.

## Microticket 5.7: Define and verify frontend quality commands

### Narrow goal

Make the frontend format, type-check, and test commands explicit and repeatable.

### Why it exists

The frontend needs the same clear quality contract as the backend.

### Acceptance criteria

- Package scripts or repository documentation expose one frontend formatting
  command, one frontend type-check command, and one frontend test command.
- Configuration for these commands is version controlled.
- All three commands pass on the frontend foundation.

### Constraints and interfaces

- Do not add CI or production build deployment.
- Ensure a type check genuinely invokes the TypeScript compiler contract.
- Do not hide failures through permissive command chaining.

### Likely risk areas

- Confusing linting with formatting or type checking.
- Tests remaining in watch mode instead of terminating for automation.
- Commands that only work through globally installed packages.

### Completion evidence

- Capture the exact commands and successful outputs.
- Confirm the test command exits without manual input.
- Show which frontend files the checks cover.

### Dependencies

- Microticket 5.6

### Definition of done

The frontend format, type, and test commands are documented, deterministic, and
passing.

## Microticket 5.8: Establish the development HTTP boundary

### Narrow goal

Define and configure how browser code addresses the backend during local
development.

### Why it exists

The two applications need one predictable development boundary before the client
can make a real health request.

### Acceptance criteria

- The development request path and origin behavior are documented.
- Browser requests can use the chosen development boundary without embedding an
  unexplained machine-specific address in application code.
- Misconfiguration produces a visible failure rather than a false healthy state.

### Constraints and interfaces

- Before implementation, compare the relevant tradeoffs of a development proxy
  and direct cross-origin requests, then choose one for this issue.
- Keep production URL, deployment, authentication, and external integration
  decisions out of scope.
- Do not add deck-review endpoints.

### Likely risk areas

- Development behavior that cannot be reproduced on another machine.
- Accidentally treating a development-only origin policy as production security.
- Configuration defaults that conceal a missing backend.

### Completion evidence

- Show the documented request/origin contract.
- Show the configuration diff and explain the chosen boundary.
- Demonstrate the browser's request destination using development tooling.

### Dependencies

- Microticket 5.7

### Definition of done

The local HTTP boundary is documented and configured, with evidence that browser
requests resolve to the intended backend development service.

## Microticket 5.9: Make the browser exercise backend health

### Narrow goal

Have the frontend perform one health request and represent success and failure
clearly enough to verify development wiring.

### Why it exists

Issue #5 requires evidence that the browser can reach the backend, not merely that
both applications start independently.

### Acceptance criteria

- With both applications running, the browser reaches the real backend health
  endpoint through the Microticket 5.8 boundary.
- The page distinguishes a successful response from an unavailable or invalid
  response.
- Automated frontend tests cover both the success and failure behavior at the
  client boundary.

### Constraints and interfaces

- Use only the health contract from Microticket 5.2.
- Do not introduce a reusable product API layer unless current behavior requires
  it.
- Do not add deck submission, card data, or other feature behavior.

### Likely risk areas

- Reporting success before the request actually completes.
- Swallowing failures or exposing raw internal errors to the page.
- Tests that accidentally contact a real server and become nondeterministic.

### Completion evidence

- Show browser evidence for a running backend and for a stopped backend.
- Show the focused automated tests passing.
- Show the browser network request status and response for the healthy case.

### Dependencies

- Microticket 5.8
- Backend health contract from Microticket 5.2

### Definition of done

The browser visibly exercises the backend health boundary, success and failure are
tested, and no product workflow has been introduced.

## Microticket 5.10: Automate full foundation startup smoke checks

### Narrow goal

Add an automated smoke check that proves both development applications can start
and become reachable.

### Why it exists

Unit and render tests do not catch invalid startup commands, missing runtime
dependencies, port conflicts, or applications that never become ready.

### Acceptance criteria

- Automation starts the backend and frontend from documented commands.
- It waits for an observable ready condition from each application and verifies
  each is reachable.
- It terminates all processes on both success and failure.
- It exits nonzero with useful diagnostics when either application cannot start or
  become ready within a bounded time.

### Constraints and interfaces

- Do not depend on a person opening a browser or stopping processes.
- Do not use unbounded waits or assume a process is ready merely because it was
  spawned.
- Avoid dependence on internet access after dependencies are installed.

### Likely risk areas

- Leaked child processes and occupied ports.
- Flaky timing assumptions.
- Diagnostics that omit which application failed.

### Completion evidence

- Show the smoke command passing from a clean stopped state.
- Demonstrate one controlled failure and its nonzero result.
- Confirm no application processes remain after the check exits.

### Dependencies

- Microticket 5.9

### Definition of done

One terminating automated check proves both applications start and are reachable,
handles failure cleanly, and is committed with its evidence.

## Microticket 5.11: Consolidate contributor instructions and final evidence

### Narrow goal

Make the completed foundation reproducible from repository documentation and
collect the final Issue #5 verification evidence.

### Why it exists

A foundation is not usable if the next contributor must infer setup, commands, or
development wiring from source files.

### Acceptance criteria

- Documentation describes prerequisites, installation, backend and frontend
  startup, development HTTP wiring, formatting, type checking, tests, and the full
  smoke check.
- Commands are presented with their required working directories or are runnable
  from an unambiguous common location.
- All documented commands pass from the committed state.
- The work remains inside Issue #5 boundaries.

### Constraints and interfaces

- Document only verified behavior.
- Do not rewrite product scope or resolve stale product artifacts as part of this
  ticket without separate authorization.
- Do not claim CI, deployment, or browser support that was not tested.

### Likely risk areas

- Documentation drifting from actual command names.
- Omitting prerequisite versions or environment assumptions.
- Treating manual evidence as a substitute for required automated checks.

### Completion evidence

- Run every documented format, type, test, and smoke command and retain the output
  for review.
- Show a final scoped diff against `main`.
- Confirm the pull request description links Issue #5 and parent Issue #3.

### Dependencies

- Microticket 5.10

### Definition of done

The committed documentation reproduces the development workflow, all required
checks pass, the diff is reviewable, and the pull request is ready for
pull-request-style review.
