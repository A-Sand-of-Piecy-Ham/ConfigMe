---
name: feedback_verify_before_denying
description: "Always verify with a search before telling the user something doesn't exist"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0e4177c8-e3ae-4797-9f1b-4407ff90a494
  modified: 2026-07-27T19:28:34.135Z
---

Never tell the user a file, command, or resource doesn't exist without first searching for it. The user's claims about their own environment are correct — verify, don't contradict.

**Why:** User said `dap-attach.lua` existed in their nvim plugins folder. Instead of searching, I concluded it wasn't present and told them so — wasting time and eroding trust.

**How to apply:** Before saying "X doesn't exist" or "X isn't configured," run the search (`find`, `grep`, `ls`) first. If the user asserts something exists, assume they are right and look harder.
