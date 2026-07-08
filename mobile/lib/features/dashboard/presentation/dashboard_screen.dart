import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';
import '../data/system_service.dart';
import '../models/dashboard_info.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardInfo? _info;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final info = await ref.read(systemServiceProvider).getDashboardInfo();
      setState(() {
        _info = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadData,
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
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
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
                                  Text(FormatHelper.formatBytes(_info?.appRamUsage ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Ổ đĩa lưu trữ', style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 16),
                      if (_info != null)
                        ..._info!.drives.map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildDriveCard(d),
                            )),
                    ],
                  ),
                ),
    );
  }
}
