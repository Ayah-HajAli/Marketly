import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Dev-time reverse proxy: the frontend (http://localhost:5173) calls /api/*
// as if it were same-origin, and Vite forwards each path to the right
// backend service.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api/auth": {
        target: process.env.VITE_AUTH_URL || "http://localhost:5101",
        changeOrigin: true,
      },
      "/api/products": {
        target: process.env.VITE_CATALOG_URL || "http://localhost:5102",
        changeOrigin: true,
      },
      "/api/categories": {
        target: process.env.VITE_CATALOG_URL || "http://localhost:5102",
        changeOrigin: true,
      },
      "/api/orders": {
        target: process.env.VITE_ORDERS_URL || "http://localhost:5103",
        changeOrigin: true,
      },
    },
  },
});