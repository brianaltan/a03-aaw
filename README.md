# SuiLens Microservices — Assignment A03

**Nama:** Brian Altan  
**NPM:** 2306152166

## Architecture

- **catalog-service** (port 3001) — Lens catalog CRUD
- **order-service** (port 3002) — Order placement, publishes events to RabbitMQ
- **notification-service** (port 3003) — Consumes RabbitMQ events, stores notifications, broadcasts via **WebSocket**
- **frontend** (port 5173) — Vue 3 + Vuetify, connects to notification-service WebSocket for real-time notifications

## OpenAPI Documentation

Swagger UI is available at:
- Catalog Service: `http://<host>:3001/swagger`  
- Order Service: `http://<host>:3002/swagger`  
- Notification Service: `http://<host>:3003/swagger`

## WebSocket

The notification-service exposes a WebSocket endpoint at `ws://<host>:3003/ws`.  
When an order is placed, the notification is broadcast in real-time to all connected frontend clients.

---

## Run Locally (Docker Compose)

```bash
docker compose up --build -d
```

### Migrate + Seed (from host)

```bash
(cd services/catalog-service && bun install --frozen-lockfile && bunx drizzle-kit push)
(cd services/order-service && bun install --frozen-lockfile && bunx drizzle-kit push)
(cd services/notification-service && bun install --frozen-lockfile && bunx drizzle-kit push)
(cd services/catalog-service && bun run src/db/seed.ts)
```

### Smoke Test

```bash
curl http://localhost:3001/api/lenses | jq
LENS_ID=$(curl -s http://localhost:3001/api/lenses | jq -r '.[0].id')

curl -X POST http://localhost:3002/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "Brian Altan",
    "customerEmail": "2306152166@gmail.com",
    "lensId": "'"$LENS_ID"'",
    "startDate": "2025-03-01",
    "endDate": "2025-03-05"
  }' | jq
```

### Stop

```bash
docker compose down
```

---

## Deploy to Kubernetes

### Prerequisites
- A K8s cluster with 1 control plane + 2 worker nodes (kubeadm, k3s, kind, etc.)
- `kubectl` configured to connect to the cluster
- Docker Hub account (images pushed there)

### 1. Build & Push Docker Images

Set your Docker Hub username and a node IP from your cluster:

```bash
docker login

export DOCKER_USER=
export NODE_IP=

./build-push.sh
```

### 2. Deploy to K8s

```bash
./deploy-k8s.sh
```

This deploys everything to namespace `suilens-2306152166`.

### 3. Run DB Migrations Inside K8s

```bash
# Get the catalog-service pod name
CATALOG_POD=$(kubectl -n suilens-2306152166 get pod -l app=catalog-service -o jsonpath='{.items[0].metadata.name}')
ORDER_POD=$(kubectl -n suilens-2306152166 get pod -l app=order-service -o jsonpath='{.items[0].metadata.name}')
NOTIF_POD=$(kubectl -n suilens-2306152166 get pod -l app=notification-service -o jsonpath='{.items[0].metadata.name}')

# Push schema
kubectl -n suilens-2306152166 exec "$CATALOG_POD" -- bunx drizzle-kit push
kubectl -n suilens-2306152166 exec "$ORDER_POD" -- bunx drizzle-kit push
kubectl -n suilens-2306152166 exec "$NOTIF_POD" -- bunx drizzle-kit push

# Seed data
kubectl -n suilens-2306152166 exec "$CATALOG_POD" -- bun run src/db/seed.ts
```

### 4. Access the App

| Service | URL |
|---|---|
| Frontend | `http://<NODE_IP>:30173` |
| Catalog Swagger | `http://<NODE_IP>:30001/swagger` |
| Order Swagger | `http://<NODE_IP>:30002/swagger` |
| Notification Swagger | `http://<NODE_IP>:30003/swagger` |

### 5. Smoke Test on K8s

```bash
curl http://<NODE_IP>:30001/api/lenses | jq
LENS_ID=$(curl -s http://<NODE_IP>:30001/api/lenses | jq -r '.[0].id')

curl -X POST http://<NODE_IP>:30002/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "Brian Altan",
    "customerEmail": "2306152166@gmail.com",
    "lensId": "'"$LENS_ID"'",
    "startDate": "2025-03-01",
    "endDate": "2025-03-05"
  }' | jq
```

### 6. Verify Pods

```bash
kubectl get pods -n suilens-2306152166 -o wide
```

---

## Docker Hub Images

- `brianaltan/suilens-catalog-service:latest`
- `brianaltan/suilens-order-service:latest`
- `brianaltan/suilens-notification-service:latest`
- `brianaltan/suilens-frontend:latest`
