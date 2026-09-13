# agent-attribution Specification

## MODIFIED Requirements

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
