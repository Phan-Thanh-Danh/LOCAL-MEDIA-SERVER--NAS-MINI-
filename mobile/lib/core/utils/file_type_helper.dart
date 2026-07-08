import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

class FileTypeHelper {
  static IconData getIconForType(String type, bool isDirectory) {
    if (isDirectory) return LucideIcons.folder;
    
    switch (type.toLowerCase()) {
      case 'video':
      case 'video/mp4':
      case 'video/x-matroska':
      case 'video/x-msvideo':
        return LucideIcons.film;
      case 'hình ảnh':
      case 'image':
      case 'image/jpeg':
      case 'image/png':
      case 'image/gif':
      case 'image/webp':
        return LucideIcons.image;
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

  static Color getColorForType(String type, bool isDirectory) {
    if (isDirectory) return const Color(0xFFF59E0B); // Amber
    
    switch (type.toLowerCase()) {
      case 'video':
      case 'video/mp4':
        return const Color(0xFF8B5CF6); // Purple
      case 'hình ảnh':
      case 'image':
      case 'image/jpeg':
      case 'image/png':
        return const Color(0xFF0EA5E9); // Sky blue
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
}
