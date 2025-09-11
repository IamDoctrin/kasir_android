import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/sync_manager.dart';

class LastSyncWidget extends StatefulWidget {
  const LastSyncWidget({super.key});

  @override
  State<LastSyncWidget> createState() => LastSyncWidgetState();
}

class LastSyncWidgetState extends State<LastSyncWidget> {
  DateTime? _lastSyncTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadLastSyncTime();
    // Refresh tampilan setiap menit
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateDisplay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void loadLastSyncTime() async {
    _lastSyncTime = await SyncManager.getLastSyncTime();
    if (mounted) setState(() {});
  }

  void _updateDisplay() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} jam yang lalu';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit yang lalu';
    }
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    if (_lastSyncTime == null) {
      return const SizedBox.shrink(); // Jangan tampilkan apapun jika belum pernah sync
    }

    final difference = DateTime.now().difference(_lastSyncTime!);
    return Text(
      'Sinkronisasi terakhir: ${_formatDuration(difference)}',
      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
    );
  }
}
