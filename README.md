# Docker Networking — Message Propagation Visualizer

A scaffold for a Docker network of three containers arranged in a ring. You
inject a message at any node from the web visualizer and watch it propagate
hop-by-hop, with each node's status (**waiting → received → sent**) shown live.

## Architecture

```
            ┌──────────────────── meshnet (bridge) ────────────────────┐
            │                                                            │
            │     node1 ──▶ node2 ──▶ node3 ──┐   (ring: 1 peer each)     │
            │       ▲                          │                         │
            │       └──────────────────────────┘                         │
            │                                                            │
            │     visualizer scrapes every node's /state ◀───────────────┘
            └───────────────────────┬────────────────────────────────────┘
                                     │ :8080 published to host
                                     ▼
                            browser → controls + live graph
```

- **node** (`node/`) — a Flask service. On receiving a message at `/message`
  it goes `received`, dwells `PROCESS_DELAY` seconds (so the state is visible),
  forwards the message to its peer, then goes `sent`. It drops any message ID it
  has already handled, which stops the ring from looping forever.
- **visualizer** (`visualizer/`) — a Flask service that scrapes every node's
  `/state`, serves a graph at `/api/graph`, and exposes `/api/send` (inject a
  message at a chosen origin) and `/api/reset` (return all nodes to `waiting`).

All containers share a user-defined bridge network (`meshnet`) and resolve each
other by service name via Docker's embedded DNS.

## Run

```bash
docker compose up --build
```

Open <http://localhost:8080>, pick an origin node, type a message, and hit
**Send**. Watch the wave travel around the ring; hit **Reset** to clear it.

- **Gray** = waiting, **amber** = received, **green** = sent, **red** = down.

## How loops are prevented

Each message carries a unique ID. A node records IDs it has handled and ignores
repeats. When a message completes the ring and returns to a node that already
saw it, that node drops it instead of forwarding — so each node processes a
given message exactly once.

## Endpoints

| Service    | Method | Endpoint      | Description                              |
|------------|--------|---------------|------------------------------------------|
| node       | POST   | `/message`    | Receive a message and relay it onward    |
| node       | POST   | `/reset`      | Return to `waiting`, forget handled IDs  |
| node       | GET    | `/state`      | `{id, status, last_message, peers}`      |
| node       | GET    | `/health`     | Liveness probe                           |
| visualizer | POST   | `/api/send`   | `{origin, text}` — inject a message      |
| visualizer | POST   | `/api/reset`  | Reset every node                         |
| visualizer | GET    | `/api/graph`  | Merged `{nodes, edges}` for the ring     |
| visualizer | GET    | `/`           | The visualizer UI                        |

## Tuning

- `PROCESS_DELAY` (per node) — how long a node lingers in `received` before
  forwarding. Raise it to slow the wave down for demos.
- `POLL_INTERVAL` (visualizer) — how often it scrapes node state.

## Extending

- **More nodes** — add a service, point its `PEERS` at the next node in the
  ring, fix the previous node's `PEERS` to point at it, and add it to the
  visualizer's `NODES`.
- **Different topology** — give a node multiple peers in `PEERS` to broadcast
  (fan-out); the seen-ID dedup still prevents reprocessing.
