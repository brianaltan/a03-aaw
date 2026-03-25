import { Elysia, t } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/swagger";
import { db } from "./db";
import { lenses } from "./db/schema";
import { eq } from "drizzle-orm";

const app = new Elysia()
  .use(cors())
  .use(
    swagger({
      documentation: {
        info: {
          title: "Catalog Service API",
          version: "1.0.0",
          description: "API for managing lens catalog in SuiLens",
        },
        tags: [
          { name: "Lenses", description: "Lens catalog endpoints" },
          { name: "Health", description: "Health check endpoints" },
        ],
      },
    })
  )
  .get("/api/lenses", async () => {
    return db.select().from(lenses);
  }, {
    detail: {
      tags: ["Lenses"],
      summary: "Get all lenses",
      description: "Retrieve the full list of available lenses in the catalog",
      responses: {
        200: { description: "List of lenses returned successfully" },
      },
    },
  })
  .get("/api/lenses/:id", async ({ params }) => {
    const results = await db
      .select()
      .from(lenses)
      .where(eq(lenses.id, params.id));
    if (!results[0]) {
      return new Response(JSON.stringify({ error: "Lens not found" }), {
        status: 404,
      });
    }
    return results[0];
  }, {
    params: t.Object({
      id: t.String({ format: "uuid", description: "Lens UUID" }),
    }),
    detail: {
      tags: ["Lenses"],
      summary: "Get lens by ID",
      description: "Retrieve a single lens by its UUID",
      responses: {
        200: { description: "Lens returned successfully" },
        404: { description: "Lens not found" },
      },
    },
  })
  .get("/health", () => ({ status: "ok", service: "catalog-service" }), {
    detail: {
      tags: ["Health"],
      summary: "Health check",
      description: "Returns the health status of the catalog service",
      responses: {
        200: { description: "Service is healthy" },
      },
    },
  })
  .listen(3001);

console.log(`Catalog Service running on port ${app.server?.port}`);
