# Security

Only the current source line is maintained; no response-time or long-term-support guarantee is offered.

## Reporting

Please do not post exploitable vulnerabilities, private files, or credentials in a public issue.

If the repository's Security tab offers **Report a vulnerability**, use that private channel. If private reporting is not enabled and no maintainer contact is listed, open a minimal public issue asking for a private contact **without technical exploit details**, then wait for a confirmed channel.

Maintainers should enable GitHub private vulnerability reporting before publication. This template intentionally does not invent a maintainer email address.

## Scope

Relevant areas include unsafe handling of persisted data, unexpected USB-device targeting, code execution, malicious build/release artifacts, and dependency or CI supply-chain problems.

Luma currently has no network service, remote command interface, privileged helper, or automatic update mechanism. USB output is restricted to its fixed static-color protocol; the project does not expose arbitrary HID report injection.

A matching VID/PID is not proof of trusted hardware. Only use devices and builds you trust. Never disable system security protections globally to install an untrusted archive.
