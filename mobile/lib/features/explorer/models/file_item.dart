class FileItem {
  final String name;
  final String relativePath;
  final bool isDirectory;
  final int size;
  final String sizeFormatted;
  final DateTime lastModified;
  final String type;
  final bool isPinned;
  final bool isHidden;
  final bool isLocked;

  FileItem({
    required this.name,
    required this.relativePath,
    required this.isDirectory,
    required this.size,
    required this.sizeFormatted,
    required this.lastModified,
    required this.type,
    required this.isPinned,
    required this.isHidden,
    required this.isLocked,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] ?? '',
      relativePath: json['relativePath'] ?? '',
      isDirectory: json['isDirectory'] ?? false,
      size: json['size'] ?? 0,
      sizeFormatted: json['sizeFormatted'] ?? '',
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : DateTime.now(),
      type: json['type'] ?? '',
      isPinned: json['isPinned'] ?? false,
      isHidden: json['isHidden'] ?? false,
      isLocked: json['isLocked'] ?? false,
    );
  }
}
