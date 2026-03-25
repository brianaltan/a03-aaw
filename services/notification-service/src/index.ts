import { Elysia } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/swagger";
import { startConsumer } from "./consumer";

// Track connected WebSocket clients
export const wsClients = new Set<any>();

const app = new Elysia()
  .use(cors())
  .use(
    swagger({
      documentation: {
        info: {
          title: "Notification Service API",
          version: "1.0.0",
          description:
            "API for viewing notifications in SuiLens. Also provides a WebSocket endpoint at /ws for real-time notification streaming.",
        },
        tags: [
          { name: "Notifications", description: "Notification endpoints" },
          { name: "Health", description: "Health check endpoints" },
        ],
      },
    })
  )
  .get("/health", () => ({ status: "ok", service: "notification-service" }), {
    detail: {
      tags: ["Health"],
      summary: "Health check",
      description: "Returns the health status of the notification service",
      responses: {
        200: { description: "Service is healthy" },
      },
    },
  })
  .ws("/ws", {
    open(ws) {
      wsClients.add(ws);
      console.log(`WebSocket client connected. Total: ${wsClients.size}`);
    },
    close(ws) {
      wsClients.delete(ws);
      console.log(`WebSocket client disconnected. Total: ${wsClients.size}`);
    },
    message(ws, message) {
      // No-op: server only broadcasts, clients don't send meaningful messages
    },
  })
  .listen(3003);

startConsumer().catch(console.error);

console.log(`Notification Service running on port ${app.server?.port}`);
