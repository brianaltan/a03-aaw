FROM node:22-alpine
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install
COPY . .

ARG VITE_CATALOG_API=http://localhost:3001
ARG VITE_ORDER_API=http://localhost:3002
ARG VITE_NOTIFICATION_WS=ws://localhost:3003/ws
ENV VITE_CATALOG_API=$VITE_CATALOG_API
ENV VITE_ORDER_API=$VITE_ORDER_API
ENV VITE_NOTIFICATION_WS=$VITE_NOTIFICATION_WS

EXPOSE 5173
CMD ["pnpm", "dev", "--host", "0.0.0.0", "--port", "5173"]
