<template>
  <video controls :src="src"></video>
</template>

<script setup>
const props = defineProps({ src: String });
</script>
