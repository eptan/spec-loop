# Security Policy

This is a teaching repository. Do not commit credentials, tokens, private keys, `.env` files, or
generated artifacts. Report suspected vulnerabilities privately through the repository's GitHub security
contact rather than opening a public issue with sensitive details.

The repository's secret check is a review guard, not a guarantee. Rotate any credential that may have been
exposed and report the incident promptly.

Known, accepted dependency advisories with no available fix are recorded in
[`docs/dependency-advisories.md`](docs/dependency-advisories.md), which CI checks on every push so a new
advisory cannot land unreviewed.
