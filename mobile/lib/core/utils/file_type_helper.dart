import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

class FileTypeHelper {
  static IconData getIconForType(String type, bool isDirectory, [String name = '']) {
    if (isDirectory) return LucideIcons.folder;
    if (isVideo(name, type)) return LucideIcons.film;
    if (isImage(name, type)) return LucideIcons.image;
    
    switch (type.toLowerCase()) {
      case 'âm thanh':
      case 'audio':
      case 'audio/mpeg':
      case 'audio/wav':
        return LucideIcons.music;
      case 'tài liệu':
      case 'document':
      case 'application/pdf':
        return LucideIcons.fileText;
      case 'code':
      case 'text/plain':
      case 'text/html':
      case 'application/json':
        return LucideIcons.code;
      case 'lưu trữ':
      case 'archive':
      case 'application/zip':
      case 'application/x-rar-compressed':
        return LucideIcons.archive;
      default:
        return LucideIcons.file;
    }
  }

  static Color getColorForType(String type, bool isDirectory, [String name = '']) {
    if (isDirectory) return const Color(0xFFF59E0B); // Amber
    if (isVideo(name, type)) return const Color(0xFF8B5CF6); // Purple
    if (isImage(name, type)) return const Color(0xFF0EA5E9); // Sky blue
    
    switch (type.toLowerCase()) {
      case 'âm thanh':
      case 'audio':
        return const Color(0xFFEC4899); // Pink
      case 'tài liệu':
      case 'document':
      case 'application/pdf':
        return const Color(0xFFEF4444); // Red
      case 'code':
      case 'text/plain':
        return const Color(0xFF64748B); // Slate
      case 'lưu trữ':
      case 'archive':
        return const Color(0xFF10B981); // Emerald
      default:
        return const Color(0xFF94A3B8); // Slate lighter
    }
  }

  static bool isImage(String name, String type) {
    final lowerName = name.toLowerCase();
    final lowerType = type.toLowerCase();
    if (lowerType.contains('hình ảnh') || lowerType.contains('image')) return true;
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png') || lowerName.endsWith('.gif') || lowerName.endsWith('.webp') || lowerName.endsWith('.bmp')) return true;
    return false;
  }

  static bool isVideo(String name, String type) {
    final lowerName = name.toLowerCase();
    final lowerType = type.toLowerCase();
    if (lowerType.contains('video')) return true;
    if (lowerName.endsWith('.mp4') || lowerName.endsWith('.mkv') || lowerName.endsWith('.avi') || lowerName.endsWith('.mov') || lowerName.endsWith('.wmv') || lowerName.endsWith('.flv') || lowerName.endsWith('.webm')) return true;
    return false;
  }

  static bool isPdf(String name, String type) {
    final lowerName = name.toLowerCase();
    return lowerName.endsWith('.pdf') || type.toLowerCase() == 'application/pdf';
  }

  static bool isText(String name, String type) {
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.txt') || lowerName.endsWith('.md') || lowerName.endsWith('.csv') || lowerName.endsWith('.json') || lowerName.endsWith('.xml') || lowerName.endsWith('.html') || lowerName.endsWith('.css') || lowerName.endsWith('.js') || lowerName.endsWith('.dart')) return true;
    if (type.toLowerCase().startsWith('text/')) return true;
    return false;
  }

  static bool isWord(String name, String type) {
    final lowerName = name.toLowerCase();
    return lowerName.endsWith('.doc') || lowerName.endsWith('.docx') || type.toLowerCase() == 'application/msword';
  }
}
