#!/bin/bash
set -e

echo "=== Deploying SuiLens to Kubernetes ==="

# 1. Create namespace
echo ">> Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# 2. Deploy databases
echo ">> Deploying databases..."
kubectl apply -f k8s/databases.yaml

# 3. Deploy RabbitMQ
echo ">> Deploying RabbitMQ..."
kubectl apply -f k8s/rabbitmq.yaml

# 4. Wait for infra to be ready
echo ">> Waiting for databases and RabbitMQ to be ready..."
kubectl -n suilens-2306152166 wait --for=condition=ready pod -l app=catalog-db --timeout=120s
kubectl -n suilens-2306152166 wait --for=condition=ready pod -l app=order-db --timeout=120s
kubectl -n suilens-2306152166 wait --for=condition=ready pod -l app=notification-db --timeout=120s
kubectl -n suilens-2306152166 wait --for=condition=ready pod -l app=rabbitmq --timeout=120s

# 5. Deploy application services
echo ">> Deploying catalog-service..."
kubectl apply -f k8s/catalog-service.yaml

echo ">> Deploying order-service..."
kubectl apply -f k8s/order-service.yaml

echo ">> Deploying notification-service..."
kubectl apply -f k8s/notification-service.yaml

echo ">> Deploying frontend..."
kubectl apply -f k8s/frontend.yaml

# 6. Wait for services
echo ">> Waiting for application pods to be ready..."
kubectl -n suilens-2306152166 wait --for=condition=ready pod -l app=catalog-service --timeout=120s
kubectl -n suilens-2306152166 wait --for=condition=ready pod -l app=order-service --timeout=120s
kubectl -n suilens-2306152166 wait --for=condition=ready pod -l app=notification-service --timeout=120s

echo ""
echo "=== Deployment complete! ==="
echo ""
kubectl get pods -n suilens-2306152166 -o wide
echo ""
kubectl get svc -n suilens-2306152166
echo ""
echo "Access the app via any node IP:"
echo "  Frontend:              http://<NODE_IP>:30173"
echo "  Catalog API + Swagger: http://<NODE_IP>:30001/swagger"
echo "  Order API + Swagger:   http://<NODE_IP>:30002/swagger"
echo "  Notification Swagger:  http://<NODE_IP>:30003/swagger"
