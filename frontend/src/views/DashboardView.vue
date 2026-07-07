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

import { ArrowLeft, Activity, Cpu, MemoryStick, HardDrive, Network, Disc } from 'lucide-vue-next';

function goBack() {
  router.push('/');
}
</script>

<template>
  <div class="min-h-screen bg-[#F8FAFC] text-[#0F172A] font-['Inter',sans-serif] p-4 md:p-6">
    <div class="max-w-7xl mx-auto flex flex-col gap-6">
      
      <!-- Header -->
      <header class="flex items-center justify-between bg-white px-6 py-5 rounded-2xl border border-[#E2E8F0] shadow-sm">
        <div class="flex items-center gap-4">
          <div class="p-3 bg-blue-50 text-[#2563EB] rounded-xl">
            <Activity class="w-7 h-7" />
          </div>
          <div>
            <h1 class="text-2xl font-bold tracking-tight text-[#0F172A]">Task Manager (NAS)</h1>
            <p class="text-[#64748B] text-[14px] mt-1">Giám sát tài nguyên hệ thống theo thời gian thực</p>
          </div>
        </div>
        <button @click="goBack" class="flex items-center gap-2 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] px-4 py-2 rounded-xl transition-colors font-medium text-[14px]">
          <ArrowLeft class="w-4 h-4" />
          Trở về trang chủ
        </button>
      </header>

      <div v-if="loading" class="flex flex-col items-center justify-center p-12 bg-white rounded-2xl border border-[#E2E8F0] shadow-sm min-h-[400px]">
        <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-[#2563EB] mb-4"></div>
        <p class="text-[#64748B] font-medium text-[14px]">Đang tải dữ liệu...</p>
      </div>

      <div v-else-if="error" class="bg-rose-50 border border-rose-200 text-rose-600 p-6 rounded-2xl text-center font-medium shadow-sm">
        {{ error }}
      </div>

      <div v-else class="flex flex-col gap-6">
        
        <!-- Metrics Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          <!-- CPU Chart -->
          <div class="bg-white border border-[#E2E8F0] p-5 rounded-2xl shadow-sm flex flex-col hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-[#64748B] text-sm font-semibold uppercase tracking-wider">CPU</h3>
                <p class="text-3xl font-bold text-sky-500 mt-1">{{ currentMetrics.cpu }}%</p>
              </div>
              <div class="p-2 bg-sky-50 text-sky-500 rounded-lg">
                <Cpu class="w-6 h-6" />
              </div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="cpuChartData" :options="cpuOptions" />
            </div>
          </div>

          <!-- RAM Chart -->
          <div class="bg-white border border-[#E2E8F0] p-5 rounded-2xl shadow-sm flex flex-col hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-[#64748B] text-sm font-semibold uppercase tracking-wider">Memory (RAM)</h3>
                <p class="text-3xl font-bold text-emerald-500 mt-1">{{ currentMetrics.ramUsed }} <span class="text-lg text-[#64748B] font-medium">/ {{ currentMetrics.ramTotal }} GB</span></p>
              </div>
              <div class="p-2 bg-emerald-50 text-emerald-500 rounded-lg">
                <MemoryStick class="w-6 h-6" />
              </div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="ramChartData" :options="{ ...chartOptions, scales: { ...chartOptions.scales, y: { ...chartOptions.scales.y, max: currentMetrics.ramTotal } } }" />
            </div>
          </div>

          <!-- Disk I/O Chart -->
          <div class="bg-white border border-[#E2E8F0] p-5 rounded-2xl shadow-sm flex flex-col hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-[#64748B] text-sm font-semibold uppercase tracking-wider">Disk (Read/Write)</h3>
                <p class="text-xl font-bold text-fuchsia-500 mt-1">R: {{ currentMetrics.diskRead }} KB/s <span class="text-[#CBD5E1]">|</span> W: {{ currentMetrics.diskWrite }} KB/s</p>
              </div>
              <div class="p-2 bg-fuchsia-50 text-fuchsia-500 rounded-lg">
                <HardDrive class="w-6 h-6" />
              </div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="diskChartData" :options="chartOptions" />
            </div>
          </div>

          <!-- Network I/O Chart -->
          <div class="bg-white border border-[#E2E8F0] p-5 rounded-2xl shadow-sm flex flex-col hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-[#64748B] text-sm font-semibold uppercase tracking-wider">Network</h3>
                <p class="text-xl font-bold text-amber-500 mt-1">S: {{ currentMetrics.netSend }} KB/s <span class="text-[#CBD5E1]">|</span> R: {{ currentMetrics.netReceive }} KB/s</p>
              </div>
              <div class="p-2 bg-amber-50 text-amber-500 rounded-lg">
                <Network class="w-6 h-6" />
              </div>
            </div>
            <div class="flex-1 min-h-[150px]">
              <Line :data="netChartData" :options="chartOptions" />
            </div>
          </div>

        </div>

        <!-- Drives Details -->
        <div class="bg-white border border-[#E2E8F0] p-6 rounded-2xl shadow-sm">
          <h2 class="text-lg font-bold text-[#0F172A] mb-6 flex items-center gap-2">
            <Disc class="w-5 h-5 text-[#475569]" />
            Dung lượng các ổ đĩa
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="drive in stats.drives" :key="drive.name" class="border border-[#E2E8F0] p-5 rounded-xl bg-[#F8FAFC]">
              <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-bold text-[#0F172A] flex items-center gap-2">
                  <HardDrive class="w-5 h-5 text-[#64748B]" /> Ổ đĩa {{ drive.name }}
                </h3>
                <span class="px-2.5 py-1 bg-white border border-[#E2E8F0] rounded-md text-[13px] text-[#475569] font-semibold shadow-sm">
                  {{ drive.usedPercentage }}%
                </span>
              </div>
              
              <!-- Progress Bar -->
              <div class="w-full h-3 bg-[#E2E8F0] rounded-full overflow-hidden mb-4">
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

              <div class="flex justify-between text-[13px]">
                <div class="flex flex-col">
                  <span class="text-[#64748B] font-medium">Đã dùng</span>
                  <span class="text-[#0F172A] font-semibold">{{ formatBytes(drive.usedSpace) }}</span>
                </div>
                <div class="flex flex-col text-right">
                  <span class="text-[#64748B] font-medium">Trống</span>
                  <span class="text-[#0F172A] font-semibold">{{ formatBytes(drive.availableFreeSpace) }}</span>
                </div>
              </div>
              
              <div class="mt-4 pt-3 border-t border-[#E2E8F0] text-center text-[12px] text-[#64748B] font-medium">
                Tổng dung lượng: {{ formatBytes(drive.totalSize) }}
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
