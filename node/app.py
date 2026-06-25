"""A mesh node: a shared relay engine + per-node logic loaded at startup.

Every container runs this same engine, but each loads its own logic module from
logic/<LOGIC>.py (defaulting to logic/<NODE_ID>.py). That module is where a
node's unique behavior lives:

    role "relay"     -> defines transform(text) -> text. The node applies it,
                        records the change in the message trail, forwards on.
    role "collector" -> defines choose(candidates) -> candidate. The node gathers
                        every branch's arrival for a message, then picks one.

A message carries its own history so the visualizer can show how it mutated:
    {id, origin, original, text, trail: [{node, in, out}, ...]}

Environment variables:
    NODE_ID         Unique name (e.g. "node2a").
    PEERS           Comma-separated peer host:port to forward to.
    ROLE            "relay" (default) or "collector".
    LOGIC           Logic module name (default: NODE_ID).
    PROCESS_DELAY   Seconds a relay dwells in "received" before forwarding (default 1).
    COLLECT_WINDOW  Seconds a collector waits for branches after the first arrival (default 3).
"""
import importlib
import os
import threading
import time

import requests
from flask import Flask, jsonify, request

NODE_ID = os.environ.get("NODE_ID", "unknown")
PEERS = [p.strip() for p in os.environ.get("PEERS", "").split(",") if p.strip()]
ROLE = os.environ.get("ROLE", "relay")
LOGIC = os.environ.get("LOGIC", NODE_ID)
PROCESS_DELAY = float(os.environ.get("PROCESS_DELAY", "1"))
COLLECT_WINDOW = float(os.environ.get("COLLECT_WINDOW", "3"))

logic = importlib.import_module(f"logic.{LOGIC}")

app = Flask(__name__)

_lock = threading.Lock()
_status = "waiting"        # "waiting" | "received" | "sent" | "chose"
_last_message = None       # the message this node produced / accepted
_seen_ids = set()          # relay: IDs already forwarded (drop duplicates)
_candidates = {}           # collector: message id -> [arrived messages]
_decision = None           # collector: {chosen, candidates} for display


def _peer_names():
    return [p.split(":")[0] for p in PEERS]


def process_relay(msg):
    """Transform the message and forward it to every peer, once per message ID."""
    global _status, _last_message

    mid = msg.get("id")
    with _lock:
        if mid in _seen_ids:
            return  # already handled — drop to break loops
        _seen_ids.add(mid)
        _status = "received"

    incoming = msg.get("text", "")
    outgoing = logic.transform(incoming)
    entry = {"node": NODE_ID, "in": incoming, "out": outgoing}
    new_msg = {**msg, "text": outgoing, "trail": msg.get("trail", []) + [entry]}

    with _lock:
        _last_message = new_msg

    time.sleep(PROCESS_DELAY)  # dwell so "received" is observable

    for peer in PEERS:
        try:
            requests.post(f"http://{peer}/message", json=new_msg, timeout=2)
        except requests.RequestException:
            pass

    with _lock:
        _status = "sent"


def process_collect(msg):
    """Collect every branch's arrival for a message, then choose one."""
    global _status

    mid = msg.get("id")
    first = False
    with _lock:
        if mid not in _candidates:
            _candidates[mid] = []
            first = True
        _candidates[mid].append(msg)
        _status = "received"

    if first:
        threading.Thread(target=decide, args=(mid,), daemon=True).start()


def decide(mid):
    """After the collection window, run the node's choose() and accept a winner."""
    global _status, _last_message, _decision

    time.sleep(COLLECT_WINDOW)
    with _lock:
        candidates = list(_candidates.get(mid, []))

    chosen = logic.choose(candidates)

    with _lock:
        _decision = {"chosen": chosen, "candidates": candidates}
        _last_message = chosen
        _status = "chose"


@app.route("/message", methods=["POST"])
def message():
    msg = request.get_json(force=True)
    handler = process_collect if ROLE == "collector" else process_relay
    threading.Thread(target=handler, args=(msg,), daemon=True).start()
    return jsonify({"ok": True})


@app.route("/reset", methods=["POST"])
def reset():
    global _status, _last_message, _decision
    with _lock:
        _status = "waiting"
        _last_message = None
        _decision = None
        _seen_ids.clear()
        _candidates.clear()
    return jsonify({"ok": True})


@app.route("/health")
def health():
    return jsonify({"id": NODE_ID, "status": "healthy"})


@app.route("/state")
def state():
    with _lock:
        return jsonify(
            {
                "id": NODE_ID,
                "role": ROLE,
                "status": _status,
                "last_message": _last_message,
                "decision": _decision,
                "peers": _peer_names(),
            }
        )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
