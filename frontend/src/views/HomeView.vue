<template>
  <div class="min-h-screen bg-slate-950 text-slate-100 font-sans">
    <div class="max-w-7xl mx-auto px-4 py-6 flex flex-col gap-6">
      
      <!-- Header -->
      <header class="bg-slate-900/80 border border-slate-800 rounded-2xl shadow-xl p-4 sm:p-6 flex flex-col md:flex-row justify-between md:items-center gap-4">
        <div>
          <h1 class="text-xl sm:text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            Local Media Server
            <span class="px-2 py-1 bg-sky-500/20 text-sky-400 text-[10px] sm:text-xs font-semibold rounded-md uppercase tracking-wider">LAN Storage</span>
          </h1>
          <p class="text-slate-400 text-xs sm:text-sm mt-1">NAS Mini File Explorer</p>
        </div>
        <div class="flex w-full md:w-auto gap-2">
          <button @click="$router.push('/dashboard')" class="w-full md:w-auto bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2 rounded-xl font-medium transition flex items-center justify-center gap-2">
            <span>🎛️</span> Dashboard
          </button>
          <button @click="refresh" class="w-full md:w-auto bg-sky-600 hover:bg-sky-500 text-white px-4 py-2 rounded-xl font-medium transition flex items-center justify-center gap-2">
            <span>🔄</span> Refresh
          </button>
          <button @click="logout" class="w-full md:w-auto bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 px-4 py-2 rounded-xl font-medium transition flex items-center justify-center gap-2">
            <span>Đăng xuất</span>
          </button>
        </div>
      </header>

      <!-- Navigation & Actions -->
      <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
        <!-- Breadcrumb & Nav -->
        <div class="flex items-center gap-2 flex-wrap bg-slate-900 border border-slate-800 rounded-xl px-4 py-2">
          <button @click="goHome" class="text-slate-400 hover:text-white px-2 py-1 rounded transition">🏠 Home</button>
          <span class="text-slate-600">/</span>
          <button @click="goBack" class="text-slate-400 hover:text-white px-2 py-1 rounded transition" :disabled="!history.length" :class="{'opacity-50 cursor-not-allowed': !history.length}">🔙 Back</button>
          
          <template v-if="breadcrumbs.length > 0">
            <span class="text-slate-600 ml-2">|</span>
            <div class="flex items-center gap-1 ml-2 flex-wrap">
              <template v-for="(segment, index) in breadcrumbs" :key="index">
                <button @click="navigateTo(segment.path)" class="text-sky-400 hover:text-sky-300 font-medium transition">
                  {{ segment.name }}
                </button>
                <span v-if="index < breadcrumbs.length - 1" class="text-slate-600">/</span>
              </template>
            </div>
          </template>
        </div>

        <!-- Action Toolbar -->
        <div v-if="!selectedMedia" class="flex flex-wrap items-center gap-2 sm:gap-3 w-full lg:w-auto mt-2 lg:mt-0">
          <button v-if="currentPath" @click="handleLockFolder" class="flex-1 lg:flex-none justify-center bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 border border-rose-500/20 px-3 sm:px-4 py-2 rounded-xl text-sm sm:text-base font-medium transition flex items-center gap-2">
            <span>🔒</span> <span class="hidden sm:inline">Lock Folder</span><span class="sm:hidden">Lock</span>
          </button>

          <button @click="handleCreateFolder" class="flex-1 lg:flex-none justify-center bg-amber-500/10 hover:bg-amber-500/20 text-amber-500 border border-amber-500/20 px-3 sm:px-4 py-2 rounded-xl text-sm sm:text-base font-medium transition flex items-center gap-2">
            <span>➕📁</span> <span class="hidden sm:inline">New Folder</span><span class="sm:hidden">Folder</span>
          </button>
          
          <button @click="showUploadModal = true" class="flex-1 lg:flex-none justify-center bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 px-3 sm:px-4 py-2 rounded-xl text-sm sm:text-base font-medium transition flex items-center gap-2">
            <span>📤</span> <span class="hidden sm:inline">Upload File</span><span class="sm:hidden">Upload</span>
          </button>
        </div>
      </div>

      <!-- Filter/Search Toolbar -->
      <div v-if="!selectedMedia" class="bg-slate-900 border border-slate-800 rounded-2xl p-4 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-6 gap-3 items-center">
        <div class="xl:col-span-2 relative group flex-1 sm:flex-none">
          <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-slate-400">
            🔍
          </div>
          <input 
            v-model="searchQuery" 
            type="text" 
            class="w-full bg-slate-900/50 border border-slate-700 rounded-xl pl-10 pr-4 py-2.5 text-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all placeholder:text-slate-500"
            placeholder="Tìm kiếm file..."
          >
        </div>
          <select v-model="fileTypeFilter" class="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2 text-sm text-slate-200 outline-none focus:ring-2 focus:ring-sky-500 transition">
            <option value="all">All Types</option>
            <option value="folder">Folders</option>
            <option value="video">Videos</option>
            <option value="image">Images</option>
            <option value="other">Other Files</option>
          </select>
        
        <div>
          <select v-model="sortField" class="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2 text-sm text-slate-200 outline-none focus:ring-2 focus:ring-sky-500 transition">
            <option value="name">Sort by Name</option>
            <option value="lastModified">Sort by Date</option>
            <option value="size">Sort by Size</option>
            <option value="type">Sort by Type</option>
          </select>
        </div>

        <div class="flex gap-2">
          <button @click="toggleSortDirection" class="flex-1 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-xl px-3 py-2 text-sm text-slate-200 transition flex items-center justify-center gap-1">
            {{ sortDirection === 'asc' ? '🔼 Asc' : '🔽 Desc' }}
          </button>
          
          <button @click="viewMode = 'table'" :class="['px-3 py-1.5 rounded-lg text-sm font-medium transition', viewMode === 'table' ? 'bg-sky-500 text-white shadow-lg shadow-sky-500/30' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800']">
            📄 Table
          </button>
          <button @click="viewMode = 'card'" :class="['px-3 py-1.5 rounded-lg text-sm font-medium transition', viewMode === 'card' ? 'bg-sky-500 text-white shadow-lg shadow-sky-500/30' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800']">
            🗂️ Card
          </button>
          <button @click="viewMode = 'gallery'" :class="['px-3 py-1.5 rounded-lg text-sm font-medium transition', viewMode === 'gallery' ? 'bg-sky-500 text-white shadow-lg shadow-sky-500/30' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800']">
            🖼️ Gallery
          </button>
        </div>
        
        <div class="flex items-center justify-between gap-3">
          <span class="text-sm text-slate-400">{{ resultCount }} item(s)</span>
          <button v-if="searchQuery || fileTypeFilter !== 'all'" @click="clearFilters" class="text-xs text-rose-400 hover:text-rose-300 underline">Clear</button>
        </div>
      </div>

      <!-- Main Content -->
      <div v-if="loading" class="flex flex-col items-center justify-center py-20 bg-slate-900 border border-slate-800 rounded-2xl">
        <div class="animate-spin text-4xl mb-4">⏳</div>
        <p class="text-slate-400 font-medium animate-pulse">Loading files...</p>
      </div>
      
      <div v-else-if="resultCount === 0" class="flex flex-col items-center justify-center py-20 bg-slate-900 border border-slate-800 rounded-2xl">
        <div class="text-5xl mb-4 opacity-50">📂</div>
        <h3 class="text-xl font-medium text-slate-300 mb-2">No files found</h3>
        <p class="text-slate-500 text-sm mb-4">Try adjusting your search or filter criteria.</p>
        <button @click="clearFilters" class="bg-slate-800 hover:bg-slate-700 text-slate-300 px-4 py-2 rounded-lg transition">Clear Filters</button>
      </div>

      <div v-else>
        <!-- Table View -->
        <div v-if="viewMode === 'table'" class="overflow-hidden overflow-x-auto rounded-2xl border border-slate-800 bg-slate-900 shadow-lg">
          <table class="w-full text-sm text-left whitespace-nowrap">
            <thead class="bg-slate-800/80 text-slate-400 uppercase text-xs tracking-wider">
              <tr>
                <th class="px-4 py-3 sm:px-6 sm:py-4 font-medium">Name</th>
                <th class="px-4 py-3 sm:px-6 sm:py-4 font-medium hidden sm:table-cell">Date modified</th>
                <th class="px-4 py-3 sm:px-6 sm:py-4 font-medium hidden md:table-cell">Type</th>
                <th class="px-4 py-3 sm:px-6 sm:py-4 font-medium hidden sm:table-cell">Size</th>
                <th class="px-4 py-3 sm:px-6 sm:py-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-800/50">
              <tr v-for="item in filteredAndSortedItems" :key="item.relativePath" @click="openItem(item)" class="hover:bg-slate-800/60 transition cursor-pointer group">
                <td class="px-4 py-3 sm:px-6 sm:py-4 flex items-center gap-3">
                  <span class="text-xl sm:text-2xl">{{ getIcon(item) }}</span>
                  <span class="font-medium text-slate-200 truncate max-w-[150px] sm:max-w-[200px] md:max-w-md lg:max-w-lg">{{ item.name }}</span>
                </td>
                <td class="px-4 py-3 sm:px-6 sm:py-4 text-slate-400 hidden sm:table-cell">{{ formatDate(item.lastModified) }}</td>
                <td class="px-4 py-3 sm:px-6 sm:py-4 hidden md:table-cell">
                  <span class="px-2 py-1 rounded-md text-xs font-medium bg-slate-800 text-slate-300">{{ item.type }}</span>
                </td>
                <td class="px-4 py-3 sm:px-6 sm:py-4 text-slate-400 hidden sm:table-cell">{{ item.sizeFormatted || '-' }}</td>
                <td class="px-4 py-3 sm:px-6 sm:py-4 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button v-if="!item.isDirectory" @click.stop="downloadFile(item)" class="sm:opacity-0 sm:group-hover:opacity-100 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-500 border border-emerald-500/20 px-3 py-1.5 rounded-lg text-xs font-medium transition flex items-center justify-center gap-1 ml-auto">
                      ⬇ DL
                    </button>
                    <template v-if="item.isDirectory">
                      <button v-if="!item.isLocked" @click.stop="lockItem(item)" class="sm:opacity-0 sm:group-hover:opacity-100 bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 border border-rose-500/20 px-3 py-1.5 rounded-lg text-xs font-medium transition flex items-center justify-center gap-1">
                        🔒 Khóa
                      </button>
                      <button v-else @click.stop="unlockItem(item)" class="sm:opacity-0 sm:group-hover:opacity-100 bg-amber-500/10 hover:bg-amber-500/20 text-amber-500 border border-amber-500/20 px-3 py-1.5 rounded-lg text-xs font-medium transition flex items-center justify-center gap-1">
                        🔓 Mở Khóa
                      </button>
                    </template>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Card View -->
        <div v-if="viewMode === 'card'" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          <div v-for="item in filteredAndSortedItems" :key="item.relativePath" @click="openItem(item)" class="bg-slate-900 border border-slate-800 rounded-2xl hover:border-sky-500/50 hover:bg-slate-800/80 hover:shadow-lg hover:shadow-sky-900/20 transition cursor-pointer flex flex-col group relative overflow-hidden">
            
            <!-- Video Thumbnail Preview -->
            <div v-if="isVideo(item)" class="w-full aspect-video bg-slate-800/50 relative overflow-hidden flex items-center justify-center border-b border-slate-800">
              <img :src="getThumbnailUrl(item)" @error="$event.target.style.display='none'; $event.target.nextSibling.style.display='block'" class="w-full h-full object-cover transition-transform group-hover:scale-105" loading="lazy">
              <span class="text-4xl absolute transition-transform drop-shadow-lg group-hover:scale-110" style="display: none">🎬</span>
              <!-- Play Overlay -->
              <div class="absolute inset-0 bg-black/20 group-hover:bg-black/40 transition-colors flex items-center justify-center">
                <div class="w-12 h-12 rounded-full bg-sky-500/90 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all transform scale-90 group-hover:scale-100 shadow-xl backdrop-blur-md">
                  <svg class="w-6 h-6 ml-1" fill="currentColor" viewBox="0 0 20 20"><path d="M4 4l12 6-12 6z"/></svg>
                </div>
              </div>
              <!-- Badge Floating -->
              <div class="absolute top-3 right-3 bg-slate-900/80 backdrop-blur text-purple-400 text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-lg shadow-lg">Video</div>
            </div>

            <!-- Header for Non-Video -->
            <div v-else class="flex justify-between items-start p-5 pb-3">
              <div class="text-5xl drop-shadow-md group-hover:scale-110 transition-transform origin-bottom-left">{{ getIcon(item) }}</div>
              <div v-if="item.isDirectory" class="bg-amber-500/10 text-amber-500 text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-lg">Folder</div>
              <div v-else-if="isImage(item)" class="bg-sky-500/10 text-sky-400 text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-lg">Image</div>
              <div v-else class="bg-slate-700 text-slate-300 text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-lg">File</div>
            </div>
            
            <div class="p-5 pt-3 flex flex-col flex-1">
              <h3 class="font-semibold text-slate-100 text-base mb-1 truncate group-hover:text-sky-400 transition-colors" :title="item.name">{{ item.name }}</h3>
            
              <div class="flex flex-col gap-1 mt-auto pt-4 border-t border-slate-800/50">
                <div class="flex justify-between text-xs text-slate-400">
                  <span>Date:</span>
                  <span>{{ formatDate(item.lastModified).split(',')[0] }}</span>
                </div>
                <div class="flex justify-between text-xs text-slate-400">
                  <span>Size:</span>
                  <span>{{ item.sizeFormatted || '-' }}</span>
                </div>
              </div>
            </div>
            
            <button v-if="!item.isDirectory" @click.stop="downloadFile(item)" class="absolute top-4 right-4 opacity-0 group-hover:opacity-100 bg-emerald-500 hover:bg-emerald-400 text-slate-950 p-2 rounded-full shadow-lg transition translate-y-2 group-hover:translate-y-0" title="Download">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                <path d="M.5 9.9a.5.5 0 0 1 .5.5v2.5a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-2.5a.5.5 0 0 1 1 0v2.5a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2v-2.5a.5.5 0 0 1 .5-.5z"/>
                <path d="M7.646 11.854a.5.5 0 0 0 .708 0l3-3a.5.5 0 0 0-.708-.708L8.5 10.293V1.5a.5.5 0 0 0-1 0v8.793L5.354 8.146a.5.5 0 1 0-.708.708l3 3z"/>
              </svg>
            </button>
            <template v-if="item.isDirectory">
              <button v-if="!item.isLocked" @click.stop="lockItem(item)" class="absolute top-4 right-4 opacity-0 group-hover:opacity-100 bg-rose-500 hover:bg-rose-400 text-slate-950 p-2 rounded-full shadow-lg transition translate-y-2 group-hover:translate-y-0 text-xs flex items-center justify-center w-8 h-8" title="Khóa Thư Mục">
                🔒
              </button>
              <button v-else @click.stop="unlockItem(item)" class="absolute top-4 right-4 opacity-0 group-hover:opacity-100 bg-amber-500 hover:bg-amber-400 text-slate-950 p-2 rounded-full shadow-lg transition translate-y-2 group-hover:translate-y-0 text-xs flex items-center justify-center w-8 h-8" title="Mở Khóa">
                🔓
              </button>
            </template>
          </div>
        </div>

        <!-- Gallery View -->
        <div v-if="viewMode === 'gallery'" class="columns-2 sm:columns-3 md:columns-4 lg:columns-5 gap-4 space-y-4">
          <div v-for="item in filteredAndSortedItems" :key="item.relativePath" @click="openItem(item)" class="break-inside-avoid bg-slate-900 border border-slate-800 rounded-2xl hover:border-sky-500/50 hover:shadow-lg hover:shadow-sky-900/20 transition cursor-pointer group relative overflow-hidden">
            
            <!-- Image / Video Thumbnail -->
            <div v-if="isImage(item) || isVideo(item)" class="w-full relative overflow-hidden bg-slate-800/50">
              <img :src="isImage(item) ? getImageUrl(item) : getThumbnailUrl(item)" @error="$event.target.style.display='none'; $event.target.nextSibling.style.display='block'" class="w-full h-auto object-cover transition-transform duration-500 group-hover:scale-110" loading="lazy">
              <span class="text-4xl absolute inset-0 flex items-center justify-center transition-transform drop-shadow-lg group-hover:scale-110" style="display: none">{{ isVideo(item) ? '🎬' : '🖼️' }}</span>
              
              <div v-if="isVideo(item)" class="absolute top-2 right-2 bg-slate-900/80 backdrop-blur text-purple-400 text-[10px] font-bold uppercase tracking-wider px-2 py-1 rounded-md shadow-lg">Video</div>
            </div>

            <!-- Non-Media Fallback -->
            <div v-else class="w-full aspect-square flex flex-col items-center justify-center bg-slate-800/50 p-4">
              <div class="text-5xl drop-shadow-md group-hover:scale-110 transition-transform mb-2">{{ getIcon(item) }}</div>
              <div v-if="item.isDirectory" class="bg-amber-500/10 text-amber-500 text-[10px] font-bold uppercase tracking-wider px-2 py-1 rounded-md">Folder</div>
            </div>
            
            <div class="absolute bottom-0 left-0 right-0 p-3 bg-gradient-to-t from-slate-950 via-slate-900/80 to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
              <h3 class="font-medium text-white text-sm truncate" :title="item.name">{{ item.name }}</h3>
            </div>
          </div>
        </div>
      </div>

      <!-- Viewer Overlay -->
      <div v-if="selectedMedia" class="fixed inset-0 bg-slate-950/90 backdrop-blur-sm z-50 flex flex-col items-center justify-center p-4 md:p-8" @click.self="closeViewer">
        <div class="w-full max-w-6xl bg-slate-900 border border-slate-800 rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
          
          <!-- Viewer Toolbar -->
          <div class="bg-slate-950/50 p-4 border-b border-slate-800 flex flex-wrap items-center justify-between gap-4">
            <div class="flex items-center gap-3 truncate">
              <span class="text-2xl">{{ getIcon(selectedMedia) }}</span>
              <h2 class="text-white font-medium truncate max-w-[200px] sm:max-w-xs md:max-w-md">{{ selectedMedia.name }}</h2>
            </div>
            
            <div class="flex items-center gap-1 sm:gap-2 overflow-x-auto pb-2 scrollbar-hide flex-nowrap w-full md:w-auto">
              <template v-if="mediaNavigationAvailable">
                <button @click="showPreviousMedia" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">← Prev</button>
                <button @click="showNextMedia" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">Next →</button>
              </template>
              
              <div class="hidden sm:block w-px h-6 bg-slate-700 mx-1"></div>
              
              <template v-if="isImage(selectedMedia) || isVideo(selectedMedia)">
                <!-- Slideshow Button -->
                <button @click="toggleSlideshow" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-fuchsia-600 hover:bg-fuchsia-500 text-white rounded-lg text-xs sm:text-sm transition flex items-center gap-1 font-medium">
                  {{ slideshowInterval ? '⏸ Stop' : '▶ Slideshow' }}
                </button>
              </template>
              
              <template v-if="isImage(selectedMedia)">
                <button @click="zoomOut" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">−</button>
                <button @click="resetZoom" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">100%</button>
                <button @click="zoomIn" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">+</button>
              </template>
              
              <template v-if="isVideo(selectedMedia)">
                <button @click="toggleMute" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">{{ isMuted ? 'Unmute' : 'Mute' }}</button>
                <button @click="setPlaybackRate(1)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">1x</button>
                <button @click="setPlaybackRate(1.5)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">1.5x</button>
                <button @click="setPlaybackRate(2)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs sm:text-sm transition">2x</button>
              </template>
              
              <div class="hidden sm:block w-px h-6 bg-slate-700 mx-1"></div>
              
              <button @click="downloadFile(selectedMedia)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs sm:text-sm font-medium transition">DL</button>
              <button @click="closeViewer" class="whitespace-nowrap px-3 sm:px-4 py-1.5 bg-rose-600 hover:bg-rose-500 text-white rounded-lg text-xs sm:text-sm font-medium transition ml-1">Close</button>
            </div>
          </div>
          
          <!-- Media Content -->
          <div class="flex-1 overflow-auto bg-black/50 p-4 flex items-center justify-center min-h-[50vh]">
            <video
              v-if="isVideo(selectedMedia)"
              ref="videoRef"
              controls
              playsinline
              preload="metadata"
              :src="getMediaUrl(selectedMedia)"
              @timeupdate="onVideoTimeUpdate"
              @loadedmetadata="onVideoLoaded"
              class="max-w-full max-h-[75vh] rounded-lg shadow-2xl"
            ></video>

            <img
              v-else-if="isImage(selectedMedia)"
              :src="getImageUrl(selectedMedia)"
              :style="{ transform: `scale(${imageScale})` }"
              @wheel.prevent="handleImageWheel"
              class="max-w-full max-h-[75vh] object-contain transition-transform duration-200 rounded-lg shadow-2xl origin-center"
            />
          </div>
        </div>
      </div>

      <!-- Upload Modal -->
      <div v-if="showUploadModal" class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-[60] flex flex-col items-center justify-center p-4" 
           @click.self="showUploadModal = false"
           @dragover.prevent
           @dragenter.prevent
           @drop.prevent="isDragging = false">
        <div class="w-full max-w-md bg-slate-900 border border-slate-700 rounded-3xl shadow-2xl p-6 flex flex-col relative"
             @dragover.prevent="isDragging = true"
             @dragenter.prevent="isDragging = true"
             @dragleave.prevent="isDragging = false"
             @drop.prevent.stop="handleDrop">
             
          <button @click="showUploadModal = false" class="absolute top-4 right-4 text-slate-400 hover:text-white transition">
            ✖
          </button>
          
          <h2 class="text-xl font-bold text-white mb-6 text-center">Upload File</h2>
          
          <div :class="['border-2 border-dashed rounded-2xl p-10 flex flex-col items-center justify-center text-center transition-colors cursor-pointer', isDragging ? 'border-sky-500 bg-sky-500/10' : 'border-slate-600 hover:border-slate-500 hover:bg-slate-800/50']" @click="triggerFileInput">
            <span class="text-5xl mb-4 opacity-70" :class="{'animate-bounce': isDragging}">☁️</span>
            <p class="text-slate-300 font-medium mb-1">{{ isDragging ? 'Drop file to upload' : 'Click to browse or drag file here' }}</p>
            <p class="text-slate-500 text-sm">Supported files: Images, Videos</p>
          </div>
          
          <input type="file" ref="fileInput" @change="handleUploadFile" class="hidden" accept="video/*,image/*" />
          
          <div v-if="uploadProgress > 0" class="mt-6 w-full">
            <div class="flex justify-between text-xs text-slate-400 mb-1">
              <span>Uploading...</span>
              <span>{{ uploadProgress }}%</span>
            </div>
            <div class="w-full bg-slate-800 rounded-full h-2">
              <div class="bg-sky-500 h-2 rounded-full transition-all duration-300" :style="{ width: `${uploadProgress}%` }"></div>
            </div>
          </div>
        </div>
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
const showUploadModal = ref(false);
const isDragging = ref(false);
const uploadProgress = ref(0);
const unlockedPasswords = ref({});

// New UI State
const viewMode = ref('table'); // table | card
const searchQuery = ref('');
const fileTypeFilter = ref('all'); // all | folder | video | image | other
const sortField = ref('name'); // name | lastModified | size | type
const sortDirection = ref('asc'); // asc | desc

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

const filteredAndSortedItems = computed(() => {
  let result = [...items.value];

  // 1. Search
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(item => item.name.toLowerCase().includes(query));
  }

  // 2. Filter by type
  if (fileTypeFilter.value !== 'all') {
    result = result.filter(item => {
      if (fileTypeFilter.value === 'folder') return item.isDirectory;
      if (fileTypeFilter.value === 'video') return !item.isDirectory && isVideo(item);
      if (fileTypeFilter.value === 'image') return !item.isDirectory && isImage(item);
      if (fileTypeFilter.value === 'other') return !item.isDirectory && !isVideo(item) && !isImage(item);
      return true;
    });
  }

  // 3. Sort
  result.sort((a, b) => {
    // Folders always on top when sorting by name or type
    if ((sortField.value === 'name' || sortField.value === 'type') && a.isDirectory !== b.isDirectory) {
      return a.isDirectory ? -1 : 1;
    }

    let valA, valB;

    switch (sortField.value) {
      case 'name':
        valA = a.name.toLowerCase();
        valB = b.name.toLowerCase();
        break;
      case 'lastModified':
        valA = new Date(a.lastModified).getTime();
        valB = new Date(b.lastModified).getTime();
        break;
      case 'size':
        valA = a.size || 0;
        valB = b.size || 0;
        break;
      case 'type':
        valA = a.type.toLowerCase();
        valB = b.type.toLowerCase();
        break;
      default:
        valA = a.name.toLowerCase();
        valB = b.name.toLowerCase();
    }

    let comparison = 0;
    if (valA < valB) comparison = -1;
    if (valA > valB) comparison = 1;

    return sortDirection.value === 'asc' ? comparison : -comparison;
  });

  return result;
});

const resultCount = computed(() => filteredAndSortedItems.value.length);

function toggleViewMode() {
  viewMode.value = viewMode.value === 'table' ? 'card' : 'table';
}

function toggleSortDirection() {
  sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc';
}

function clearFilters() {
  searchQuery.value = '';
  fileTypeFilter.value = 'all';
}

async function loadItems() {
  loading.value = true;
  const path = currentPath.value;
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const password = unlockedPasswords.value[path] || '';
    const response = await axios.get(`${base}/api/files`, { params: { path, password } });
    items.value = response.data;
    
    // Auto-detect Gallery Mode
    if (items.value.length > 0) {
      const mediaCount = items.value.filter(i => isImage(i) || isVideo(i)).length;
      if (mediaCount / items.value.length >= 0.5) {
        viewMode.value = 'gallery';
      } else {
        viewMode.value = 'card';
      }
    }
  } catch (error) {
    if (error.response?.status === 401 && error.response?.data === 'LOCKED') {
      loading.value = false;
      const pwd = prompt("Thư mục này đã bị khóa. Vui lòng nhập mật khẩu:");
      if (pwd) {
        unlockedPasswords.value[path] = pwd;
        return loadItems();
      } else {
        goBack();
        return;
      }
    }
    console.error("Lỗi khi load danh sách file:", error);
    alert("Lỗi tải file. Kiểm tra backend hoặc mật khẩu.");
  } finally {
    loading.value = false;
  }
}

function getIcon(item) {
  if (item.isDirectory) return item.isLocked ? '🔒' : '📁';
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
    navigateTo(item.relativePath);
  } else {
    selectMedia(item);
  }
}

let lastSavedTime = 0;
let isSeeking = false;

async function checkHistoryAndPlay(path) {
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    const res = await axios.get(`${base}/api/history`, {
      params: { path },
      headers: { Authorization: `Bearer ${token}` }
    });
    const stoppedAt = res.data.stoppedAt;
    
    if (stoppedAt > 10) { // Only resume if watched more than 10 seconds
      if (confirm(`Bạn đang xem dở ở phút ${Math.floor(stoppedAt / 60)}:${Math.floor(stoppedAt % 60).toString().padStart(2, '0')}. Phát tiếp?`)) {
        isSeeking = true;
        // Wait for video ref
        setTimeout(() => {
          if (videoRef.value) {
            videoRef.value.currentTime = stoppedAt;
            videoRef.value.play().catch(e => console.log('Autoplay blocked', e));
          }
          isSeeking = false;
        }, 500);
      }
    }
  } catch (err) {
    console.error("Lỗi lấy lịch sử:", err);
  }
}

async function onVideoTimeUpdate(e) {
  if (isSeeking) return;
  const time = e.target.currentTime;
  
  // Save history every 5 seconds
  if (Math.abs(time - lastSavedTime) > 5) {
    lastSavedTime = time;
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    if (!selectedMedia.value) return;
    
    try {
      await axios.post(`${base}/api/history`, {
        path: selectedMedia.value.relativePath,
        stoppedAt: time
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
    } catch (err) {
      console.error("Lỗi lưu lịch sử:", err);
    }
  }
}

function onVideoLoaded(e) {
  if (!isSeeking && e.target) {
    e.target.play().catch(e => console.log('Autoplay blocked', e));
  }
}

function selectMedia(item) {
  selectedMedia.value = item;
  imageScale.value = 1;
  isMuted.value = false;
  if (isVideo(item)) {
    checkHistoryAndPlay(item.relativePath);
  }
}

let slideshowInterval = ref(null);

function toggleSlideshow() {
  if (slideshowInterval.value) {
    clearInterval(slideshowInterval.value);
    slideshowInterval.value = null;
  } else {
    slideshowInterval.value = setInterval(() => {
      showNextMedia();
    }, 4000); // 4 seconds per slide
  }
}

function showPreviousMedia() {
  const mediaItems = items.value.filter(item => !item.isDirectory && (isVideo(item) || isImage(item)));
  const currentIndex = mediaItems.findIndex(item => item.relativePath === selectedMedia.value?.relativePath);
  if (currentIndex <= 0) {
    if (slideshowInterval.value) toggleSlideshow();
    return;
  }
  selectMedia(mediaItems[currentIndex - 1]);
}

function showNextMedia() {
  const mediaItems = items.value.filter(item => !item.isDirectory && (isVideo(item) || isImage(item)));
  const currentIndex = mediaItems.findIndex(item => item.relativePath === selectedMedia.value?.relativePath);
  if (currentIndex === -1 || currentIndex >= mediaItems.length - 1) {
    if (slideshowInterval.value) toggleSlideshow();
    return;
  }
  selectMedia(mediaItems[currentIndex + 1]);
}

function closeViewer() {
  if (videoRef.value) {
    videoRef.value.pause();
  }
  if (slideshowInterval.value) toggleSlideshow();
  selectedMedia.value = null;
  imageScale.value = 1;
  isMuted.value = false;
  lastSavedTime = 0;
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

async function handleLockFolder() {
  const pwd = prompt(`Nhập mật khẩu để khóa thư mục hiện tại:`);
  if (!pwd) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.post(`${base}/api/media/lock`, {
      path: currentPath.value,
      password: pwd
    });
    alert(response.data.message || "Đã khóa thư mục thành công!");
    unlockedPasswords.value[currentPath.value] = pwd;
    loadItems();
  } catch (error) {
    alert("Lỗi khi khóa thư mục: " + (error.response?.data || error.message));
  }
}

async function lockItem(item) {
  const pwd = prompt(`Nhập mật khẩu để khóa thư mục "${item.name}":`);
  if (!pwd) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.post(`${base}/api/media/lock`, {
      path: item.relativePath,
      password: pwd
    });
    alert(response.data.message || "Đã khóa thư mục thành công!");
    unlockedPasswords.value[item.relativePath] = pwd;
    loadItems();
  } catch (error) {
    alert("Lỗi khi khóa thư mục: " + (error.response?.data || error.message));
  }
}

async function unlockItem(item) {
  const pwd = prompt(`Nhập mật khẩu để gỡ khóa thư mục "${item.name}":`);
  if (!pwd) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.post(`${base}/api/media/unlock`, {
      path: item.relativePath,
      password: pwd
    });
    alert(response.data.message || "Đã gỡ khóa thư mục thành công!");
    delete unlockedPasswords.value[item.relativePath];
    loadItems();
  } catch (error) {
    if (error.response?.status === 403) {
      alert("Mật khẩu không đúng!");
    } else {
      alert("Lỗi khi gỡ khóa thư mục: " + (error.response?.data || error.message));
    }
  }
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

function handleDrop(event) {
  isDragging.value = false;
  const files = event.dataTransfer.files;
  if (files.length > 0) {
    uploadFile(files[0]);
  }
}

async function handleUploadFile(event) {
  const files = event.target.files;
  if (files.length === 0) return;
  await uploadFile(files[0]);
}

async function uploadFile(file) {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("subPath", currentPath.value);

  uploadProgress.value = 1;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    
    await axios.post(`${base}/api/media/upload`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      onUploadProgress: (progressEvent) => {
        const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
        uploadProgress.value = percentCompleted;
      }
    });

    alert("Tải file lên thành công!");
    loadItems();
    showUploadModal.value = false;
  } catch (error) {
    console.error(error);
    alert("Có lỗi xảy ra trong quá trình upload: " + (error.response?.data || error.message));
  } finally {
    uploadProgress.value = 0;
    if (fileInput.value) {
      fileInput.value.value = '';
    }
  }
}

function getMediaUrl(item) {
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token') || '';
  const path = item.relativePath.split('/').map(segment => encodeURIComponent(segment)).join('/');
  return `${base}/api/media/video/${path}?access_token=${token}`;
}

function getImageUrl(item) {
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token') || '';
  const path = item.relativePath.split('/').map(segment => encodeURIComponent(segment)).join('/');
  return `${base}/api/media/image/${path}?access_token=${token}`;
}

function getThumbnailUrl(item) {
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token') || '';
  const path = item.relativePath.split('/').map(segment => encodeURIComponent(segment)).join('/');
  return `${base}/api/media/thumbnail/${path}?access_token=${token}`;
}

function logout() {
  localStorage.removeItem('jwt_token');
  localStorage.removeItem('user_role');
  router.push('/login');
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

<style>
body {
  background-color: #020617; /* bg-slate-950 */
}
</style>
