---
name: web-browsing
description: Read, search, or interact with a web page. Triggers - URL pasted, "check this site", "what does X say", login/click/fill needed, page slow or erroring. Routes WebFetch vs chrome-devtools.
---

## Pick the cheapest tool that can work

Reaching for a browser first is the most common mistake here, and the slowest.

| Situation | Tool |
|---|---|
| Read one page whose content is in the HTML | `WebFetch` |
| Find pages, or check something is current | `WebSearch` |
| Library or framework documentation | `context7`, not a browser |
| Content only appears after JavaScript runs | chrome-devtools |
| Needs a login, a session, or cookies | chrome-devtools |
| Requires clicking, typing, or submitting | chrome-devtools |
| Diagnosing console errors, network, or slowness | chrome-devtools |

`WebFetch` returns in about a second. Launching Chrome, waiting for a page
load, and taking a snapshot is several seconds before anything is read. For a
static page that difference is pure waste, so try `WebFetch` first and escalate
only when it comes back empty, truncated, or obviously JavaScript-gated.

Escalate immediately, without trying `WebFetch`, when the task itself requires
interaction or authentication -- there is nothing to learn from the cheap
attempt in that case.

## Driving chrome-devtools

Read the page structure with `take_snapshot`, not `take_screenshot`. The
snapshot is an accessibility tree: text, roles, and the element uids that
`click`, `fill`, and `hover` take as arguments. A screenshot is an image that
costs far more context and cannot be clicked on. Take a screenshot only when
the question is genuinely visual -- layout, styling, or "does this look right".

A normal pass:

1. `new_page` with the URL, or `navigate_page` if a page is already open.
2. `take_snapshot` to see structure and get element uids.
3. `click` / `fill` / `fill_form` / `press_key` using those uids.
4. `wait_for` text that indicates the action landed, rather than assuming it did.
5. `take_snapshot` again after anything that changes the DOM -- uids from a
   previous snapshot are stale once the page updates.
6. `close_page` when finished.

Use `list_pages` and `select_page` when several tabs are open; page-scoped
tools route by page id.

## Diagnosing rather than reading

These have no equivalent in a fetch tool, and are the reason the browser is
worth its cost:

- `list_console_messages` for errors the page logged. First stop when something
  renders wrong.
- `list_network_requests` and `get_network_request` for failed calls, redirects,
  payloads, and status codes.
- `performance_start_trace` / `performance_stop_trace` /
  `performance_analyze_insight` for why a page is slow, with real trace insights
  rather than guesses.
- `lighthouse_audit` for a full performance, accessibility, and SEO pass.
- `take_heapsnapshot` when memory growth is suspected.
- `emulate` to reproduce a problem under a slow network, throttled CPU, or a
  different viewport.

## Notes

The browser runs with `--isolated`, so it starts with a fresh throwaway profile
every time. Logged-in state does not carry over between sessions, and a task
that needs a login must perform it.

Chrome only. There is no Firefox or WebKit available -- say so rather than
attempting a workaround if cross-browser behaviour is the actual question.
