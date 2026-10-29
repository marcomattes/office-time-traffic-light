# Office Light

A personal tool that shows whether I have spent enough time in the office on a given day.

## Language

**Office time**:
The span from the first to the last detection on an office network today (resets at midnight).
_Avoid_: presence time, attendance, working time

**Scheduled hours**:
The configurable daily reference working time (default: 8 h).
_Avoid_: workday, day

**Daily goal**:
The office time from which a day counts as reached; derived from scheduled hours and quota (default: 80 %).
_Avoid_: threshold, limit, 80 %

**Office network**:
A network that identifies me as being in the office: a configured Wi-Fi SSID or a configured IP range.
_Avoid_: company network, office Wi-Fi

**Light**:
The always-visible indicator of today's state: gray (no office time yet today), red (daily goal not reached), green (daily goal reached).
_Avoid_: indicator, status icon, dot
