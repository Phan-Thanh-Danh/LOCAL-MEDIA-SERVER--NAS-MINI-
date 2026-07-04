<template>
  <div class="breadcrumb">
    <button @click="$emit('navigate', '')">Home</button>
    <template v-for="(segment, index) in segments" :key="index">
      <span>/</span>
      <button @click="$emit('navigate', segment.path)">{{ segment.name }}</button>
    </template>
  </div>
</template>

<script setup>
const props = defineProps({ segments: Array });
const emit = defineEmits(['navigate']);
</script>
