class FileItemModel {
  final String name;
  final String relativePath;
  final String extension;
  final String type;
  final int size;
  final String sizeFormatted;
  final DateTime lastModified;
  final DateTime createdDate;
  final bool isDirectory;
  final bool isLocked;
  final bool isHidden;
  final bool isPinned;
  final String mimeType;

  FileItemModel({
    required this.name,
    required this.relativePath,
    required this.extension,
    required this.type,
    required this.size,
    required this.sizeFormatted,
    required this.lastModified,
    required this.createdDate,
    required this.isDirectory,
    required this.isLocked,
    required this.isHidden,
    required this.isPinned,
    required this.mimeType,
  });

  factory FileItemModel.fromJson(Map<String, dynamic> json) {
    return FileItemModel(
      name: json['name'] ?? '',
      relativePath: json['relativePath'] ?? '',
      extension: json['extension'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      sizeFormatted: json['sizeFormatted'] ?? '',
      lastModified: DateTime.parse(json['lastModified'] ?? DateTime.now().toIso8601String()),
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      isDirectory: json['isDirectory'] ?? false,
      isLocked: json['isLocked'] ?? false,
      isHidden: json['isHidden'] ?? false,
      isPinned: json['isPinned'] ?? false,
      mimeType: json['mimeType'] ?? '',
    );
  }
}
