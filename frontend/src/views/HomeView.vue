<template>
  <div class="container">
    <div class="toolbar">
      <button @click="goBack">Back</button>
      <button @click="goHome">Home</button>
      <button @click="refresh">Refresh</button>
    </div>

    <div class="breadcrumb">
      <button v-for="(segment, index) in breadcrumbs" :key="index" @click="navigateTo(segment.path)">
        {{ segment.name }}
      </button>
    </div>

    <div class="action-toolbar" v-if="!selectedMedia">
      <button @click="handleCreateFolder" class="toolbar-btn text-yellow">
        <span>➕📁</span> New Folder
      </button>
      
      <button @click="triggerFileInput" class="toolbar-btn text-blue">
        <span>📤</span> Upload File
      </button>
      <input type="file" ref="fileInput" @change="handleUploadFile" style="display: none;" accept="video/*,image/*" />
    </div>

    <div v-if="loading">Loading...</div>
    <div v-else>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Date modified</th>
            <th>Type</th>
            <th>Size</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.relativePath" @click="openItem(item)">
            <td>{{ getIcon(item) }} {{ item.name }}</td>
            <td>{{ formatDate(item.lastModified) }}</td>
            <td>{{ item.type }}</td>
            <td>{{ item.sizeFormatted || '' }}</td>
            <td>
              <button
                v-if="!item.isDirectory"
                class="download-btn"
                @click.stop="downloadFile(item)"
              >
                ⬇ Download
              </button>
              <span v-else>-</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="selectedMedia" class="viewer-overlay" @click.self="closeViewer">
      <div class="viewer">
        <div class="viewer-toolbar">
          <button v-if="mediaNavigationAvailable" @click="showPreviousMedia">← Prev</button>
          <button v-if="mediaNavigationAvailable" @click="showNextMedia">Next →</button>
          <button v-if="isImage(selectedMedia)" @click="zoomOut">−</button>
          <button v-if="isImage(selectedMedia)" @click="resetZoom">100%</button>
          <button v-if="isImage(selectedMedia)" @click="zoomIn">+</button>
          <button v-if="isVideo(selectedMedia)" @click="toggleMute">{{ isMuted ? 'Unmute' : 'Mute' }}</button>
          <button v-if="isVideo(selectedMedia)" @click="setPlaybackRate(1)">1x</button>
          <button v-if="isVideo(selectedMedia)" @click="setPlaybackRate(1.5)">1.5x</button>
          <button v-if="isVideo(selectedMedia)" @click="setPlaybackRate(2)">2x</button>
          <button @click="closeViewer">Close</button>
        </div>

        <video
          v-if="isVideo(selectedMedia)"
          ref="videoRef"
          controls
          playsinline
          preload="metadata"
          :src="mediaUrl(selectedMedia)"
        ></video>

        <img
          v-else-if="isImage(selectedMedia)"
          :src="mediaUrl(selectedMedia)"
          :style="{ transform: `scale(${imageScale})` }"
          @wheel.prevent="handleImageWheel"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import axios from 'axios';
import { useRoute, useRouter } from 'vue-router';

const route = useRoute();
const router = useRouter();

const items = ref([]);
const loading = ref(false);
const selectedMedia = ref(null);
const history = ref([]);
const videoRef = ref(null);
const imageScale = ref(1);
const isMuted = ref(false);
const fileInput = ref(null);

const currentPath = computed(() => {
  const value = route.query.path;
  return Array.isArray(value) ? value[0] || '' : value || '';
});

const mediaNavigationAvailable = computed(() => {
  return items.value.some(item => !item.isDirectory && (isVideo(item) || isImage(item)));
});

const breadcrumbs = computed(() => {
  const path = currentPath.value;
  const parts = path.split('/').filter(Boolean);
  const result = [];
  let current = '';
  for (const part of parts) {
    current = current ? `${current}/${part}` : part;
    result.push({ name: part, path: current });
  }
  return result;
});

async function loadItems() {
  loading.value = true;
  const path = currentPath.value;
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.get(`${base}/api/files`, { params: { path } });
    items.value = response.data;
  } catch (error) {
    console.error("Lỗi khi load danh sách file:", error);
    console.error("Message:", error.message);
    console.error("Code:", error.code);
    console.error("Status:", error.response?.status);
    console.error("Data:", error.response?.data);
    alert("Không thể kết nối Backend. Kiểm tra backend port 5000 hoặc chạy file BAT.");
  } finally {
    loading.value = false;
  }
}

function getIcon(item) {
  if (item.isDirectory) return '📁';
  if (isVideo(item)) return '🎬';
  if (isImage(item)) return '🖼️';
  return '📄';
}

function isVideo(item) {
  return ['.mp4', '.webm', '.mkv'].includes((item.extension || '').toLowerCase());
}

function isImage(item) {
  return ['.jpg', '.jpeg', '.png', '.webp'].includes((item.extension || '').toLowerCase());
}

function openItem(item) {
  if (item.isDirectory) {
    const nextPath = item.relativePath;
    history.value.push(currentPath.value);
    router.push({ query: { path: nextPath } });
    selectedMedia.value = null;
    imageScale.value = 1;
    return;
  }

  selectMedia(item);
}

function selectMedia(item) {
  selectedMedia.value = item;
  imageScale.value = 1;
  isMuted.value = false;
}

function showPreviousMedia() {
  const mediaItems = items.value.filter(item => !item.isDirectory && (isVideo(item) || isImage(item)));
  const currentIndex = mediaItems.findIndex(item => item.relativePath === selectedMedia.value?.relativePath);
  if (currentIndex <= 0) return;
  selectMedia(mediaItems[currentIndex - 1]);
}

function showNextMedia() {
  const mediaItems = items.value.filter(item => !item.isDirectory && (isVideo(item) || isImage(item)));
  const currentIndex = mediaItems.findIndex(item => item.relativePath === selectedMedia.value?.relativePath);
  if (currentIndex === -1 || currentIndex >= mediaItems.length - 1) return;
  selectMedia(mediaItems[currentIndex + 1]);
}

function closeViewer() {
  selectedMedia.value = null;
  imageScale.value = 1;
  isMuted.value = false;
}

function zoomIn() {
  imageScale.value = Math.min(4, Number((imageScale.value + 0.25).toFixed(2)));
}

function zoomOut() {
  imageScale.value = Math.max(1, Number((imageScale.value - 0.25).toFixed(2)));
}

function resetZoom() {
  imageScale.value = 1;
}

function handleImageWheel(event) {
  if (event.deltaY < 0) {
    zoomIn();
  } else {
    zoomOut();
  }
}

function toggleMute() {
  const video = videoRef.value;
  if (!video) return;
  video.muted = !video.muted;
  isMuted.value = video.muted;
}

function setPlaybackRate(rate) {
  const video = videoRef.value;
  if (!video) return;
  video.playbackRate = rate;
}

function navigateTo(path) {
  router.push({ query: { path: path || '' } });
}

function goBack() {
  if (history.value.length) {
    const previous = history.value.pop();
    router.push({ query: { path: previous || '' } });
  }
}

function goHome() {
  router.push({ query: { path: '' } });
}

function refresh() {
  loadItems();
}

async function handleCreateFolder() {
  const folderName = prompt("Nhập tên thư mục cần tạo:");
  if (!folderName) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await fetch(`${base}/api/media/create-folder`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        folderName: folderName,
        subPath: currentPath.value
      })
    });

    if (response.ok) {
      alert("Đã tạo thư mục thành công!");
      loadItems();
    } else {
      const err = await response.text();
      alert("Lỗi: " + err);
    }
  } catch (error) {
    alert("Không thể kết nối đến Server");
  }
}

function triggerFileInput() {
  fileInput.value.click();
}

async function handleUploadFile(event) {
  const files = event.target.files;
  if (files.length === 0) return;

  const formData = new FormData();
  formData.append("file", files[0]);
  formData.append("subPath", currentPath.value);

  try {
    console.log("Đang tải file lên...");
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await fetch(`${base}/api/media/upload`, {
      method: 'POST',
      body: formData
    });

    if (response.ok) {
      alert("Tải file lên thành công!");
      loadItems();
    } else {
      const errText = await response.text();
      alert(`Tải file thất bại (Lỗi ${response.status}): ${errText}`);
    }
  } catch (error) {
    console.error(error);
    alert("Có lỗi xảy ra trong quá trình upload: " + error.message);
  } finally {
    event.target.value = '';
  }
}

function mediaUrl(item) {
  const base = import.meta.env.VITE_API_BASE || '';
  const path = item.relativePath
    .split('/')
    .map(segment => encodeURIComponent(segment))
    .join('/');
  return isVideo(item) ? `${base}/api/media/video/${path}` : `${base}/api/media/image/${path}`;
}

function formatDate(value) {
  return new Date(value).toLocaleString();
}

function downloadFile(item) {
  if (!item || item.isDirectory) return;

  const base = import.meta.env.VITE_API_BASE || '';
  const path = item.relativePath
    .split('/')
    .map(segment => encodeURIComponent(segment))
    .join('/');

  const url = `${base}/api/media/download/${path}`;

  const link = document.createElement('a');
  link.href = url;
  link.download = item.name || 'download';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

watch(currentPath, () => {
  loadItems();
  selectedMedia.value = null;
  imageScale.value = 1;
  isMuted.value = false;
});

onMounted(() => {
  loadItems();
});
</script>

<style scoped>
.container {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 8px;
  box-sizing: border-box;
}

.toolbar,
.viewer-toolbar {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.action-toolbar {
  display: flex;
  gap: 15px;
  background-color: #202020;
  border: 1px solid #333;
  padding: 8px 15px;
  border-radius: 6px;
  margin-bottom: 15px;
}
.toolbar-btn {
  background: transparent;
  border: none;
  color: #fff;
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  border-radius: 4px;
  font-weight: 500;
}
.toolbar-btn:hover {
  background-color: #2d2d2d;
}
.text-yellow { color: #ffca28; }
.text-blue { color: #42a5f5; }

button {
  cursor: pointer;
  padding: 8px 10px;
  border: none;
  border-radius: 6px;
  background: #007bff;
  color: #fff;
  font-weight: 500;
}

button:hover {
  background: #0056b3;
}

.download-btn {
  padding: 6px 8px;
  border-radius: 4px;
  font-size: 13px;
  background: #28a745;
}
.download-btn:hover {
  background: #218838;
}

.viewer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 16px;
  z-index: 1000;
}

.viewer {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: #fafafa;
  max-width: 95vw;
  max-height: 95vh;
  overflow: auto;
}

video {
  width: 100%;
  max-height: 70vh;
  background: #000;
}

img {
  max-width: 100%;
  max-height: 70vh;
  object-fit: contain;
  transition: transform 0.15s ease;
  align-self: center;
}

@media (max-width: 768px) {
  .container {
    padding: 6px;
  }

  .toolbar,
  .viewer-toolbar {
    gap: 6px;
  }

  button {
    padding: 7px 8px;
    font-size: 14px;
  }

  table {
    font-size: 13px;
  }

  th, td {
    padding: 6px;
  }

  .viewer {
    padding: 8px;
  }
}
</style>
