"""node4 (collector): choose which branch's message to accept.

Receives a list of candidate messages (one per branch that reached it) and
returns the winner. Each candidate is the full message dict, so the choice can
use the text, the trail, or anything else.

This rule: accept the longest final text (ties broken by branch name).
"""


def choose(candidates):
    return min(candidates, key=lambda m: (len(m["text"]), m["trail"][-1]["node"]))
