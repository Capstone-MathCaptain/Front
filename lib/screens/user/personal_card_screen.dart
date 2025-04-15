import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class PersonalCardScreen extends StatefulWidget {
  final int durationInMinutes;
  final int remainingDailyGoalMinutes;
  final int remainingWeeklyGoalDays;
  final int personalDailyGoal;
  final int personalWeeklyGoal;

  const PersonalCardScreen({
    super.key,
    required this.durationInMinutes,
    required this.remainingDailyGoalMinutes,
    required this.remainingWeeklyGoalDays,
    required this.personalDailyGoal,
    required this.personalWeeklyGoal,
  });

  @override
  State<PersonalCardScreen> createState() => _PersonalCardScreenState();
}

class _PersonalCardScreenState extends State<PersonalCardScreen> {
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    _loadHtmlContent();
  }

  Future<void> _loadHtmlContent() async {
    String htmlContent = await rootBundle.loadString(
      'assets/html/personal_card.html',
    );

    final dailyGoal = widget.personalDailyGoal;
    final dailyCompleted = widget.durationInMinutes;
    final dailyPercentage =
        dailyGoal > 0 ? (dailyCompleted / dailyGoal * 100).round() : 0;

    final weeklyGoal = widget.personalWeeklyGoal;
    final completedWeeklyDays = weeklyGoal - widget.remainingWeeklyGoalDays;
    final weeklyPercentage =
        weeklyGoal > 0 ? (completedWeeklyDays / weeklyGoal * 100).round() : 0;

    String formatTimeFromMinutes(int minutes) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';
    }

    final dailyCompletedFormatted = formatTimeFromMinutes(dailyCompleted);
    final dailyGoalFormatted = formatTimeFromMinutes(dailyGoal);

    htmlContent = htmlContent
        .replaceAll('{{DAILY_COMPLETED}}', dailyCompletedFormatted)
        .replaceAll('{{DAILY_GOAL}}', dailyGoalFormatted)
        .replaceAll('{{DAILY_PERCENTAGE}}', dailyPercentage.toString())
        .replaceAll(
          '{{REMAINING_DAILY_GOAL}}',
          widget.remainingDailyGoalMinutes.toString(),
        )
        .replaceAll('{{WEEKLY_PERCENTAGE}}', weeklyPercentage.toString())
        .replaceAll(
          '{{REMAINING_WEEKLY_GOAL}}',
          widget.remainingWeeklyGoalDays.toString(),
        );

    setState(() {
      _htmlContent = htmlContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('개인 카드'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Container(
          // 화면의 95%를 사용하고, 충분한 너비를 보장
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            //html
          ),
        ),
      ),
    );
  }
}
