class DriveInfo {
  final String name;
  final int totalSize;
  final int availableFreeSpace;
  final int usedSpace;
  final double usedPercentage;

  DriveInfo({
    required this.name,
    required this.totalSize,
    required this.availableFreeSpace,
    required this.usedSpace,
    required this.usedPercentage,
  });

  factory DriveInfo.fromJson(Map<String, dynamic> json) {
    return DriveInfo(
      name: json['name'] ?? '',
      totalSize: json['totalSize'] ?? 0,
      availableFreeSpace: json['availableFreeSpace'] ?? 0,
      usedSpace: json['usedSpace'] ?? 0,
      usedPercentage: (json['usedPercentage'] ?? 0).toDouble(),
    );
  }
}

class DashboardInfo {
  final List<DriveInfo> drives;
  final int appRamUsage;
  final String uptime;

  DashboardInfo({
    required this.drives,
    required this.appRamUsage,
    required this.uptime,
  });

  factory DashboardInfo.fromJson(Map<String, dynamic> json) {
    var drivesList = json['drives'] as List? ?? [];
    List<DriveInfo> parsedDrives = drivesList.map((i) => DriveInfo.fromJson(i)).toList();

    return DashboardInfo(
      drives: parsedDrives,
      appRamUsage: json['appRamUsage'] ?? 0,
      uptime: json['uptime'] ?? '',
    );
  }
}
