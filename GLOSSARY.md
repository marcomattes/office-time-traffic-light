# Office Light

A personal tool that shows whether I have spent enough time in the office on a given day, and on enough days in a month.

## Language

**Office time**:
The span from the first to the last detection on an office network today (resets at midnight).
_Avoid_: presence time, attendance, working time

**Scheduled hours**:
The configurable daily reference working time (default: 8 h).
_Avoid_: workday, day

**Break**:
The configurable daily break (default: 45 min). Office time includes it, so it is added to the daily goal.
_Avoid_: pause, lunch

**Daily goal**:
The office time from which a day counts as reached: scheduled hours × quota (default: 80 %) + break.
_Avoid_: threshold, limit, 80 %

**Office day**:
A day on which the daily goal was reached.
_Avoid_: office visit, attendance day

**Working day**:
Monday to Friday. Holidays and vacation are not known to the app.
_Avoid_: business day, workday

**Monthly goal**:
The number of office days needed in a calendar month: working days × monthly quota (default: 50 %), rounded up.
_Avoid_: monthly target, 50 %

**Office network**:
A network that identifies me as being in the office: a configured Wi-Fi SSID or a configured IP range.
_Avoid_: company network, office Wi-Fi

**Light**:
The always-visible indicator of today's state: gray (no office time yet today), red (daily goal not reached), green (daily goal reached).
_Avoid_: indicator, status icon, dot
