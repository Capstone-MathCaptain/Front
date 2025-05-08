import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:capstone/services/group_service.dart';
import 'package:capstone/screens/group/memo_screen.dart';
import 'package:capstone/screens/user/personal_card_overlay.dart';

class RecordScreen extends StatefulWidget {
  final int groupId;

  const RecordScreen({super.key, required this.groupId});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isLoading = false;
  DateTime? _startTime;
  DateTime? _endTime;

  void _startTimer() {
    if (_isRunning || _isLoading) return;
    _startTime = DateTime.now();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _pauseTimer() {
    if (_isLoading) return;
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _completeTimer() async {
    if (_isLoading) return;
    _pauseTimer();
    _endTime = DateTime.now();
    setState(() => _isLoading = true);

    final minutes = _seconds ~/ 60;
    try {
      // 1) 그룹 카테고리 조회
      final groupDetails = await GroupService.fetchGroupDetails(widget.groupId);
      if (!mounted) return;
      final category = groupDetails['category'] as String? ?? '';

      // 2) 메모 화면으로 이동
      final responseData = await Navigator.push<Map<String, dynamic>?>(
        context,
        MaterialPageRoute(
          builder:
              (_) => MemoScreen(
                groupId: widget.groupId,
                category: category,
                startTime: _startTime!.toIso8601String(),
                endTime: _endTime!.toIso8601String(),
                activityTimeMinutes: minutes,
              ),
        ),
      );
      if (!mounted) return;

      // 3) 타이머 및 상태 초기화
      setState(() {
        _seconds = 0;
        _startTime = null;
        _endTime = null;
      });

      // 4) 결과에 따른 행동
      if (responseData != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          builder:
              (_) => PersonalCardOverlay(
                durationInMinutes:
                    responseData['durationInMinutes'] as int? ?? 0,
                remainingDailyGoalMinutes:
                    responseData['remainingDailyGoalMinutes'] as int? ?? 0,
                remainingWeeklyGoalDays:
                    responseData['remainingWeeklyGoalDays'] as int? ?? 0,
                personalDailyGoal:
                    responseData['personalDailyGoal'] as int? ?? 0,
                personalWeeklyGoal:
                    responseData['personalWeeklyGoal'] as int? ?? 0,
              ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기록 저장에 실패하였습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('기록', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton('시작', _startTimer),
                      const SizedBox(width: 12),
                      _buildActionButton('일시정지', _pauseTimer),
                      const SizedBox(width: 12),
                      _buildActionButton('완료', _completeTimer),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE3F2FD),
        foregroundColor: const Color(0xFF1976D2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF1976D2)),
        ),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
