# Security Policy

## Reporting A Vulnerability

Please report security issues privately through GitHub security advisories when available. If advisories are unavailable, contact the maintainer directly and avoid publishing exploit details in a public issue.

## Scope

Security-sensitive areas include:

- kubeconfig generation and cleanup
- registry credentials and mirror configuration
- local cluster API server exposure
- container labels and lifecycle ownership
- image archive handling
- node container capabilities, sysctls, and mounts

## Secret Handling

Do not include kubeconfig credentials, service account tokens, registry credentials, private keys, or private image names in public issues, logs, screenshots, tests, or documentation.
