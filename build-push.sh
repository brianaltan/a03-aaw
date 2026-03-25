#!/bin/bash
set -e

# Docker Hub username — change if yours is different
DOCKER_USER="${DOCKER_USER:-brianaltan}"

echo "=== Building and pushing Docker images to $DOCKER_USER ==="

# Build and push catalog-service
echo ">> Building catalog-service..."
docker build -t "$DOCKER_USER/suilens-catalog-service:latest" ./services/catalog-service
docker push "$DOCKER_USER/suilens-catalog-service:latest"

# Build and push order-service
echo ">> Building order-service..."
docker build -t "$DOCKER_USER/suilens-order-service:latest" ./services/order-service
docker push "$DOCKER_USER/suilens-order-service:latest"

# Build and push notification-service
echo ">> Building notification-service..."
docker build -t "$DOCKER_USER/suilens-notification-service:latest" ./services/notification-service
docker push "$DOCKER_USER/suilens-notification-service:latest"

# Build and push frontend
# NODE_IP is the IP of any node in your K8s cluster (control plane or worker)
NODE_IP="${NODE_IP:-192.168.1.100}"
echo ">> Building frontend (NODE_IP=$NODE_IP)..."
docker build \
  --build-arg VITE_CATALOG_API="http://${NODE_IP}:30001" \
  --build-arg VITE_ORDER_API="http://${NODE_IP}:30002" \
  --build-arg VITE_NOTIFICATION_WS="ws://${NODE_IP}:30003/ws" \
  -t "$DOCKER_USER/suilens-frontend:latest" \
  ./frontend/suilens-frontend
docker push "$DOCKER_USER/suilens-frontend:latest"

echo "=== All images pushed to Docker Hub ==="
echo "Images:"
echo "  - $DOCKER_USER/suilens-catalog-service:latest"
echo "  - $DOCKER_USER/suilens-order-service:latest"
echo "  - $DOCKER_USER/suilens-notification-service:latest"
echo "  - $DOCKER_USER/suilens-frontend:latest"
