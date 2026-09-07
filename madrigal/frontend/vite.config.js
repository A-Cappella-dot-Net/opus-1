import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    // Match the port the app used under CRA (see useWebSocket.js's
    // dev-mode detection, which hardcodes ws://localhost:8080 when
    // running on port 3000).
    port: 3000,
  },
  build: {
    // madrigal/build.gradle.kts's `buildReact`/`copyReactBuild` tasks
    // expect the production bundle in frontend/build.
    outDir: 'build',
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/setupTests.js'],
    globals: true,
  },
});
