# agent-attribution Specification

## Purpose

Define neutral attribution rules for repository-produced content while preserving external platform boundaries
and existing human-authored records.

## Requirements

### Requirement: Repository agent output uses neutral attribution

Agents operating in the repository MUST use neutral role labels such as `contributor`, `reviewer`, or
`agent` for repository-produced documentation, reports, reviews, and status messages. They MUST NOT add
provider names, commercial identities, logos, marketing signatures, or generated-by watermarks to newly
generated repository content. Existing human-authored attribution, copyright, licensing, and historical
review records MUST remain unchanged.

#### Scenario: Generated review remains neutral

- GIVEN an agent writes a review or report into the repository
- WHEN it identifies the author or reviewer role
- THEN it uses a neutral repository role
- AND it does not add a model/provider name, commercial signature, or generated-by watermark

### Requirement: Attribution policy states its platform boundary

The repository MUST document that its instructions govern repository-produced content and agent workflow
messages, but cannot remove branding or watermarks injected by an external Claude UI, API gateway, or
organization-managed platform. It MUST direct platform-level branding changes to the responsible administrator
or product settings outside the repository. This statement MUST live under a specifically named, checkable
section (`## Platform Boundary`) rather than being verifiable only by the incidental presence of a word
that could appear in unrelated prose.

#### Scenario: External watermark is not misrepresented as controlled

- GIVEN an external agent platform adds a watermark after repository content is generated
- WHEN a contributor reviews the repository attribution policy
- THEN the policy identifies the watermark as outside repository control
- AND it does not instruct agents to modify human attribution or licensing to conceal it

#### Scenario: The platform boundary is a checkable section, not an incidental word

- GIVEN the attribution policy document
- WHEN the repository check verifies the platform-boundary statement exists
- THEN it verifies the presence of the `## Platform Boundary` section heading
- AND a document that merely mentions the word "platform" elsewhere, without that section, fails the check

### Requirement: Agent rule updates reuse prior request context

The canonical `/agent-rule` command and `agent-rule` skill MUST update the shared `AGENTS.md` with one durable
rule. When invoked without a parameter, they MUST use the immediately preceding user request as the rule
context; explicit parameters MUST override that context. They MUST NOT update provider-specific adapter files
instead of the canonical guidance.

#### Scenario: Empty agent-rule invocation uses the preceding request

- GIVEN the preceding user request describes a concrete repository rule
- WHEN a contributor invokes `/agent-rule` without a parameter
- THEN the command uses that request as the rule context
- AND it updates `AGENTS.md` rather than a copied adapter file

#### Scenario: Explicit agent-rule input wins

- GIVEN the preceding conversation contains one possible rule
- WHEN a contributor invokes `/agent-rule` with explicit rule text
- THEN the command uses the explicit rule text
- AND it does not silently substitute the preceding conversation
