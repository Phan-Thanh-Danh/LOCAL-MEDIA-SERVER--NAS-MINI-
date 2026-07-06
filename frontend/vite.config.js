import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import basicSsl from '@vitejs/plugin-basic-ssl';

export default defineConfig({
  plugins: [vue(), basicSsl()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': {
        // Đã cập nhật trỏ về máy chủ NAS (192.168.2.10)
        target: 'http://192.168.2.10:5000',
        changeOrigin: true
      }
    }
  }
});
