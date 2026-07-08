class AuditLog {
  final int id;
  final String? username;
  final String action;
  final String? apiPath;
  final String? payload;
  final String? ipAddress;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    this.username,
    required this.action,
    this.apiPath,
    this.payload,
    this.ipAddress,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] ?? 0,
      username: json['username'],
      action: json['action'] ?? '',
      apiPath: json['apiPath'],
      payload: json['payload'],
      ipAddress: json['ipAddress'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}
