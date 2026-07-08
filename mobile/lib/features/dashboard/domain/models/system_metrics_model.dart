class SystemMetricsModel {
  final double cpu;
  final double ramUsed;
  final double ramTotal;
  final double diskRead;
  final double diskWrite;
  final double netReceive;
  final double netSend;
  final DateTime timestamp;

  SystemMetricsModel({
    required this.cpu,
    required this.ramUsed,
    required this.ramTotal,
    required this.diskRead,
    required this.diskWrite,
    required this.netReceive,
    required this.netSend,
    required this.timestamp,
  });

  factory SystemMetricsModel.fromJson(Map<String, dynamic> json) {
    return SystemMetricsModel(
      cpu: (json['cpu'] as num).toDouble(),
      ramUsed: (json['ramUsed'] as num).toDouble(),
      ramTotal: (json['ramTotal'] as num).toDouble(),
      diskRead: (json['diskRead'] as num).toDouble(),
      diskWrite: (json['diskWrite'] as num).toDouble(),
      netReceive: (json['netReceive'] as num).toDouble(),
      netSend: (json['netSend'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
