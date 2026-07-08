import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/system_service.dart';
import '../models/dashboard_info.dart';
import '../models/audit_log.dart';
import '../models/system_metrics.dart';
import 'widgets/realtime_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardInfo? _info;
  bool _isLoading = true;
  String? _error;

  List<AuditLog> _auditLogs = [];
  bool _auditLogsLoading = true;
  String? _auditLogsError;
  Timer? _auditLogsTimer;

  HubConnection? _hubConnection;
  
  // Chart Data State
  static const int maxPoints = 60;
  List<double> _cpuData = List.filled(maxPoints, 0.0, growable: true);
  List<double> _ramData = List.filled(maxPoints, 0.0, growable: true);
  List<double> _diskReadData = List.filled(maxPoints, 0.0, growable: true);
  List<double> _diskWriteData = List.filled(maxPoints, 0.0, growable: true);
  List<double> _netReceiveData = List.filled(maxPoints, 0.0, growable: true);
  List<double> _netSendData = List.filled(maxPoints, 0.0, growable: true);

  SystemMetrics _currentMetrics = SystemMetrics();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadAuditLogs();
    _auditLogsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadAuditLogs(isPolling: true);
    });
    _setupSignalR();
  }

  @override
  void dispose() {
    _auditLogsTimer?.cancel();
    _hubConnection?.stop();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final info = await ref.read(systemServiceProvider).getDashboardInfo();
      if (mounted) {
        setState(() {
          _info = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAuditLogs({bool isPolling = false}) async {
    if (!isPolling && mounted) {
      setState(() {
        _auditLogsLoading = true;
      });
    }
    try {
      final logs = await ref.read(systemServiceProvider).getAuditLogs(limit: 20);
      if (mounted) {
        setState(() {
          _auditLogs = logs;
          _auditLogsLoading = false;
          _auditLogsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _auditLogsError = e.toString();
          _auditLogsLoading = false;
        });
      }
    }
  }

  Future<void> _setupSignalR() async {
    final storage = SecureStorageService();
    final baseUrl = await storage.getBaseUrl();
    final token = await storage.getToken();

    if (baseUrl == null || token == null) return;

    final hubUrl = '$baseUrl/hubs/media?access_token=$token';

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('ReceiveSystemMetrics', _handleMetricsUpdate);

    try {
      await _hubConnection?.start();
    } catch (e) {
      print('SignalR connection error: $e');
    }
  }

  void _handleMetricsUpdate(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final data = args[0] as Map<String, dynamic>;
      final metrics = SystemMetrics.fromJson(data);

      if (mounted) {
        setState(() {
          _currentMetrics = metrics;

          // Update lists and shift left
          _cpuData.add(metrics.cpu.toDouble());
          _cpuData.removeAt(0);

          _ramData.add(metrics.ramUsed); // Already in GB from C#
          _ramData.removeAt(0);

          _diskReadData.add(metrics.diskRead); // Already in KB/s from C#
          _diskReadData.removeAt(0);
          
          _diskWriteData.add(metrics.diskWrite); // Already in KB/s from C#
          _diskWriteData.removeAt(0);

          _netReceiveData.add(metrics.netReceive); // Already in KB/s from C#
          _netReceiveData.removeAt(0);
          
          _netSendData.add(metrics.netSend); // Already in KB/s from C#
          _netSendData.removeAt(0);
        });
      }
    } catch (e) {
      print('Error parsing metrics: $e');
    }
  }

  Widget _buildDriveCard(DriveInfo drive) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.hardDrive, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  drive.name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: drive.usedPercentage / 100,
              backgroundColor: AppColors.border,
              color: drive.usedPercentage > 90 ? AppColors.error : AppColors.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đã dùng', style: Theme.of(context).textTheme.bodySmall),
                    Text(FormatHelper.formatBytes(drive.usedSpace), style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Còn trống', style: Theme.of(context).textTheme.bodySmall),
                    Text(FormatHelper.formatBytes(drive.availableFreeSpace), style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogs() {
    if (_auditLogsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_auditLogsError != null) {
      return Center(child: Text(_auditLogsError!, style: const TextStyle(color: AppColors.error)));
    }
    if (_auditLogs.isEmpty) {
      return const Center(child: Text('Không có nhật ký hoạt động'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _auditLogs.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(LucideIcons.activity, color: AppColors.primary, size: 20),
          ),
          title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (log.payload != null && log.payload!.isNotEmpty) 
                Text(log.payload!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.user, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(log.username ?? 'System', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.clock, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(FormatHelper.formatDate(log.timestamp), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              _loadInitialData();
              _loadAuditLogs();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadInitialData();
                    await _loadAuditLogs();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 0,
                          color: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Icon(LucideIcons.activity, color: AppColors.primary),
                                    const SizedBox(height: 8),
                                    const Text('Uptime', style: TextStyle(color: AppColors.textSecondary)),
                                    Text(_info?.uptime ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Icon(LucideIcons.cpu, color: AppColors.primary),
                                    const SizedBox(height: 8),
                                    const Text('RAM', style: TextStyle(color: AppColors.textSecondary)),
                                    Text('${_currentMetrics.ramUsed.toStringAsFixed(2)} GB', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Text('Biểu đồ thời gian thực', style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 16),
                        
                        RealtimeChart(
                          title: 'CPU Usage',
                          dataPoints: _cpuData,
                          color1: Colors.lightBlue,
                          maxY: 100,
                          label1: 'CPU (%)',
                        ),
                        const SizedBox(height: 16),
                        RealtimeChart(
                          title: 'RAM Usage',
                          dataPoints: _ramData,
                          color1: Colors.green,
                          maxY: (_currentMetrics.ramTotal > 0) ? _currentMetrics.ramTotal : 16,
                          label1: 'RAM (GB)',
                        ),
                        const SizedBox(height: 16),
                        RealtimeChart(
                          title: 'Disk I/O',
                          dataPoints: _diskReadData,
                          dataPoints2: _diskWriteData,
                          color1: Colors.purple,
                          color2: Colors.pink,
                          maxY: 50000, // 50MB/s max display, auto scaling is complicated in fl_chart without dynamic loop
                          label1: 'Read (KB/s)',
                          label2: 'Write (KB/s)',
                        ),
                        const SizedBox(height: 16),
                        RealtimeChart(
                          title: 'Network',
                          dataPoints: _netSendData,
                          dataPoints2: _netReceiveData,
                          color1: Colors.orange,
                          color2: Colors.amber,
                          maxY: 50000, 
                          label1: 'Send (KB/s)',
                          label2: 'Receive (KB/s)',
                        ),

                        const SizedBox(height: 32),
                        Text('Ổ đĩa lưu trữ', style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 16),
                        if (_info != null)
                          ..._info!.drives.map((d) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _buildDriveCard(d),
                              )),

                        const SizedBox(height: 32),
                        Text('Nhật ký hoạt động', style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 0,
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: _buildAuditLogs(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
}
