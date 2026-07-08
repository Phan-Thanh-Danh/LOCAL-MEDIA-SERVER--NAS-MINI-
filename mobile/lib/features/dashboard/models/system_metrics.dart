class SystemMetrics {
  final double cpu;
  final double ramUsed;
  final double ramTotal;
  final double diskRead;
  final double diskWrite;
  final double netReceive;
  final double netSend;

  SystemMetrics({
    this.cpu = 0.0,
    this.ramUsed = 0.0,
    this.ramTotal = 0.0,
    this.diskRead = 0.0,
    this.diskWrite = 0.0,
    this.netReceive = 0.0,
    this.netSend = 0.0,
  });

  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      cpu: (json['cpu'] ?? 0).toDouble(),
      ramUsed: (json['ramUsed'] ?? 0).toDouble(),
      ramTotal: (json['ramTotal'] ?? 16).toDouble(),
      diskRead: (json['diskRead'] ?? 0).toDouble(),
      diskWrite: (json['diskWrite'] ?? 0).toDouble(),
      netReceive: (json['netReceive'] ?? 0).toDouble(),
      netSend: (json['netSend'] ?? 0).toDouble(),
    );
  }
}
