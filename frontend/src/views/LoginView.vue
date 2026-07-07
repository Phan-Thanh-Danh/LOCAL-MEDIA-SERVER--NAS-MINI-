<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';

import { LockKeyhole } from 'lucide-vue-next';

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
  <div class="min-h-screen bg-[#F8FAFC] flex items-center justify-center p-4 font-['Inter',sans-serif]">
    <div class="max-w-md w-full bg-white rounded-3xl shadow-xl p-10 border border-[#E2E8F0] relative overflow-hidden">
      <!-- Decor -->
      <div class="absolute -top-32 -right-32 w-64 h-64 bg-blue-500/10 rounded-full blur-3xl"></div>
      <div class="absolute -bottom-32 -left-32 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl"></div>

      <div class="relative z-10">
        <div class="text-center mb-10">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-blue-50 text-[#2563EB] mb-5 shadow-sm border border-blue-100">
            <LockKeyhole class="w-8 h-8" />
          </div>
          <h2 class="text-3xl font-bold text-[#0F172A] tracking-tight">Đăng Nhập</h2>
          <p class="text-[#64748B] mt-2 text-[15px]">Truy cập Local Media Server</p>
        </div>

        <form @submit.prevent="handleLogin" class="space-y-5">
          <div>
            <label class="block text-[14px] font-semibold text-[#0F172A] mb-2">Tên Đăng Nhập</label>
            <input 
              v-model="username" 
              type="text" 
              class="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-xl px-4 py-3 text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#2563EB] focus:border-[#2563EB] transition-all placeholder:text-[#94A3B8] text-[15px]"
              placeholder="Nhập tài khoản"
              required
            >
          </div>

          <div>
            <label class="block text-[14px] font-semibold text-[#0F172A] mb-2">Mật Khẩu</label>
            <input 
              v-model="password" 
              type="password" 
              class="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-xl px-4 py-3 text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#2563EB] focus:border-[#2563EB] transition-all placeholder:text-[#94A3B8] text-[15px]"
              placeholder="••••••••"
              required
            >
          </div>

          <div v-if="error" class="bg-rose-50 text-rose-600 text-[14px] p-3 rounded-xl border border-rose-100 text-center font-medium">
            {{ error }}
          </div>

          <button 
            type="submit" 
            :disabled="loading"
            class="w-full bg-[#2563EB] hover:bg-blue-700 text-white font-semibold py-3.5 px-4 rounded-xl shadow-md shadow-blue-500/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 mt-2 text-[15px]"
          >
            <span v-if="!loading">Đăng Nhập Hệ Thống</span>
            <span v-else>Đang xử lý...</span>
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
