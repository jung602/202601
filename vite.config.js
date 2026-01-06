// vite.config.js
import glsl from "vite-plugin-glsl"
import { defineConfig } from "vite"
import tailwindcss from "@tailwindcss/vite"

export default defineConfig({
  plugins: [glsl(), tailwindcss()],
  build: {
    outDir: 'docs',
  },
  server: {
    host: true,
    proxy: {
      "/api": {
        target: "https://api.spotify.com",
        changeOrigin: true,
        secure: true,
        rewrite: (path) => path.replace(/^\/api/, ""),
      },
    },
  },
})
