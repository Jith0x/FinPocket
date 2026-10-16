import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    watch: {
      ignored: ['**/finpocket_app/**', '**/finpocket_server/**', '**/.web_reference/**', '**/build/**'],
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
  },
})
