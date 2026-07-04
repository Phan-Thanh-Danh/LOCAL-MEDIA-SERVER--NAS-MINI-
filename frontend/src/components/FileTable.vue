<template>
  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Date modified</th>
        <th>Type</th>
        <th>Size</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="item in items" :key="item.relativePath" @dblclick="$emit('open-item', item)">
        <td>{{ getIcon(item) }} {{ item.name }}</td>
        <td>{{ formatDate(item.lastModified) }}</td>
        <td>{{ item.type }}</td>
        <td>{{ item.sizeFormatted || '' }}</td>
      </tr>
    </tbody>
  </table>
</template>

<script setup>
const props = defineProps({ items: Array });
const emit = defineEmits(['open-item']);

function getIcon(item) {
  if (item.isDirectory) return '📁';
  if (['.mp4', '.webm', '.mkv'].includes((item.extension || '').toLowerCase())) return '🎬';
  if (['.jpg', '.jpeg', '.png', '.webp'].includes((item.extension || '').toLowerCase())) return '🖼️';
  return '📄';
}

function formatDate(value) {
  return new Date(value).toLocaleString();
}
</script>
