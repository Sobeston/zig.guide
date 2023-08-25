# zighelp

Repo for https://zighelp.org content. Feedback and PRs welcome.

https://zighelp.org is a fork of ziglearn.

It offers couple of improvements over ziglearn:

- simpler section navigation only on the left
- next/previous chapter at the bottom
- light/dark themes
- searching
- updated code and content for zig master
- full build system (mkdocs and github actions) in repo
- CI/CD that tests zig code with latest zig master build before merging
- Infrastructure for translations thanks to @BratishkaErik. Right now you can choose English or Russian (just a stub). Help translating zighelp!
- Every PR has checks
- mkdocs validation for navigation
- Use of requirements.txt for installing python packages.
- Some small changes to README.md about installing locally, creating PR with gh.

In the feature I plan to:

- actively merge community PRs
- add languages other than English
- extend content with more examples, topics
- actively update content to zig master
- have epub/pdf for download

**Why fork of ziglearn?**

I wanted to add light mode, and a few other things.

I also wanted to be able to add content without having to wait too long for a PR to be merged.

Also there is a lot of good content in the ziglearn repo that hasn't been merged yet.

## Generate docs locally

```sh
$ python -m venv env
$ source env/bin/activate
$ pip install -r requirements.txt
$ mkdocs serve
$ deactivate
```

How requirements.txt where created:

```sh
$ pip install mkdocs-material==9.2.3 mkdocs-static-i18n==0.56
$ pip freeze > requirements.txt
```

## How to run the tests

1. `zig run test-out.zig`
2. `zig test do_tests.zig`

## TODO

- [ ] HashMap example with dupe
- [ ] PRs from ziglearn repo
- [ ] make test run on Windows
- [x] i18n aka internationalization aka translations

## Contributing

When creating PR, change default base repository to zighelp/zighelp.

You may also use gh to crete correct PR for you:

`gh pr create --web`

That's because this project is a github fork and there is a [bug still](https://github.com/orgs/community/discussions/11729#discussioncomment-6793106).
