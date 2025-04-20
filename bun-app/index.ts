import { sql, SQL } from "bun";
import Elysia from "elysia";

const db = new SQL({
  url: import.meta.env.DATABASE_URL,
  onconnect: () => {
    console.log("Connected to database");
  },
  onclose: () => {
    console.log("Connection closed");
  },
});

new Elysia()
  .get("/users", async () => {
    const users = await sql`SELECT * FROM users`;
    return {
      users,
    };
  })
  .listen(3001);
