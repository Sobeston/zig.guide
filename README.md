# zig.guide

Repo for https://zig.guide content. Feedback and PRs welcome.

## Testing

```bash
zig build --summary all
```

## Contributing

1. Make use of `zig build` - it handles fmt and testing for you.
2. Use the correct Zig version; `zig build` will select what content to test based on your compiler version.
3. When fixing a regression, fix it in both the latest major release & master where applicable, and improve test coverage where possible.
4. Raise an issue or reach out before making large changes (e.g. new pages).

## Running the dev server

```bash
cd website
npm install
npm run docusaurus start
```
