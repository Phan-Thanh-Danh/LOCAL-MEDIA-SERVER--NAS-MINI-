<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';

const router = useRouter();
const username = ref('');
const password = ref('');
const error = ref('');
const loading = ref(false);

async function handleLogin() {
  if (!username.value || !password.value) {
    error.value = "Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.";
    return;
  }

  error.value = '';
  loading.value = true;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const res = await axios.post(`${base}/api/auth/login`, {
      username: username.value,
      password: password.value
    });

    // Save token
    localStorage.setItem('jwt_token', res.data.token);
    localStorage.setItem('user_role', res.data.role);

    // Redirect to home
    router.push('/');
  } catch (err) {
    error.value = err.response?.data || "Sai tài khoản hoặc mật khẩu.";
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="min-h-screen bg-slate-900 flex items-center justify-center p-4">
    <div class="max-w-md w-full bg-slate-800 rounded-2xl shadow-2xl p-8 border border-slate-700/50 relative overflow-hidden">
      <!-- Decor -->
      <div class="absolute -top-32 -right-32 w-64 h-64 bg-indigo-500/20 rounded-full blur-3xl"></div>
      <div class="absolute -bottom-32 -left-32 w-64 h-64 bg-rose-500/20 rounded-full blur-3xl"></div>

      <div class="relative z-10">
        <div class="text-center mb-8">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-indigo-500/10 text-indigo-400 mb-4 shadow-inner border border-indigo-500/20">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
          <h2 class="text-3xl font-bold text-white tracking-tight">Đăng Nhập</h2>
          <p class="text-slate-400 mt-2 text-sm">Vui lòng đăng nhập để truy cập Local Media Server</p>
        </div>

        <form @submit.prevent="handleLogin" class="space-y-6">
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Tên Đăng Nhập</label>
            <input 
              v-model="username" 
              type="text" 
              class="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all placeholder:text-slate-600"
              placeholder="Nhập tài khoản"
              required
            >
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Mật Khẩu</label>
            <input 
              v-model="password" 
              type="password" 
              class="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all placeholder:text-slate-600"
              placeholder="••••••••"
              required
            >
          </div>

          <div v-if="error" class="bg-rose-500/10 text-rose-400 text-sm p-3 rounded-lg border border-rose-500/20 text-center">
            {{ error }}
          </div>

          <button 
            type="submit" 
            :disabled="loading"
            class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 px-4 rounded-xl shadow-lg shadow-indigo-500/30 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            <span v-if="!loading">Đăng Nhập Hệ Thống</span>
            <span v-else>Đang xử lý...</span>
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
