import 'dart:async';
import 'package:capstone/screens/user/personal_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:capstone/services/record_service.dart';
import 'package:capstone/screens/user/personal_card_overlay.dart';

class RecordScreen extends StatefulWidget {
  final int groupId;

  const RecordScreen({super.key, required this.groupId});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _startTime;
  DateTime? _endTime;

  void _startTimer() {
    if (_isRunning) return;
    _startTime = DateTime.now();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _completeTimer() async {
    _pauseTimer();
    _endTime = DateTime.now();
    int minutes = _seconds ~/ 60; // 초 -> 분
    final responseData = await RecordService.sendRecordTime(
      widget.groupId,
      minutes,
      _startTime!.toIso8601String(),
      _endTime!.toIso8601String(),
    );
    if (!mounted) return;

    // 성공적으로 응답을 받으면 타이머 초기화
    setState(() {
      _seconds = 0;
      _startTime = null;
      _endTime = null;
    });

    if (responseData != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent, // 배경을 어둡게
        builder:
            (context) => PersonalCardOverlay(
              durationInMinutes: responseData['durationInMinutes'],
              remainingDailyGoalMinutes:
                  responseData['remainingDailyGoalMinutes'],
              remainingWeeklyGoalDays: responseData['remainingWeeklyGoalDays'],
              personalDailyGoal: responseData['personalDailyGoal'],
              personalWeeklyGoal: responseData['personalWeeklyGoal'],
            ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('기록 저장에 실패하였습니다')));
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
      appBar: AppBar(title: const Text('기록')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_seconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _startTimer, child: const Text('시작')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _pauseTimer,
                  child: const Text('일시정지'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _completeTimer,
                  child: const Text('완료'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
