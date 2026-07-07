<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';
import { Line } from 'vue-chartjs';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';
import * as signalR from '@microsoft/signalr';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend, Filler);

const router = useRouter();
const stats = ref(null); // Cho ổ cứng và uptime tĩnh ban đầu
const loading = ref(true);
const error = ref('');

// --- Chart Data State ---
const MAX_POINTS = 60; // Hiển thị 60 giây qua
const timeLabels = Array(MAX_POINTS).fill('');

let rawCpuData = Array(MAX_POINTS).fill(0);
let rawRamData = Array(MAX_POINTS).fill(0);
let rawDiskReadData = Array(MAX_POINTS).fill(0);
let rawDiskWriteData = Array(MAX_POINTS).fill(0);
let rawNetRecvData = Array(MAX_POINTS).fill(0);
let rawNetSendData = Array(MAX_POINTS).fill(0);

const cpuChartData = ref({
  labels: [...timeLabels],
  datasets: [{ label: 'CPU Usage (%)', data: [...rawCpuData], borderColor: '#38bdf8', backgroundColor: 'rgba(56, 189, 248, 0.1)', fill: true, pointRadius: 0, tension: 0.4, borderWidth: 2 }]
});

const ramChartData = ref({
  labels: [...timeLabels],
  datasets: [{ label: 'RAM Usage (GB)', data: [...rawRamData], borderColor: '#34d399', backgroundColor: 'rgba(52, 211, 153, 0.1)', fill: true, pointRadius: 0, tension: 0.4, borderWidth: 2 }]
});

const diskChartData = ref({
  labels: [...timeLabels],
  datasets: [
    { label: 'Read (KB/s)', data: [...rawDiskReadData], borderColor: '#c084fc', backgroundColor: 'transparent', pointRadius: 0, tension: 0.4, borderWidth: 2 },
    { label: 'Write (KB/s)', data: [...rawDiskWriteData], borderColor: '#f472b6', backgroundColor: 'transparent', pointRadius: 0, tension: 0.4, borderWidth: 2 }
  ]
});

const netChartData = ref({
  labels: [...timeLabels],
  datasets: [
    { label: 'Send (KB/s)', data: [...rawNetSendData], borderColor: '#fbbf24', backgroundColor: 'transparent', pointRadius: 0, tension: 0.4, borderWidth: 2 },
    { label: 'Receive (KB/s)', data: [...rawNetRecvData], borderColor: '#fcd34d', backgroundColor: 'transparent', pointRadius: 0, tension: 0.4, borderWidth: 2 }
  ]
});

// Current values for summary cards
const currentMetrics = ref({
  cpu: 0,
  ramUsed: 0,
  ramTotal: 16,
  diskRead: 0,
  diskWrite: 0,
  netReceive: 0,
  netSend: 0
});

// Common chart options
const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  animation: { duration: 0 },
  elements: {
    point: { radius: 0 },
    line: { tension: 0.4, borderWidth: 2 }
  },
  scales: {
    x: { display: false },
    y: { 
      beginAtZero: true,
      grid: { color: 'rgba(255, 255, 255, 0.1)' },
      ticks: { color: '#94a3b8' }
    }
  },
  plugins: {
    legend: { labels: { color: '#e2e8f0' } }
  }
};

// Specific options
const cpuOptions = { ...chartOptions, scales: { ...chartOptions.scales, y: { ...chartOptions.scales.y, max: 100 } } };

// SignalR Connection
let hubConnection = null;

async function fetchInitialStats() {
  loading.value = true;
  error.value = '';
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const res = await axios.get(`${base}/api/system/dashboard`, {
      headers: { Authorization: `Bearer ${localStorage.getItem('jwt_token')}` }
    });
    stats.value = res.data;
  } catch (err) {
    error.value = "Không thể lấy thông tin hệ thống.";
    console.error(err);
  } finally {
    loading.value = false;
  }
}

function setupSignalR() {
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token');
  
  hubConnection = new signalR.HubConnectionBuilder()
    .withUrl(`${base}/hubs/media?access_token=${token}`)
    .withAutomaticReconnect()
    .build();

  hubConnection.on("ReceiveSystemMetrics", (metrics) => {
    currentMetrics.value = metrics;
    
    // Update raw arrays
    timeLabels.push('');
    timeLabels.shift();

    rawCpuData.push(metrics.cpu);
    rawCpuData.shift();

    rawRamData.push(metrics.ramUsed);
    rawRamData.shift();

    rawDiskReadData.push(metrics.diskRead);
    rawDiskReadData.shift();
    rawDiskWriteData.push(metrics.diskWrite);
    rawDiskWriteData.shift();

    rawNetRecvData.push(metrics.netReceive);
    rawNetRecvData.shift();
    rawNetSendData.push(metrics.netSend);
    rawNetSendData.shift();
    
    // Trigger reactivity by completely reassigning the refs
    cpuChartData.value = { ...cpuChartData.value, labels: [...timeLabels], datasets: [{ ...cpuChartData.value.datasets[0], data: [...rawCpuData] }] };
    ramChartData.value = { ...ramChartData.value, labels: [...timeLabels], datasets: [{ ...ramChartData.value.datasets[0], data: [...rawRamData] }] };
    diskChartData.value = { ...diskChartData.value, labels: [...timeLabels], datasets: [
      { ...diskChartData.value.datasets[0], data: [...rawDiskReadData] },
      { ...diskChartData.value.datasets[1], data: [...rawDiskWriteData] }
    ]};
    netChartData.value = { ...netChartData.value, labels: [...timeLabels], datasets: [
      { ...netChartData.value.datasets[0], data: [...rawNetSendData] },
      { ...netChartData.value.datasets[1], data: [...rawNetRecvData] }
    ]};
  });

  hubConnection.start().catch(err => console.error("SignalR Connection Error: ", err));
}

onMounted(() => {
  fetchInitialStats();
  setupSignalR();
});

onUnmounted(() => {
  if (hubConnection) {
    hubConnection.stop();
  }
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
  <div class="min-h-screen bg-slate-950 text-slate-100 font-sans p-4 md:p-6">
    <div class="max-w-7xl mx-auto">
      
      <!-- Header -->
      <header class="flex items-center justify-between mb-6 bg-slate-900/50 p-4 md:p-6 rounded-2xl border border-slate-800">
        <div>
          <h1 class="text-2xl sm:text-3xl font-bold tracking-tight text-white flex items-center gap-3">
            <span>🎛️</span> Task Manager (NAS)
          </h1>
          <p class="text-slate-400 mt-1">Giám sát tài nguyên hệ thống theo thời gian thực</p>
        </div>
        <div class="flex items-center gap-3">
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

      <div v-else>
        
        <!-- Metrics Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          
          <!-- CPU Chart -->
          <div class="bg-slate-900 border border-slate-800 p-4 rounded-2xl shadow-lg flex flex-col">
            <div class="flex justify-between items-end mb-4">
              <div>
                <h3 class="text-slate-400 text-sm font-medium">CPU</h3>
                <p class="text-3xl font-bold text-sky-400 mt-1">{{ currentMetrics.cpu }}%</p>
              </div>
              <div class="text-6xl opacity-10">⚙️</div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="cpuChartData" :options="cpuOptions" />
            </div>
          </div>

          <!-- RAM Chart -->
          <div class="bg-slate-900 border border-slate-800 p-4 rounded-2xl shadow-lg flex flex-col">
            <div class="flex justify-between items-end mb-4">
              <div>
                <h3 class="text-slate-400 text-sm font-medium">Memory (RAM)</h3>
                <p class="text-3xl font-bold text-emerald-400 mt-1">{{ currentMetrics.ramUsed }} <span class="text-lg text-slate-400">/ {{ currentMetrics.ramTotal }} GB</span></p>
              </div>
              <div class="text-6xl opacity-10">🧠</div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="ramChartData" :options="{ ...chartOptions, scales: { ...chartOptions.scales, y: { ...chartOptions.scales.y, max: currentMetrics.ramTotal } } }" />
            </div>
          </div>

          <!-- Disk I/O Chart -->
          <div class="bg-slate-900 border border-slate-800 p-4 rounded-2xl shadow-lg flex flex-col">
            <div class="flex justify-between items-end mb-4">
              <div>
                <h3 class="text-slate-400 text-sm font-medium">Disk (Read/Write)</h3>
                <p class="text-xl font-bold text-fuchsia-400 mt-1">R: {{ currentMetrics.diskRead }} KB/s | W: {{ currentMetrics.diskWrite }} KB/s</p>
              </div>
              <div class="text-6xl opacity-10">💾</div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="diskChartData" :options="chartOptions" />
            </div>
          </div>

          <!-- Network I/O Chart -->
          <div class="bg-slate-900 border border-slate-800 p-4 rounded-2xl shadow-lg flex flex-col">
            <div class="flex justify-between items-end mb-4">
              <div>
                <h3 class="text-slate-400 text-sm font-medium">Network</h3>
                <p class="text-xl font-bold text-amber-400 mt-1">S: {{ currentMetrics.netSend }} KB/s | R: {{ currentMetrics.netReceive }} KB/s</p>
              </div>
              <div class="text-6xl opacity-10">🌐</div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="netChartData" :options="chartOptions" />
            </div>
          </div>

        </div>

        <!-- Drives Details -->
        <div>
          <h2 class="text-xl font-bold mb-4 flex items-center gap-2">💿 Dung lượng các ổ đĩa</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="drive in stats.drives" :key="drive.name" class="bg-slate-900 border border-slate-800 p-6 rounded-2xl shadow-lg relative overflow-hidden">
              <div class="flex justify-between items-center mb-4">
                <h3 class="text-xl font-bold text-white flex items-center gap-2">
                  <span>💽</span> Ổ đĩa {{ drive.name }}
                </h3>
                <span class="px-3 py-1 bg-slate-800 rounded-lg text-sm text-slate-300 font-medium">{{ drive.usedPercentage }}% đã dùng</span>
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
              
              <div class="mt-4 pt-4 border-t border-slate-800 text-center text-xs text-slate-500 font-medium">
                Tổng dung lượng: {{ formatBytes(drive.totalSize) }}
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
