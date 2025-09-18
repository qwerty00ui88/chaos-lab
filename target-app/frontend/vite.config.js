import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Vite dev 서버가 /api/... 요청을 각 서비스로 프록시
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api/user': {
        target: 'http://localhost:8081',
        changeOrigin: true,
      },
      '/api/catalog': {
        target: 'http://localhost:8082',
        changeOrigin: true,
      },
      '/api/order': {
        target: 'http://localhost:8083',
        changeOrigin: true,
      },
    },
  },
});
