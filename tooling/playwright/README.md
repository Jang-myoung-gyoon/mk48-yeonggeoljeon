# Playwright route sweep

## Prerequisites
- Node.js
- `npx playwright` available
- A running Flutter web server (default `http://127.0.0.1:7357`)

## Run

```bash
flutter run -d web-server --web-port 7357
npx playwright test -c tooling/playwright
```

You can override the target server with `RALPHTHON_BASE_URL`.

Failure artifacts land in `playwright-report/` with screenshots and traces.
