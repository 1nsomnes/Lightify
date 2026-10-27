// Starts the Vite dev server at http://localhost:3001
import { createServer } from "vite";

const server = await createServer({ server: { port: Number(process.env.PORT ?? 3001), strictPort: true } });
await server.listen();
server.printUrls();
