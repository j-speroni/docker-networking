"""Visualizer backend.

Scrapes every node's /state to build a live graph of node statuses and the
ring topology, and provides controls to inject a message at a chosen origin
node and to reset the mesh.

Environment variables:
    NODES          Comma-separated host:port of nodes to scrape.
    POLL_INTERVAL  Seconds between scrapes (default 0.5).
"""
import os
import threading
import time
import uuid

import requests
from flask import Flask, jsonify, request, send_from_directory

NODES = [n.strip() for n in os.environ.get("NODES", "").split(",") if n.strip()]
POLL_INTERVAL = float(os.environ.get("POLL_INTERVAL", "0.5"))
HOSTNAME = os.environ.get("HOSTNAME")

app = Flask(__name__, static_folder="static")

_lock = threading.Lock()
_snapshots = {node: None for node in NODES}  # host:port -> last /state, or None

# name -> host:port, so the UI can refer to nodes by their short name.
_addr_by_name = {node.split(":")[0]: node for node in NODES}


def _node_name(hostport):
    return hostport.split(":")[0]


def scrape_nodes():
    """Background loop: pull /state from each node."""
    while True:
        for node in NODES:
            try:
                resp = requests.get(f"http://{node}/state", timeout=2)
                snapshot = resp.json() if resp.status_code == 200 else None
            except requests.RequestException:
                snapshot = None
            with _lock:
                _snapshots[node] = snapshot
        time.sleep(POLL_INTERVAL)


@app.route("/api/graph")
def graph():
    """Assemble nodes (with status + last message) and topology edges."""
    with _lock:
        snapshots = dict(_snapshots)

    nodes = []
    edges = []
    for hostport, snap in snapshots.items():
        name = _node_name(hostport)
        up = snap is not None
        nodes.append(
            {
                "id": name,
                "up": up,
                "role": snap.get("role") if up else None,
                "status": snap.get("status") if up else "down",
                "last_message": snap.get("last_message") if up else None,
                "decision": snap.get("decision") if up else None,
            }
        )
        if not up:
            continue
        for peer in snap.get("peers") or []:
            edges.append({"from": name, "to": peer})

    return jsonify({"nodes": nodes, "edges": edges, "ts": time.time()})


@app.route("/api/result", methods=["GET"])
def result():
    """Retrieve the altered message at the end"""
    with _lock:
        snapshots = dict(_snapshots)

    for hostport, snap in snapshots.items():
        name = _node_name(hostport)
        up = snap is not None
        if name == "node4":
            return snap.get("decision").get("chosen").get("text") if up else None


@app.route("/api/send", methods=["POST"])
def send():
    """Inject a message at the chosen origin node."""
    body = request.get_json(force=True)
    origin = body.get("origin")
    text = body.get("text", "")

    # print(body, flush=True)
    # print(origin, flush=True)
    # print(_addr_by_name, flush=True)

    addr = _addr_by_name.get(origin)
    if not addr:
        return jsonify({"ok": False, "error": f"unknown origin '{origin}'"}), 400

    msg = {
        "id": uuid.uuid4().hex,
        "origin": origin,
        "original": text,
        "text": text,
        "trail": [],
    }
    try:
        requests.post(f"http://{addr}/message", json=msg, timeout=2)
    except requests.RequestException as e:
        return jsonify({"ok": False, "error": str(e)}), 502
    return jsonify({"ok": True, "id": msg["id"]})


@app.route("/api/reset", methods=["POST"])
def reset():
    """Reset every node back to the waiting state."""
    for node in NODES:
        try:
            requests.post(f"http://{node}/reset", timeout=2)
        except requests.RequestException:
            pass
    return jsonify({"ok": True})


@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.route("/api/server")
def server():
    return jsonify({"server": HOSTNAME})


if __name__ == "__main__":
    threading.Thread(target=scrape_nodes, daemon=True).start()
    app.run(host="0.0.0.0", port=8080, threaded=True)
