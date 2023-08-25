# zighelp

Repo for https://zighelp.org content. Feedback and PRs welcome.

## Generate docs locally

```sh
$ python -m venv env
$ source env/bin/activate
$ pip install -r requirements.txt
$ mkdocs serve
$ deactivate
```

## How to run the tests

1. `zig run test-out.zig`
2. `zig test do_tests.zig`

## Contributing

When creating PR, change default base repository to zighelp/zighelp.

You may also us gh to crete correct PR for you:

`gh pr create --web`

That's because this project is a github fork and there is a [bug still](https://github.com/orgs/community/discussions/11729#discussioncomment-6793106),
