<template>
  <div class="min-h-screen bg-[#F8FAFC] text-[#0F172A] font-['Inter',sans-serif]">
    <div class="max-w-7xl mx-auto px-4 py-6 flex flex-col gap-6">
      
      <!-- Header -->
      <header class="bg-white/80 backdrop-blur-md border border-[#E2E8F0] rounded-2xl shadow-sm p-4 sm:p-6 flex flex-col md:flex-row justify-between md:items-center gap-4">
        <div>
          <h1 class="text-xl sm:text-2xl font-bold tracking-tight text-[#0F172A] flex items-center gap-2">
            Local Media Server
            <span class="px-2 py-1 bg-blue-50 text-[#2563EB] text-[10px] sm:text-xs font-semibold rounded-md uppercase tracking-wider">LAN Storage</span>
          </h1>
          <p class="text-[#64748B] text-xs sm:text-sm mt-1">NAS Mini File Explorer</p>
        </div>
        <div class="flex w-full md:w-auto gap-2">
          <button @click="$router.push('/dashboard')" class="w-full md:w-auto bg-[#F8FAFC] hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] hover:text-[#2563EB] px-4 py-2 rounded-xl font-medium transition-colors flex items-center justify-center gap-2 text-[14px]">
            <Activity class="w-4 h-4" /> Dashboard
          </button>
          <button v-if="isVaultPasswordSet" @click="changeVaultPassword" class="w-full md:w-auto bg-indigo-50 hover:bg-indigo-100 text-indigo-600 px-4 py-2 rounded-xl font-medium transition-colors flex items-center justify-center gap-2 text-[14px]">
            <Key class="w-4 h-4" /> Đổi MK
          </button>
          <button @click="toggleVault" :class="vaultUnlocked ? 'bg-indigo-500 hover:bg-indigo-600 text-white' : 'bg-slate-50 hover:bg-slate-100 text-slate-600'" class="w-full md:w-auto px-4 py-2 rounded-xl font-medium transition-colors flex items-center justify-center gap-2 text-[14px]">
            <component :is="vaultUnlocked ? Eye : EyeOff" class="w-4 h-4" /> Két Sắt
          </button>
          <button @click="refresh" class="w-full md:w-auto bg-blue-50 hover:bg-blue-100 text-[#2563EB] px-4 py-2 rounded-xl font-medium transition-colors flex items-center justify-center gap-2 text-[14px]">
            <RefreshCw class="w-4 h-4" /> Làm mới
          </button>
          <button @click="logout" class="w-full md:w-auto bg-rose-50 hover:bg-rose-100 text-rose-600 px-4 py-2 rounded-xl font-medium transition-colors flex items-center justify-center gap-2 text-[14px]">
            <LogOut class="w-4 h-4" /> Đăng xuất
          </button>
        </div>
      </header>

      <!-- Navigation & Actions -->
      <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
        <!-- Breadcrumb & Nav -->
        <div class="flex items-center gap-2 flex-wrap bg-white border border-[#E2E8F0] rounded-xl px-4 py-2 shadow-sm text-[14px]">
          <button @click="goHome" class="text-[#64748B] hover:text-[#2563EB] p-1.5 rounded transition-colors flex items-center gap-1" title="Trang chủ">
            <Home class="w-4 h-4" /> Home
          </button>
          <span class="text-[#CBD5E1]">/</span>
          <button @click="goBack" 
            @dragover.prevent="onItemDragOver($event, { isDirectory: true, relativePath: parentPath })"
            @dragenter.prevent="onItemDragEnter($event, { isDirectory: true, relativePath: parentPath })"
            @dragleave="onItemDragLeave($event, { isDirectory: true, relativePath: parentPath })"
            @drop="onItemDrop($event, { isDirectory: true, relativePath: parentPath, name: 'Thư mục cha' })"
            class="text-[#64748B] hover:text-[#2563EB] p-1.5 rounded transition-all flex items-center gap-1 border border-transparent" 
            :class="{'opacity-50 cursor-not-allowed': !history.length, 'bg-blue-50 border-blue-300 text-[#2563EB]': dragTarget === parentPath && currentPath}" 
            :disabled="!history.length" 
            title="Quay lại">
            <ArrowLeft class="w-4 h-4" /> Back
          </button>
          
          <template v-if="breadcrumbs.length > 0">
            <span class="text-[#CBD5E1] ml-2">|</span>
            <div class="flex items-center gap-1 ml-2 flex-wrap">
              <template v-for="(segment, index) in breadcrumbs" :key="index">
                <button @click="navigateTo(segment.path)" 
                  @dragover.prevent="onItemDragOver($event, { isDirectory: true, relativePath: segment.path })"
                  @dragenter.prevent="onItemDragEnter($event, { isDirectory: true, relativePath: segment.path })"
                  @dragleave="onItemDragLeave($event, { isDirectory: true, relativePath: segment.path })"
                  @drop="onItemDrop($event, { isDirectory: true, relativePath: segment.path, name: segment.name })"
                  class="text-[#2563EB] hover:text-blue-700 font-medium transition-all px-1.5 py-0.5 rounded border border-transparent"
                  :class="{'bg-blue-50 border-blue-300': dragTarget === segment.path}">
                  {{ segment.name }}
                </button>
                <span v-if="index < breadcrumbs.length - 1" class="text-[#CBD5E1]">/</span>
              </template>
            </div>
          </template>
        </div>

        <!-- Action Toolbar -->
        <div v-if="!selectedMedia" class="flex flex-wrap items-center gap-2 sm:gap-3 w-full lg:w-auto mt-2 lg:mt-0">
          <button v-if="currentPath" @click="handleLockFolder" class="flex-1 lg:flex-none justify-center bg-amber-50 hover:bg-amber-100 text-amber-600 px-3 sm:px-4 py-2 rounded-xl text-[14px] font-medium transition-colors flex items-center gap-2 border border-amber-200 shadow-sm">
            <Lock class="w-4 h-4" /> <span class="hidden sm:inline">Khóa Thư Mục</span><span class="sm:hidden">Khóa</span>
          </button>

          <button @click="handleCreateFolder" class="flex-1 lg:flex-none justify-center bg-white hover:bg-[#F1F5F9] text-[#2563EB] px-3 sm:px-4 py-2 rounded-xl text-[14px] font-medium transition-colors flex items-center gap-2 border border-[#E2E8F0] shadow-sm">
            <FolderPlus class="w-4 h-4" /> <span class="hidden sm:inline">Thư Mục Mới</span><span class="sm:hidden">Thêm</span>
          </button>
          
          <button @click="showUploadModal = true" class="flex-1 lg:flex-none justify-center bg-[#2563EB] hover:bg-blue-700 text-white px-3 sm:px-4 py-2 rounded-xl text-[14px] font-medium transition-colors flex items-center gap-2 shadow-sm">
            <UploadCloud class="w-4 h-4" /> <span class="hidden sm:inline">Tải Lên File</span><span class="sm:hidden">Tải Lên</span>
          </button>
        </div>
      </div>

      <!-- Filter/Search Toolbar -->
      <div v-if="!selectedMedia" class="bg-white border border-[#E2E8F0] rounded-2xl p-4 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-7 gap-3 items-center shadow-sm">
        <div class="xl:col-span-2 relative group flex-1 sm:flex-none">
          <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-[#64748B]">
            <Search class="w-4 h-4" />
          </div>
          <input 
            v-model="searchQuery" 
            type="text" 
            class="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-xl pl-10 pr-4 py-2.5 text-[14px] text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#2563EB] focus:border-[#2563EB] transition-all placeholder:text-[#94A3B8]"
            placeholder="Tìm kiếm file..."
          >
        </div>
          <select v-model="fileTypeFilter" class="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-xl px-3 py-2.5 text-[14px] text-[#475569] outline-none focus:ring-2 focus:ring-[#2563EB] transition">
            <option value="all">Tất cả loại file</option>
            <option value="folder">Thư mục</option>
            <option value="video">Video</option>
            <option value="image">Hình ảnh</option>
            <option value="other">File khác</option>
          </select>
        
        <div>
          <select v-model="sortField" class="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-xl px-3 py-2.5 text-[14px] text-[#475569] outline-none focus:ring-2 focus:ring-[#2563EB] transition">
            <option value="name">Sắp xếp theo Tên</option>
            <option value="lastModified">Sắp xếp theo Ngày</option>
            <option value="size">Sắp xếp theo Kích cỡ</option>
            <option value="type">Sắp xếp theo Loại</option>
          </select>
        </div>

        <div class="flex flex-wrap gap-2 xl:col-span-2">
          <button @click="toggleSortDirection" class="flex-1 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] rounded-xl px-3 py-2 text-[14px] text-[#475569] transition-colors flex items-center justify-center gap-1 font-medium">
            <component :is="sortDirection === 'asc' ? ArrowDownAz : ArrowUpZa" class="w-4 h-4" />
            {{ sortDirection === 'asc' ? 'Tăng dần' : 'Giảm dần' }}
          </button>
          
          <div class="flex bg-[#F8FAFC] border border-[#E2E8F0] p-1 rounded-xl gap-1">
            <button @click="viewMode = 'table'" :class="['px-3 py-1.5 rounded-lg text-[13px] font-medium transition-all flex items-center gap-1.5', viewMode === 'table' ? 'bg-white text-[#2563EB] shadow-sm' : 'text-[#64748B] hover:text-[#0F172A]']" title="Dạng Bảng">
              <List class="w-4 h-4" /> Bảng
            </button>
            <button @click="viewMode = 'card'" :class="['px-3 py-1.5 rounded-lg text-[13px] font-medium transition-all flex items-center gap-1.5', viewMode === 'card' ? 'bg-white text-[#2563EB] shadow-sm' : 'text-[#64748B] hover:text-[#0F172A]']" title="Dạng Thẻ">
              <LayoutGrid class="w-4 h-4" /> Thẻ
            </button>
            <button @click="viewMode = 'gallery'" :class="['px-3 py-1.5 rounded-lg text-[13px] font-medium transition-all flex items-center gap-1.5', viewMode === 'gallery' ? 'bg-white text-[#2563EB] shadow-sm' : 'text-[#64748B] hover:text-[#0F172A]']" title="Dạng Lưới">
              <ImageIcon class="w-4 h-4" /> Lưới
            </button>
          </div>
        </div>
        
        <div class="flex items-center justify-between gap-3 px-2">
          <span class="text-[13px] font-medium text-[#64748B]">{{ resultCount }} mục</span>
          <button v-if="searchQuery || fileTypeFilter !== 'all'" @click="clearFilters" class="text-[13px] text-rose-500 hover:text-rose-600 font-medium transition-colors">Xóa lọc</button>
        </div>
      </div>

      <!-- Main Content -->
      <div v-if="loading" class="flex flex-col items-center justify-center py-20 bg-white border border-[#E2E8F0] rounded-2xl shadow-sm min-h-[400px]">
        <Loader2 class="animate-spin text-[#2563EB] w-10 h-10 mb-4" />
        <p class="text-[#64748B] font-medium text-[14px]">Đang tải dữ liệu...</p>
      </div>
      
      <div v-else-if="resultCount === 0" class="flex flex-col items-center justify-center py-20 bg-white border border-[#E2E8F0] rounded-2xl shadow-sm min-h-[400px]">
        <FolderOpen class="w-12 h-12 text-[#94A3B8] mb-4 opacity-50" />
        <h3 class="text-xl font-medium text-[#0F172A] mb-2">Thư mục trống</h3>
        <p class="text-[#64748B] text-[14px] mb-4">Không tìm thấy file nào hoặc thư mục hiện chưa có dữ liệu.</p>
        <button @click="clearFilters" class="bg-[#F8FAFC] hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] font-medium px-4 py-2 rounded-lg transition-colors text-[14px]">Xóa bộ lọc</button>
      </div>

      <div v-else>
        <!-- Table View -->
        <div v-if="viewMode === 'table'" class="overflow-hidden overflow-x-auto rounded-2xl border border-[#E2E8F0] bg-white shadow-sm">
          <table class="w-full text-left whitespace-nowrap border-collapse">
            <thead class="bg-[#F8FAFC] border-b border-[#E2E8F0] text-[#64748B] uppercase text-[12px] tracking-wider font-semibold">
              <tr>
                <th class="px-6 py-4">Tên File / Thư Mục</th>
                <th class="px-6 py-4 hidden sm:table-cell">Ngày cập nhật</th>
                <th class="px-6 py-4 hidden md:table-cell">Loại</th>
                <th class="px-6 py-4 hidden sm:table-cell text-right">Kích cỡ</th>
                <th class="px-6 py-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[#E2E8F0]">
              <tr v-for="item in filteredAndSortedItems" :key="item.relativePath" 
                  @click="openItem(item)" 
                  draggable="true"
                  @dragstart="onItemDragStart($event, item)"
                  @dragover.prevent="onItemDragOver($event, item)"
                  @dragenter.prevent="onItemDragEnter($event, item)"
                  @dragleave="onItemDragLeave($event, item)"
                  @drop="onItemDrop($event, item)"
                  :class="['transition-colors cursor-pointer group', dragTarget === item ? 'bg-blue-50 border-blue-300' : 'hover:bg-[#F1F5F9]', {'opacity-50': draggedItem === item}]">
                <td class="px-6 py-3.5 flex items-center gap-3">
                  <component :is="getIconComponent(item)" class="w-5 h-5 flex-shrink-0" :class="getIconColor(item)" />
                  <span class="font-medium text-[#0F172A] text-[14px] truncate max-w-[150px] sm:max-w-[200px] md:max-w-md lg:max-w-lg">{{ item.name }}</span>
                  <Star v-if="item.isPinned" class="w-4 h-4 text-yellow-400 flex-shrink-0 ml-1" fill="currentColor" />
                </td>
                <td class="px-6 py-3.5 text-[#64748B] text-[13px] hidden sm:table-cell">{{ formatDate(item.lastModified) }}</td>
                <td class="px-6 py-3.5 hidden md:table-cell">
                  <span class="px-2.5 py-1 rounded-md text-[12px] font-medium bg-[#F1F5F9] text-[#475569] border border-[#E2E8F0]">{{ item.type }}</span>
                </td>
                <td class="px-6 py-3.5 text-[#64748B] text-[13px] hidden sm:table-cell text-right">{{ item.sizeFormatted || '-' }}</td>
                <td class="px-6 py-3.5 text-right">
                  <div class="flex items-center justify-end gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button v-if="!item.isPinned" @click.stop="pinItem(item)" class="p-1.5 text-slate-400 hover:bg-yellow-50 hover:text-yellow-500 rounded-md transition-colors" title="Ghim lên đầu">
                      <Star class="w-4 h-4" />
                    </button>
                    <button v-else @click.stop="unpinItem(item)" class="p-1.5 text-yellow-500 hover:bg-yellow-100 hover:text-yellow-600 rounded-md transition-colors" title="Bỏ ghim">
                      <Star class="w-4 h-4" fill="currentColor" />
                    </button>
                    <button v-if="!item.isDirectory" @click.stop="downloadFile(item)" class="p-1.5 text-[#2563EB] hover:bg-blue-100 hover:text-blue-700 rounded-md transition-colors" title="Tải về">
                      <Download class="w-4 h-4" />
                    </button>
                    <template v-if="item.isDirectory">
                      <button v-if="!item.isHidden" @click.stop="hideItem(item)" class="p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-700 rounded-md transition-colors" title="Ẩn thư mục">
                        <EyeOff class="w-4 h-4" />
                      </button>
                      <button v-else @click.stop="unhideItem(item)" class="p-1.5 text-indigo-500 hover:bg-indigo-100 hover:text-indigo-600 rounded-md transition-colors" title="Hiện thư mục">
                        <Eye class="w-4 h-4" />
                      </button>
                      <button v-if="!item.isLocked" @click.stop="lockItem(item)" class="p-1.5 text-amber-500 hover:bg-amber-100 hover:text-amber-600 rounded-md transition-colors" title="Khóa">
                        <Unlock class="w-4 h-4" />
                      </button>
                      <button v-else @click.stop="unlockItem(item)" class="p-1.5 text-rose-500 hover:bg-rose-100 hover:text-rose-600 rounded-md transition-colors" title="Mở khóa">
                        <Lock class="w-4 h-4" />
                      </button>
                    </template>
                    <button @click.stop="renameItem(item)" class="p-1.5 text-[#64748B] hover:bg-indigo-100 hover:text-indigo-600 rounded-md transition-colors" title="Đổi tên">
                      <Edit3 class="w-4 h-4" />
                    </button>
                    <button @click.stop="deleteItem(item)" class="p-1.5 text-[#64748B] hover:bg-rose-100 hover:text-rose-600 rounded-md transition-colors" title="Xóa">
                      <Trash2 class="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Card View -->
        <div v-if="viewMode === 'card'" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          <div v-for="item in filteredAndSortedItems" :key="item.relativePath" 
               @click="openItem(item)" 
               draggable="true"
               @dragstart="onItemDragStart($event, item)"
               @dragover.prevent="onItemDragOver($event, item)"
               @dragenter.prevent="onItemDragEnter($event, item)"
               @dragleave="onItemDragLeave($event, item)"
               @drop="onItemDrop($event, item)"
               :class="['bg-white border rounded-2xl hover:border-blue-300 hover:shadow-md transition-all cursor-pointer flex flex-col group relative overflow-hidden', dragTarget === item ? 'border-blue-500 shadow-lg ring-2 ring-blue-200' : 'border-[#E2E8F0]', {'opacity-50': draggedItem === item}]">
            
            <!-- Video Thumbnail Preview -->
            <div v-if="isVideo(item)" class="w-full aspect-video bg-[#F1F5F9] relative overflow-hidden flex items-center justify-center border-b border-[#E2E8F0]">
              <img :src="getThumbnailUrl(item)" @error="$event.target.style.display='none'; $event.target.nextSibling.style.display='block'" class="w-full h-full object-cover transition-transform group-hover:scale-105" loading="lazy">
              <Film class="w-10 h-10 text-[#64748B] absolute transition-transform drop-shadow-sm group-hover:scale-110" style="display: none" />
              <!-- Play Overlay -->
              <div class="absolute inset-0 bg-black/10 group-hover:bg-black/20 transition-colors flex items-center justify-center">
                <div class="w-12 h-12 rounded-full bg-white/90 text-[#2563EB] flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all transform scale-90 group-hover:scale-100 shadow-md backdrop-blur-sm">
                  <Play class="w-6 h-6 ml-1 fill-current" />
                </div>
              </div>
              <!-- Badge Floating -->
              <div class="absolute top-3 right-3 bg-white/90 backdrop-blur text-purple-600 text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-md shadow-sm border border-purple-100">Video</div>
            </div>

            <!-- Header for Non-Video -->
            <div v-else class="flex justify-between items-start p-5 pb-3">
              <div class="drop-shadow-sm group-hover:scale-110 transition-transform origin-bottom-left">
                <component :is="getIconComponent(item)" class="w-10 h-10" :class="getIconColor(item)" />
              </div>
              <div v-if="item.isDirectory" class="bg-amber-50 text-amber-600 border border-amber-200 text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-md">Thư mục</div>
              <div v-else-if="isImage(item)" class="bg-sky-50 text-sky-600 border border-sky-200 text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-md">Ảnh</div>
              <div v-else class="bg-[#F1F5F9] text-[#475569] border border-[#E2E8F0] text-[10px] font-bold uppercase tracking-wider px-2.5 py-1.5 rounded-md">File</div>
            </div>
            
            <div class="p-5 pt-3 flex flex-col flex-1">
              <h3 class="font-semibold text-[#0F172A] text-[14px] mb-1 truncate group-hover:text-[#2563EB] transition-colors" :title="item.name">{{ item.name }}</h3>
            
              <div class="flex flex-col gap-1 mt-auto pt-4 border-t border-[#E2E8F0]">
                <div class="flex justify-between text-[12px] text-[#64748B]">
                  <span>Ngày:</span>
                  <span class="font-medium text-[#475569]">{{ formatDate(item.lastModified).split(',')[0] }}</span>
                </div>
                <div class="flex justify-between text-[12px] text-[#64748B]">
                  <span>Dung lượng:</span>
                  <span class="font-medium text-[#475569]">{{ item.sizeFormatted || '-' }}</span>
                </div>
              </div>
            </div>
            
            <!-- Hover Actions -->
            <div :class="{'opacity-0 group-hover:opacity-100': !item.isPinned}" class="absolute top-4 left-4 transition-opacity z-10">
              <button v-if="!item.isPinned" @click.stop="pinItem(item)" class="bg-white hover:bg-yellow-50 text-slate-400 hover:text-yellow-500 p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Ghim">
                <Star class="w-4 h-4" />
              </button>
              <button v-else @click.stop="unpinItem(item)" class="bg-yellow-50 hover:bg-yellow-100 text-yellow-500 p-2 rounded-full shadow-md border border-yellow-200 flex items-center justify-center w-8 h-8" title="Bỏ ghim">
                <Star class="w-4 h-4" fill="currentColor" />
              </button>
            </div>

            <div v-if="item.isDirectory" class="absolute top-4 right-14 opacity-0 group-hover:opacity-100 transition-opacity translate-y-2 group-hover:translate-y-0">
              <button v-if="!item.isHidden" @click.stop="hideItem(item)" class="bg-white hover:bg-slate-100 text-slate-600 p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Ẩn">
                <EyeOff class="w-4 h-4" />
              </button>
              <button v-else @click.stop="unhideItem(item)" class="bg-white hover:bg-indigo-50 text-indigo-500 p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Bỏ Ẩn">
                <Eye class="w-4 h-4" />
              </button>
            </div>
            <div :class="item.isDirectory ? 'right-24' : 'right-14'" class="absolute top-4 opacity-0 group-hover:opacity-100 transition-opacity translate-y-2 group-hover:translate-y-0">
              <button @click.stop="renameItem(item)" class="bg-white hover:bg-indigo-50 text-indigo-500 p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Đổi tên">
                <Edit3 class="w-4 h-4" />
              </button>
            </div>
            <div :class="item.isDirectory ? 'right-[136px]' : 'right-24'" class="absolute top-4 opacity-0 group-hover:opacity-100 transition-opacity translate-y-2 group-hover:translate-y-0">
              <button @click.stop="deleteItem(item)" class="bg-white hover:bg-rose-50 text-rose-500 p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Xóa">
                <Trash2 class="w-4 h-4" />
              </button>
            </div>
            <div class="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity translate-y-2 group-hover:translate-y-0">
              <button v-if="!item.isDirectory" @click.stop="downloadFile(item)" class="bg-white hover:bg-blue-50 text-[#2563EB] p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Tải về">
                <Download class="w-4 h-4" />
              </button>
              <template v-if="item.isDirectory">
                <button v-if="!item.isLocked" @click.stop="lockItem(item)" class="bg-white hover:bg-amber-50 text-amber-500 p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Khóa">
                  <Unlock class="w-4 h-4" />
                </button>
                <button v-else @click.stop="unlockItem(item)" class="bg-white hover:bg-rose-50 text-rose-500 p-2 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-8 h-8" title="Mở khóa">
                  <Lock class="w-4 h-4" />
                </button>
              </template>
            </div>
          </div>
        </div>

        <!-- Gallery View -->
        <div v-if="viewMode === 'gallery'" class="columns-2 sm:columns-3 md:columns-4 lg:columns-5 gap-4 space-y-4">
          <div v-for="item in filteredAndSortedItems" :key="item.relativePath" 
               @click="openItem(item)" 
               draggable="true"
               @dragstart="onItemDragStart($event, item)"
               @dragover.prevent="onItemDragOver($event, item)"
               @dragenter.prevent="onItemDragEnter($event, item)"
               @dragleave="onItemDragLeave($event, item)"
               @drop="onItemDrop($event, item)"
               :class="['break-inside-avoid bg-white border rounded-2xl hover:border-blue-300 hover:shadow-md transition-all cursor-pointer group relative overflow-hidden', dragTarget === item ? 'border-blue-500 shadow-lg ring-2 ring-blue-200' : 'border-[#E2E8F0]', {'opacity-50': draggedItem === item}]">
            
            <!-- Image / Video Thumbnail -->
            <div v-if="isImage(item) || isVideo(item)" class="w-full relative overflow-hidden bg-[#F1F5F9]">
              <img :src="isImage(item) ? getImageUrl(item) : getThumbnailUrl(item)" @error="$event.target.style.display='none'; $event.target.nextSibling.style.display='block'" class="w-full h-auto object-cover transition-transform duration-500 group-hover:scale-105" loading="lazy">
              <div class="absolute inset-0 flex items-center justify-center" style="display: none">
                <component :is="isVideo(item) ? Film : ImageIcon" class="w-10 h-10 text-[#64748B] transition-transform drop-shadow-sm group-hover:scale-110" />
              </div>
              
              <div v-if="isVideo(item)" class="absolute top-2 right-2 bg-white/90 backdrop-blur text-purple-600 text-[10px] font-bold uppercase tracking-wider px-2 py-1 rounded-md shadow-sm border border-purple-100">Video</div>
            </div>

            <!-- Non-Media Fallback -->
            <div v-else class="w-full aspect-square flex flex-col items-center justify-center bg-[#F8FAFC] p-4">
              <div class="drop-shadow-sm group-hover:scale-110 transition-transform mb-2">
                <component :is="getIconComponent(item)" class="w-12 h-12" :class="getIconColor(item)" />
              </div>
              <div v-if="item.isDirectory" class="bg-amber-50 text-amber-600 border border-amber-200 text-[10px] font-bold uppercase tracking-wider px-2 py-1 rounded-md">Thư mục</div>
            </div>
            
            <div class="absolute bottom-0 left-0 right-0 p-3 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
              <h3 class="font-medium text-white text-[13px] truncate" :title="item.name">{{ item.name }}</h3>
            </div>
            
            <div :class="{'opacity-0 group-hover:opacity-100': !item.isPinned}" class="absolute top-2 left-2 transition-opacity z-10">
              <button v-if="!item.isPinned" @click.stop="pinItem(item)" class="bg-white hover:bg-yellow-50 text-slate-400 hover:text-yellow-500 p-1.5 rounded-full shadow-md border border-[#E2E8F0] flex items-center justify-center w-7 h-7" title="Ghim">
                <Star class="w-3.5 h-3.5" />
              </button>
              <button v-else @click.stop="unpinItem(item)" class="bg-yellow-50 hover:bg-yellow-100 text-yellow-500 p-1.5 rounded-full shadow-md border border-yellow-200 flex items-center justify-center w-7 h-7" title="Bỏ ghim">
                <Star class="w-3.5 h-3.5" fill="currentColor" />
              </button>
            </div>

            <button v-if="item.isDirectory && !item.isHidden" @click.stop="hideItem(item)" class="absolute top-2 right-10 opacity-0 group-hover:opacity-100 bg-white hover:bg-slate-100 text-slate-600 p-1.5 rounded-full shadow-md transition-opacity border border-[#E2E8F0] flex items-center justify-center w-7 h-7" title="Ẩn">
              <EyeOff class="w-3.5 h-3.5" />
            </button>
            <button v-else-if="item.isDirectory && item.isHidden" @click.stop="unhideItem(item)" class="absolute top-2 right-10 opacity-0 group-hover:opacity-100 bg-white hover:bg-indigo-50 text-indigo-500 p-1.5 rounded-full shadow-md transition-opacity border border-[#E2E8F0] flex items-center justify-center w-7 h-7" title="Hiện">
              <Eye class="w-3.5 h-3.5" />
            </button>
            <button @click.stop="renameItem(item)" :class="item.isDirectory ? 'right-[72px]' : 'right-10'" class="absolute top-2 opacity-0 group-hover:opacity-100 bg-white hover:bg-indigo-50 text-indigo-500 p-1.5 rounded-full shadow-md transition-opacity border border-[#E2E8F0] flex items-center justify-center w-7 h-7" title="Đổi tên">
              <Edit3 class="w-3.5 h-3.5" />
            </button>
            <button @click.stop="deleteItem(item)" :class="item.isDirectory ? 'right-[104px]' : 'right-[72px]'" class="absolute top-2 opacity-0 group-hover:opacity-100 bg-white hover:bg-rose-50 text-rose-500 p-1.5 rounded-full shadow-md transition-opacity border border-[#E2E8F0] flex items-center justify-center w-7 h-7" title="Xóa">
              <Trash2 class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      <!-- Viewer Overlay -->
      <div v-if="selectedMedia" class="fixed inset-0 bg-black/90 backdrop-blur-md z-50 flex flex-col items-center justify-center p-4 md:p-8" @click.self="closeViewer">
        <div class="w-full max-w-6xl bg-white border border-[#E2E8F0] rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
          
          <!-- Viewer Toolbar -->
          <div class="bg-[#F8FAFC] p-4 border-b border-[#E2E8F0] flex flex-wrap items-center justify-between gap-4">
            <div class="flex items-center gap-3 truncate">
              <component :is="getIconComponent(selectedMedia)" class="w-6 h-6" :class="getIconColor(selectedMedia)" />
              <h2 class="text-[#0F172A] font-semibold truncate max-w-[200px] sm:max-w-xs md:max-w-md">{{ selectedMedia.name }}</h2>
            </div>
            
            <div class="flex items-center gap-1 sm:gap-2 overflow-x-auto pb-2 scrollbar-hide flex-nowrap w-full md:w-auto">
              <template v-if="mediaNavigationAvailable">
                <button @click="showPreviousMedia" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] hover:text-[#2563EB] rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center gap-1"><ArrowLeft class="w-3.5 h-3.5" /> Trước</button>
                <button @click="showNextMedia" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] hover:text-[#2563EB] rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center gap-1">Sau <ArrowRight class="w-3.5 h-3.5" /></button>
              </template>
              
              <div class="hidden sm:block w-px h-6 bg-[#E2E8F0] mx-1"></div>
              
              <template v-if="isImage(selectedMedia) || isVideo(selectedMedia)">
                <!-- Slideshow Button -->
                <button @click="toggleSlideshow" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-purple-50 hover:bg-purple-100 text-purple-600 rounded-lg text-xs sm:text-[13px] transition-colors flex items-center gap-1 font-medium">
                  <component :is="slideshowInterval ? PauseCircle : PlayCircle" class="w-4 h-4" />
                  {{ slideshowInterval ? 'Dừng' : 'Trình chiếu' }}
                </button>
              </template>
              
              <template v-if="isImage(selectedMedia)">
                <button @click="zoomOut" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center"><ZoomOut class="w-4 h-4" /></button>
                <button @click="resetZoom" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] rounded-lg text-xs sm:text-[13px] font-medium transition-colors">100%</button>
                <button @click="zoomIn" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center"><ZoomIn class="w-4 h-4" /></button>
              </template>
              
              <template v-if="isVideo(selectedMedia)">
                <button @click="toggleMute" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center gap-1"><component :is="isMuted ? VolumeX : Volume2" class="w-4 h-4" /> {{ isMuted ? 'Bật âm' : 'Tắt âm' }}</button>
                <button @click="setPlaybackRate(1)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] rounded-lg text-xs sm:text-[13px] font-medium transition-colors">1x</button>
                <button @click="setPlaybackRate(1.5)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] rounded-lg text-xs sm:text-[13px] font-medium transition-colors">1.5x</button>
                <button @click="setPlaybackRate(2)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-white hover:bg-[#F1F5F9] border border-[#E2E8F0] text-[#475569] rounded-lg text-xs sm:text-[13px] font-medium transition-colors">2x</button>
              </template>
              
              <div class="hidden sm:block w-px h-6 bg-[#E2E8F0] mx-1"></div>
              
              <button @click="renameItem(selectedMedia)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-600 rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center gap-1"><Edit3 class="w-4 h-4" /> Đổi tên</button>
              <button @click="deleteItem(selectedMedia)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-600 rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center gap-1"><Trash2 class="w-4 h-4" /> Xóa</button>
              <button @click="downloadFile(selectedMedia)" class="whitespace-nowrap px-2 sm:px-3 py-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-600 rounded-lg text-xs sm:text-[13px] font-medium transition-colors flex items-center gap-1"><Download class="w-4 h-4" /> Tải về</button>
              <button @click="closeViewer" class="whitespace-nowrap px-3 sm:px-4 py-1.5 bg-[#0F172A] hover:bg-[#1E293B] text-white rounded-lg text-xs sm:text-[13px] font-medium transition-colors ml-1 flex items-center gap-1"><X class="w-4 h-4" /> Đóng</button>
            </div>
          </div>
          
          <!-- Media Content -->
          <div class="flex-1 overflow-auto bg-[#F1F5F9] p-4 flex items-center justify-center min-h-[50vh]">
            <video
              v-if="isVideo(selectedMedia)"
              ref="videoRef"
              controls
              playsinline
              preload="metadata"
              :src="getMediaUrl(selectedMedia)"
              @timeupdate="onVideoTimeUpdate"
              @loadedmetadata="onVideoLoaded"
              class="max-w-full max-h-[75vh] rounded-lg shadow-md"
            ></video>

            <img
              v-else-if="isImage(selectedMedia)"
              :src="getImageUrl(selectedMedia)"
              :style="{ transform: `scale(${imageScale})` }"
              @wheel.prevent="handleImageWheel"
              class="max-w-full max-h-[75vh] object-contain transition-transform duration-200 rounded-lg shadow-md origin-center"
            />
            
            <iframe
              v-else-if="isPdf(selectedMedia) || isCodeOrText(selectedMedia)"
              :src="getGenericFileUrl(selectedMedia)"
              class="w-full h-[75vh] rounded-lg shadow-md bg-white border border-[#E2E8F0]"
            ></iframe>
            
            <div v-else class="text-center p-8 bg-white border border-[#E2E8F0] rounded-2xl shadow-sm max-w-md">
              <div class="flex justify-center mb-4">
                <component :is="getIconComponent(selectedMedia)" class="w-16 h-16" :class="getIconColor(selectedMedia)" />
              </div>
              <h3 class="text-xl font-semibold text-[#0F172A] mb-2">{{ selectedMedia.name }}</h3>
              <p class="text-[#64748B] mb-6 text-[14px]">Định dạng file này không hỗ trợ xem trực tiếp trên trình duyệt.</p>
              <button @click="downloadFile(selectedMedia)" class="bg-[#2563EB] hover:bg-blue-700 text-white px-6 py-2 rounded-xl font-medium transition-colors flex items-center justify-center mx-auto gap-2">
                <Download class="w-4 h-4" /> Tải xuống file
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Upload Modal -->
      <div v-if="showUploadModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[60] flex flex-col items-center justify-center p-4" 
           @click.self="showUploadModal = false"
           @dragover.prevent
           @dragenter.prevent
           @drop.prevent="isDragging = false">
        <div class="w-full max-w-md bg-white border border-[#E2E8F0] rounded-2xl shadow-xl p-6 flex flex-col relative"
             @dragover.prevent="isDragging = true"
             @dragenter.prevent="isDragging = true"
             @dragleave.prevent="isDragging = false"
             @drop.prevent.stop="handleDrop">
             
          <button @click="showUploadModal = false" class="absolute top-4 right-4 text-[#94A3B8] hover:text-[#0F172A] transition-colors p-1">
            <X class="w-5 h-5" />
          </button>
          
          <h2 class="text-xl font-bold text-[#0F172A] mb-6 text-center">Tải lên File</h2>
          
          <div :class="['border-2 border-dashed rounded-xl p-10 flex flex-col items-center justify-center text-center transition-colors cursor-pointer', isDragging ? 'border-[#2563EB] bg-blue-50' : 'border-[#CBD5E1] hover:border-[#94A3B8] hover:bg-[#F8FAFC]']" @click="triggerFileInput">
            <UploadCloud class="w-12 h-12 mb-4 text-[#64748B]" :class="{'animate-bounce text-[#2563EB]': isDragging}" />
            <p class="text-[#0F172A] font-semibold mb-1">{{ isDragging ? 'Thả file vào đây' : 'Nhấp để chọn hoặc kéo thả file vào đây' }}</p>
            <p class="text-[#64748B] text-[13px]">Hỗ trợ: Hình ảnh, Video, Tài liệu</p>
          </div>
          
          <input type="file" ref="fileInput" @change="handleUploadFile" class="hidden" accept="video/*,image/*" />
          
          <div v-if="uploadProgress > 0" class="mt-6 w-full">
            <div class="flex justify-between text-[13px] text-[#475569] font-medium mb-1.5">
              <span>Đang tải lên...</span>
              <span>{{ uploadProgress }}%</span>
            </div>
            <div class="w-full bg-[#E2E8F0] rounded-full h-2 overflow-hidden">
              <div class="bg-[#2563EB] h-2 rounded-full transition-all duration-300" :style="{ width: `${uploadProgress}%` }"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Custom Dialog Overlay -->
      <div v-if="dialogState.isOpen" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[70] flex flex-col items-center justify-center p-4" @click.self="cancelDialog">
        <div class="w-full max-w-sm bg-white border border-[#E2E8F0] rounded-2xl shadow-xl overflow-hidden flex flex-col transform transition-all animate-in fade-in zoom-in-95 duration-200">
          <div class="p-6">
            <div class="flex items-center gap-3 mb-4">
              <div :class="[
                'p-2 rounded-full',
                dialogState.type === 'alert' ? 'bg-amber-50 text-amber-500' : '',
                dialogState.type === 'confirm' ? 'bg-blue-50 text-[#2563EB]' : '',
                dialogState.type === 'prompt' ? 'bg-purple-50 text-purple-600' : ''
              ]">
                <AlertCircle v-if="dialogState.type === 'alert'" class="w-6 h-6" />
                <HelpCircle v-else-if="dialogState.type === 'confirm'" class="w-6 h-6" />
                <Edit3 v-else-if="dialogState.type === 'prompt'" class="w-6 h-6" />
              </div>
              <h3 class="text-lg font-bold text-[#0F172A]">{{ dialogState.title || (dialogState.type === 'alert' ? 'Thông báo' : dialogState.type === 'confirm' ? 'Xác nhận' : 'Nhập liệu') }}</h3>
            </div>
            
            <p class="text-[#475569] text-[14px] mb-5 leading-relaxed">{{ dialogState.message }}</p>
            
            <div v-if="dialogState.type === 'prompt'" class="mb-2">
              <input 
                type="text" 
                v-model="dialogState.inputValue" 
                @keyup.enter="confirmDialog"
                ref="dialogInput"
                class="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-[14px] text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#2563EB] focus:border-[#2563EB] transition-all"
                placeholder="Nhập thông tin..."
              >
            </div>
          </div>
          
          <div class="bg-[#F8FAFC] px-6 py-4 border-t border-[#E2E8F0] flex justify-end gap-3">
            <button v-if="dialogState.type !== 'alert'" @click="cancelDialog" class="px-4 py-2 text-[14px] font-medium text-[#64748B] hover:text-[#0F172A] hover:bg-[#E2E8F0] rounded-lg transition-colors">
              Hủy
            </button>
            <button @click="confirmDialog" class="px-4 py-2 text-[14px] font-medium text-white bg-[#2563EB] hover:bg-blue-700 rounded-lg transition-colors shadow-sm">
              Đồng ý
            </button>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import axios from 'axios';
import { useRoute, useRouter } from 'vue-router';
import { 
  Activity, RefreshCw, LogOut, Home, ArrowLeft, Lock, Unlock, FolderPlus, 
  UploadCloud, Search, ArrowDownAz, ArrowUpZa, List, LayoutGrid, ImageIcon, 
  Download, Trash2, Film, Play, Loader2, FolderOpen, ArrowRight, PauseCircle, 
  PlayCircle, ZoomOut, ZoomIn, VolumeX, Volume2, X, Folder, File, FileText, 
  Image as ImageIcon2, AlertCircle, HelpCircle, Edit3, HardDrive, Eye, EyeOff, Key, Star
} from 'lucide-vue-next';

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
const isDragging = ref(false); // Used for window drag drop upload
const uploadProgress = ref(0);
const unlockedPasswords = ref({});
const activeDropdown = ref(null);

// Item Drag & Drop State
const draggedItem = ref(null);
const dragTarget = ref(null);

// Vault State
const vaultUnlocked = ref(false);
const isVaultPasswordSet = ref(false);
const vaultPassword = ref('');

// Dialog State
const dialogState = ref({
  isOpen: false,
  type: 'alert',
  title: '',
  message: '',
  inputValue: '',
  resolve: null
});
const dialogInput = ref(null);

function showAlert(message, title = 'Thông báo') {
  return new Promise((resolve) => {
    dialogState.value = { isOpen: true, type: 'alert', title, message, inputValue: '', resolve };
  });
}

function showConfirm(message, title = 'Xác nhận') {
  return new Promise((resolve) => {
    dialogState.value = { isOpen: true, type: 'confirm', title, message, inputValue: '', resolve };
  });
}

function showPrompt(message, title = 'Nhập liệu') {
  return new Promise((resolve) => {
    dialogState.value = { isOpen: true, type: 'prompt', title, message, inputValue: '', resolve };
    setTimeout(() => {
      if (dialogInput.value) dialogInput.value.focus();
    }, 50);
  });
}

function confirmDialog() {
  if (!dialogState.value.isOpen) return;
  const result = dialogState.value.type === 'prompt' ? dialogState.value.inputValue : true;
  if (dialogState.value.resolve) dialogState.value.resolve(result);
  dialogState.value.isOpen = false;
}

function cancelDialog() {
  if (!dialogState.value.isOpen) return;
  const result = dialogState.value.type === 'prompt' ? null : false;
  if (dialogState.value.resolve) dialogState.value.resolve(result);
  dialogState.value.isOpen = false;
}

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
  return items.value.some(item => !item.isDirectory && (isVideo(item) || isImage(item) || isPdf(item) || isCodeOrText(item)));
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

const parentPath = computed(() => {
  if (!currentPath.value) return '';
  const parts = currentPath.value.split('/');
  parts.pop();
  return parts.join('/');
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
    // 3.1 Pinned items first
    if (a.isPinned !== b.isPinned) {
      return a.isPinned ? -1 : 1;
    }

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
    const response = await axios.get(`${base}/api/files`, { 
      params: { path, password },
      headers: { 'Vault-Password': vaultPassword.value }
    });
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
      const pwd = await showPrompt("Thư mục này đã bị khóa. Vui lòng nhập mật khẩu:");
      if (pwd) {
        unlockedPasswords.value[path] = pwd;
        return loadItems();
      } else {
        goBack();
        return;
      }
    }
    console.error("Lỗi khi load danh sách file:", error);
    await showAlert("Lỗi tải file. Kiểm tra kết nối mạng, server hoặc mật khẩu.", "Lỗi");
  } finally {
    loading.value = false;
  }
}

function getIconComponent(item) {
  if (item.type === 'Drive') return item.isLocked ? Lock : HardDrive;
  if (item.isDirectory) return item.isLocked ? Lock : Folder;
  if (isVideo(item)) return Film;
  if (isImage(item)) return ImageIcon2;
  if (isPdf(item) || isCodeOrText(item)) return FileText;
  return File;
}

function getIconColor(item) {
  if (item.isDirectory) return 'text-amber-500';
  if (isVideo(item)) return 'text-purple-500';
  if (isImage(item)) return 'text-sky-500';
  if (isPdf(item) || isCodeOrText(item)) return 'text-slate-500';
  return 'text-slate-400';
}

function isVideo(item) {
  return ['.mp4', '.webm', '.mkv'].includes((item.extension || '').toLowerCase());
}

function isImage(item) {
  return ['.jpg', '.jpeg', '.png', '.webp'].includes((item.extension || '').toLowerCase());
}

function isPdf(item) {
  return (item.extension || '').toLowerCase() === '.pdf';
}

function isCodeOrText(item) {
  return ['.txt', '.md', '.csv', '.cs', '.js', '.html', '.css', '.json', '.py', '.cpp', '.c', '.java'].includes((item.extension || '').toLowerCase());
}

function isDocument(item) {
  return ['.doc', '.docx', '.xls', '.xlsx'].includes((item.extension || '').toLowerCase());
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
      const shouldResume = await showConfirm(
        `Bạn đang xem dở ở phút ${Math.floor(stoppedAt / 60)}:${Math.floor(stoppedAt % 60).toString().padStart(2, '0')}. Bạn có muốn phát tiếp không?`, 
        "Tiếp tục xem"
      );
      if (shouldResume) {
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
      console.error("Lß╗ùi l╞░u lß╗ïch sß╗¡:", err);
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
  const mediaItems = items.value.filter(item => !item.isDirectory && (isVideo(item) || isImage(item) || isPdf(item) || isCodeOrText(item)));
  const currentIndex = mediaItems.findIndex(item => item.relativePath === selectedMedia.value?.relativePath);
  if (currentIndex <= 0) {
    if (slideshowInterval.value) toggleSlideshow();
    return;
  }
  selectMedia(mediaItems[currentIndex - 1]);
}

function showNextMedia() {
  const mediaItems = items.value.filter(item => !item.isDirectory && (isVideo(item) || isImage(item) || isPdf(item) || isCodeOrText(item)));
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

async function toggleVault() {
  if (vaultUnlocked.value) {
    vaultUnlocked.value = false;
    vaultPassword.value = '';
    loadItems();
    return;
  }

  if (!isVaultPasswordSet.value) {
    const pwd = await showPrompt("Két sắt chưa được thiết lập. Vui lòng nhập mật khẩu Két Sắt mới:", "Khởi tạo Két Sắt");
    if (!pwd) return;
    try {
      const base = import.meta.env.VITE_API_BASE || '';
      const token = localStorage.getItem('jwt_token');
      await axios.post(`${base}/api/media/vault/password`, { newPassword: pwd }, { headers: { Authorization: `Bearer ${token}` } });
      isVaultPasswordSet.value = true;
      vaultPassword.value = pwd;
      vaultUnlocked.value = true;
      await showAlert("Đã thiết lập Két Sắt thành công!", "Thành công");
      loadItems();
    } catch (err) {
      await showAlert(err.response?.data || "Lỗi khi thiết lập mật khẩu.", "Lỗi");
    }
  } else {
    const pwd = await showPrompt("Vui lòng nhập mật khẩu Két Sắt:", "Mở khóa Két Sắt");
    if (!pwd) return;
    vaultPassword.value = pwd;
    vaultUnlocked.value = true;
    loadItems();
  }
}

async function changeVaultPassword() {
  if (!isVaultPasswordSet.value) return;
  const oldPwd = await showPrompt("Nhập mật khẩu Két Sắt cũ:", "Đổi mật khẩu Két Sắt");
  if (!oldPwd) return;
  const newPwd = await showPrompt("Nhập mật khẩu Két Sắt mới:", "Đổi mật khẩu Két Sắt");
  if (!newPwd) return;
  
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    await axios.post(`${base}/api/media/vault/password`, { oldPassword: oldPwd, newPassword: newPwd }, { headers: { Authorization: `Bearer ${token}` } });
    if (vaultUnlocked.value) {
      vaultPassword.value = newPwd;
    }
    await showAlert("Đã đổi mật khẩu Két Sắt thành công!", "Thành công");
  } catch (err) {
    await showAlert(err.response?.data || "Lỗi khi đổi mật khẩu.", "Lỗi");
  }
}

async function hideItem(item) {
  if (!isVaultPasswordSet.value || !vaultUnlocked.value) {
    await showAlert("Bạn phải mở khóa Két Sắt trước khi ẩn thư mục.", "Yêu cầu Két Sắt");
    return;
  }
  const confirmed = await showConfirm(`Bạn có chắc muốn ẩn '${item.name}' không?`, "Xác nhận Ẩn");
  if (!confirmed) return;
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    await axios.post(`${base}/api/media/vault/hide`, { path: item.relativePath, password: vaultPassword.value }, { headers: { Authorization: `Bearer ${token}` } });
    await showAlert("Đã ẩn thư mục thành công.", "Thành công");
    loadItems();
  } catch (err) {
    await showAlert(err.response?.data || "Lỗi khi ẩn thư mục.", "Lỗi");
  }
}

async function unhideItem(item) {
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    await axios.post(`${base}/api/media/vault/unhide`, { path: item.relativePath, password: vaultPassword.value }, { headers: { Authorization: `Bearer ${token}` } });
    await showAlert("Đã bỏ ẩn thư mục thành công.", "Thành công");
    loadItems();
  } catch (err) {
    await showAlert(err.response?.data || "Lỗi khi bỏ ẩn thư mục.", "Lỗi");
  }
}

async function renameItem(item) {
  const newName = await showPrompt(`Nhập tên mới cho '${item.name}':`, "Đổi tên");
  if (!newName || newName === item.name) return;
  
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token');
  try {
    const res = await axios.post(`${base}/api/media/rename`, {
      path: item.relativePath,
      newName: newName
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    await showAlert(res.data.Message || 'Đã đổi tên thành công', "Thành công");
    
    if (selectedMedia.value && selectedMedia.value.relativePath === item.relativePath) {
      closeViewer();
    }
    
    loadItems();
  } catch (err) {
    console.error('Lỗi khi đổi tên:', err);
    await showAlert(err.response?.data || 'Có lỗi xảy ra khi đổi tên', "Lỗi");
  }
}

async function deleteItem(item) {
  const confirmed = await showConfirm(`Bạn có chắc muốn xóa '${item.name}' vào thùng rác không?`, "Xác nhận xóa");
  if (!confirmed) return;
  
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token');
  try {
    const res = await axios.post(`${base}/api/media/delete`, {
      path: item.relativePath
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    await showAlert(res.data.Message || 'Đã xóa vào thùng rác thành công', "Thành công");
    
    // Nếu đang mở file bị xóa, đóng nó lại
    if (selectedMedia.value && selectedMedia.value.relativePath === item.relativePath) {
      closeViewer();
    }
    
    loadItems();
  } catch (err) {
    console.error('Lỗi khi xóa:', err);
    await showAlert(err.response?.data || 'Có lỗi xảy ra khi xóa', "Lỗi");
  }
}

async function pinItem(item) {
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    await axios.post(`${base}/api/files/pin`, { path: item.relativePath }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    // Optimistic UI update
    item.isPinned = true;
  } catch (err) {
    console.error('Lỗi khi ghim:', err);
  }
}

async function unpinItem(item) {
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    await axios.post(`${base}/api/files/unpin`, { path: item.relativePath }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    // Optimistic UI update
    item.isPinned = false;
  } catch (err) {
    console.error('Lỗi khi bỏ ghim:', err);
  }
}

// Drag & Drop Item Handlers
function onItemDragStart(event, item) {
  draggedItem.value = item;
  event.dataTransfer.effectAllowed = 'move';
  // Use a slight delay to allow the drag image to be generated before styling changes
  setTimeout(() => {
    // Optionally add a global class to body while dragging
  }, 0);
}

function onItemDragEnter(event, item) {
  if (!draggedItem.value || draggedItem.value.relativePath === item.relativePath || !item.isDirectory) return;
  dragTarget.value = item.relativePath;
}

function onItemDragLeave(event, item) {
  if (dragTarget.value === item.relativePath) {
    dragTarget.value = null;
  }
}

function onItemDragOver(event, item) {
  if (draggedItem.value && item.isDirectory && draggedItem.value.relativePath !== item.relativePath) {
    event.dataTransfer.dropEffect = 'move';
  }
}

async function onItemDrop(event, item) {
  const source = draggedItem.value;
  draggedItem.value = null;
  dragTarget.value = null;

  if (!source || !item.isDirectory || source.relativePath === item.relativePath) return;

  const targetFolder = item.relativePath;

  // Confirmation
  const confirmed = await showConfirm(`Bạn có chắc muốn di chuyển '${source.name}' vào thư mục '${item.name}' không?`, "Xác nhận di chuyển");
  if (!confirmed) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const token = localStorage.getItem('jwt_token');
    await axios.post(`${base}/api/files/move`, { 
      sourcePath: source.relativePath,
      targetFolder: targetFolder
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    await showAlert("Di chuyển thành công!", "Thành công");
    loadItems();
  } catch (err) {
    console.error('Lỗi khi di chuyển:', err);
    await showAlert(err.response?.data || 'Có lỗi xảy ra khi di chuyển.', "Lỗi");
  }
}

async function handleLockFolder() {
  const pwd = await showPrompt(`Nhập mật khẩu để khóa thư mục hiện tại:`, "Khóa thư mục");
  if (!pwd) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.post(`${base}/api/media/lock`, {
      path: currentPath.value,
      password: pwd
    });
    await showAlert(response.data.message || "Đã khóa thư mục thành công!", "Thành công");
    unlockedPasswords.value[currentPath.value] = pwd;
    loadItems();
  } catch (error) {
    await showAlert("Lỗi khi khóa thư mục: " + (error.response?.data || error.message), "Lỗi");
  }
}

async function lockItem(item) {
  const pwd = await showPrompt(`Nhập mật khẩu để khóa thư mục "${item.name}":`, "Khóa thư mục");
  if (!pwd) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.post(`${base}/api/media/lock`, {
      path: item.relativePath,
      password: pwd
    });
    await showAlert(response.data.message || "Đã khóa thư mục thành công!", "Thành công");
    unlockedPasswords.value[item.relativePath] = pwd;
    loadItems();
  } catch (error) {
    await showAlert("Lỗi khi khóa thư mục: " + (error.response?.data || error.message), "Lỗi");
  }
}

async function unlockItem(item) {
  const pwd = await showPrompt(`Nhập mật khẩu để gỡ khóa thư mục "${item.name}":`, "Mở khóa thư mục");
  if (!pwd) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.post(`${base}/api/media/unlock`, {
      path: item.relativePath,
      password: pwd
    });
    await showAlert(response.data.message || "Đã gỡ khóa thư mục thành công!", "Thành công");
    delete unlockedPasswords.value[item.relativePath];
    loadItems();
  } catch (error) {
    if (error.response?.status === 403) {
      await showAlert("Mật khẩu không đúng!", "Lỗi");
    } else {
      await showAlert("Lỗi khi gỡ khóa thư mục: " + (error.response?.data || error.message), "Lỗi");
    }
  }
}

async function handleCreateFolder() {
  const folderName = await showPrompt("Nhập tên thư mục cần tạo:", "Thư mục mới");
  if (!folderName) return;

  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const response = await axios.post(`${base}/api/media/create-folder`, {
      folderName: folderName,
      subPath: currentPath.value
    });

    await showAlert("Đã tạo thư mục thành công!", "Thành công");
    loadItems();
  } catch (error) {
    const err = error.response?.data || error.message;
    await showAlert("Lỗi: " + err, "Lỗi");
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

    await showAlert("Tải file lên thành công!", "Thành công");
    loadItems();
    showUploadModal.value = false;
  } catch (error) {
    console.error(error);
    await showAlert("Có lỗi xảy ra trong quá trình upload: " + (error.response?.data || error.message), "Lỗi");
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

function getGenericFileUrl(item) {
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token') || '';
  const path = item.relativePath.split('/').map(segment => encodeURIComponent(segment)).join('/');
  return `${base}/api/media/file/${path}?access_token=${token}`;
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
  const token = localStorage.getItem('jwt_token') || '';
  const path = item.relativePath
    .split('/')
    .map(segment => encodeURIComponent(segment))
    .join('/');

  const url = `${base}/api/media/download/${path}?access_token=${token}`;

  const link = document.createElement('a');
  link.href = url;
  link.download = item.name || 'download';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// Global Keyboard Shortcuts
function handleGlobalKeyDown(e) {
  // Only process if media viewer is open
  if (!selectedMedia.value) return;
  
  // Don't intercept if user is typing in an input or textarea
  if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
  
  const video = videoRef.value;
  
  switch(e.key) {
    case ' ': // Space
      e.preventDefault();
      if (video) {
        if (video.paused) video.play();
        else video.pause();
      }
      break;
    case 'ArrowLeft':
      e.preventDefault();
      if (video) video.currentTime = Math.max(0, video.currentTime - 10);
      break;
    case 'ArrowRight':
      e.preventDefault();
      if (video) video.currentTime = Math.min(video.duration, video.currentTime + 10);
      break;
    case 'ArrowUp':
      e.preventDefault();
      if (video) video.volume = Math.min(1, video.volume + 0.1);
      break;
    case 'ArrowDown':
      e.preventDefault();
      if (video) video.volume = Math.max(0, video.volume - 0.1);
      break;
    case 'f':
    case 'F':
      e.preventDefault();
      if (video) {
        if (!document.fullscreenElement) {
          video.requestFullscreen().catch(err => console.log(err));
        } else {
          document.exitFullscreen();
        }
      }
      break;
    case 'Escape':
      closeViewer();
      break;
  }
}

watch(() => route.query.path, () => {
  loadItems();
  selectedMedia.value = null;
  imageScale.value = 1;
  isMuted.value = false;
});

onMounted(async () => {
  const base = import.meta.env.VITE_API_BASE || '';
  const token = localStorage.getItem('jwt_token');
  if (token) {
    try {
      const res = await axios.get(`${base}/api/media/vault/status`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      isVaultPasswordSet.value = res.data.isSet;
    } catch (e) {
      console.error(e);
    }
  }
  window.addEventListener('keydown', handleGlobalKeyDown);
  loadItems();
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleGlobalKeyDown);
});
</script>

<style>
body {
  background-color: #020617; /* bg-slate-950 */
}
</style>
