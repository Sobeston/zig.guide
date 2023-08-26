# zighelp

Repo for https://zighelp.org content. Feedback and PRs are welcome.

Zighelp is a fork of [ziglearn](https://ziglearn.org/) which offers several improvements:

- Simpler navigation section, only on the left
- Easy access to next/previous chapter at the bottom
- Light/dark themes
- Search
- Updated code and content for latest Zig changes
- Full build system (`mkdocs` and github actions) in the repo
- CI/CD that tests Zig code with the latest Zig nightly build before merging
- Infrastructure for translations thanks to @BratishkaErik. Right now you can choose English or Russian (just a stub). Help translating zighelp!
- Every PR has checks
- `mkdocs` validation for navigation
- Use of `requirements.txt` for installing python packages.
- Some small changes to README.md about installing locally and creating PRs with `gh`.

For the future I plan to:
- Actively merge community PRs
- Add languages other than English
- Extend content with more examples, topics
- Keep the content updated with Zig's latest changes
- Make an epub/pdf available for download

**Why forking ziglearn?**

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

How `requirements.txt` was created:

```sh
$ pip install mkdocs-material==9.2.3 mkdocs-static-i18n==0.56
$ pip freeze > requirements.txt
```

## How to run the tests

1. `zig run test-out.zig`
2. `zig test do_tests.zig`

## TODO

- [ ] HashMap example with dupe
- [ ] Merge PRs from ziglearn repo
- [ ] Make tests run on Windows
- [x] i18n aka internationalization aka translations

## Contributing

When creating a PR, change the default base repository to `zighelp/zighelp`.

You may also use `gh` to create a correct PR for you:

`gh pr create --web`

That's because this project is a Github fork and there is still a [bug](https://github.com/orgs/community/discussions/11729#discussioncomment-6793106).
