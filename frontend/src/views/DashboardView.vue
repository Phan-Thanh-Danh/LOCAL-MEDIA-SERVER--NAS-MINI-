<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';

const router = useRouter();
const stats = ref(null);
const loading = ref(true);
const error = ref('');

async function fetchStats() {
  loading.value = true;
  error.value = '';
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const res = await axios.get(`${base}/api/system/dashboard`);
    stats.value = res.data;
  } catch (err) {
    error.value = "Không thể lấy thông tin hệ thống.";
    console.error(err);
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  fetchStats();
});

function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function goBack() {
  router.push('/');
}
</script>

<template>
  <div class="min-h-screen bg-slate-950 text-slate-100 font-sans p-6">
    <div class="max-w-6xl mx-auto">
      
      <!-- Header -->
      <header class="flex items-center justify-between mb-8 bg-slate-900/50 p-6 rounded-2xl border border-slate-800">
        <div>
          <h1 class="text-2xl sm:text-3xl font-bold tracking-tight text-white flex items-center gap-3">
            <span>🎛️</span> Hệ thống Giám sát
          </h1>
          <p class="text-slate-400 mt-1">Dashboard thời gian thực cho NAS Mini</p>
        </div>
        <div class="flex items-center gap-3">
          <button @click="fetchStats" class="bg-indigo-500/10 hover:bg-indigo-500/20 text-indigo-400 border border-indigo-500/20 px-4 py-2 rounded-xl transition flex items-center gap-2">
            🔄 Làm mới
          </button>
          <button @click="goBack" class="bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-xl transition">
            🏠 Trở về
          </button>
        </div>
      </header>

      <div v-if="loading" class="flex justify-center p-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-500"></div>
      </div>

      <div v-else-if="error" class="bg-rose-500/10 border border-rose-500/20 text-rose-400 p-6 rounded-2xl text-center">
        {{ error }}
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        <!-- Summary Cards -->
        <div class="md:col-span-3 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 mb-2">
          <div class="bg-slate-900 border border-slate-800 p-6 rounded-2xl shadow-lg relative overflow-hidden group">
            <div class="absolute -right-4 -top-4 text-6xl opacity-5 group-hover:scale-110 transition-transform">⏱️</div>
            <h3 class="text-slate-400 text-sm font-medium">Thời gian hoạt động</h3>
            <p class="text-2xl font-bold text-white mt-2">{{ stats.uptime }}</p>
          </div>
          
          <div class="bg-slate-900 border border-slate-800 p-6 rounded-2xl shadow-lg relative overflow-hidden group">
            <div class="absolute -right-4 -top-4 text-6xl opacity-5 group-hover:scale-110 transition-transform">🧠</div>
            <h3 class="text-slate-400 text-sm font-medium">RAM Ứng dụng ngốn</h3>
            <p class="text-2xl font-bold text-emerald-400 mt-2">{{ formatBytes(stats.appRamUsage) }}</p>
          </div>
          
          <div class="bg-slate-900 border border-slate-800 p-6 rounded-2xl shadow-lg relative overflow-hidden group">
            <div class="absolute -right-4 -top-4 text-6xl opacity-5 group-hover:scale-110 transition-transform">💾</div>
            <h3 class="text-slate-400 text-sm font-medium">Số lượng Ổ đĩa</h3>
            <p class="text-2xl font-bold text-sky-400 mt-2">{{ stats.drives.length }} ổ</p>
          </div>

          <div class="bg-slate-900 border border-slate-800 p-6 rounded-2xl shadow-lg relative overflow-hidden group">
            <div class="absolute -right-4 -top-4 text-6xl opacity-5 group-hover:scale-110 transition-transform">✅</div>
            <h3 class="text-slate-400 text-sm font-medium">Trạng thái</h3>
            <p class="text-2xl font-bold text-emerald-400 mt-2 flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-emerald-500 animate-pulse"></span> Đang chạy
            </p>
          </div>
        </div>

        <!-- Drives Details -->
        <div class="md:col-span-3">
          <h2 class="text-xl font-bold mb-4 flex items-center gap-2">💿 Chi tiết Ổ cứng</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div v-for="drive in stats.drives" :key="drive.name" class="bg-slate-900 border border-slate-800 p-6 rounded-2xl shadow-lg">
              <div class="flex justify-between items-center mb-4">
                <h3 class="text-xl font-bold text-white flex items-center gap-2">
                  <span>💽</span> Ổ đĩa {{ drive.name }}
                </h3>
                <span class="px-3 py-1 bg-slate-800 rounded-lg text-sm text-slate-300">{{ drive.usedPercentage }}% đã dùng</span>
              </div>
              
              <!-- Progress Bar -->
              <div class="w-full h-4 bg-slate-800 rounded-full overflow-hidden mb-4">
                <div 
                  class="h-full rounded-full transition-all duration-1000"
                  :class="{
                    'bg-emerald-500': drive.usedPercentage < 70,
                    'bg-amber-500': drive.usedPercentage >= 70 && drive.usedPercentage < 90,
                    'bg-rose-500': drive.usedPercentage >= 90
                  }"
                  :style="{ width: drive.usedPercentage + '%' }"
                ></div>
              </div>

              <div class="flex justify-between text-sm">
                <div class="flex flex-col">
                  <span class="text-slate-400">Đã dùng</span>
                  <span class="text-slate-200 font-medium">{{ formatBytes(drive.usedSpace) }}</span>
                </div>
                <div class="flex flex-col text-right">
                  <span class="text-slate-400">Trống</span>
                  <span class="text-slate-200 font-medium">{{ formatBytes(drive.availableFreeSpace) }}</span>
                </div>
              </div>
              
              <div class="mt-4 pt-4 border-t border-slate-800 text-center text-xs text-slate-500">
                Tổng dung lượng: {{ formatBytes(drive.totalSize) }}
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
