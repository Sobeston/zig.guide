# zighelp

Repo for https://zighelp.org content. Feedback and PRs welcome.

## Generate docs locally

Requirements: `mkdocs`, `mkdocs-material`, `mkdocs-material-extensions`, `mkdocs-static-i18n` (install via Pip or your distribution packages).

```sh
# everything else is already in dependencies
pip install mkdocs-material mkdocs-static-i18n
mkdocs serve
```

## How to run the tests

1. `zig run test-out.zig`
2. `zig test do_tests.zig`
