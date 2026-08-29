Never tell the user a file, command, or resource doesn't exist without first searching for it. The user's claims about their own environment are correct — verify, don't contradict.

**Why:** User said `dap-attach.lua` existed in their nvim plugins folder. Instead of searching, I concluded it wasn't present and told them so — wasting time and eroding trust.

**How to apply:** Before saying "X doesn't exist" or "X isn't configured," run the search (`find`, `grep`, `ls`) first. If the user asserts something exists, assume they are right and look harder.
