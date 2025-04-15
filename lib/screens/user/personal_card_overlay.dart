import 'package:flutter/material.dart';

class PersonalCardOverlay extends StatelessWidget {
  final int durationInMinutes; // 기록된 활동시간 (분)
  final int remainingDailyGoalMinutes; // 남은 하루 목표 시간 (분)
  final int remainingWeeklyGoalDays; // 남은 주 목표 일수 (일)
  final int personalDailyGoal; // 하루 목표 시간 (분)
  final int personalWeeklyGoal; // 한 주 목표 일수 (일)

  const PersonalCardOverlay({
    super.key,
    required this.durationInMinutes,
    required this.remainingDailyGoalMinutes,
    required this.personalDailyGoal,
    required this.remainingWeeklyGoalDays,
    required this.personalWeeklyGoal,
  });

  // 분 단위의 시간을 "HH:MM" 형식으로 변환
  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 하루 진행률 계산 (0~1)
    double dailyPercentage =
        personalDailyGoal > 0 ? (durationInMinutes / personalDailyGoal) : 0;
    if (dailyPercentage > 1) dailyPercentage = 1;
    int dailyPercentInt = (dailyPercentage * 100).round();

    // 한 주 진행률 계산 (0~1)
    double weeklyPercentage =
        personalWeeklyGoal > 0
            ? ((personalWeeklyGoal - remainingWeeklyGoalDays) /
                personalWeeklyGoal)
            : 0;
    if (weeklyPercentage > 1) weeklyPercentage = 1;
    int weeklyPercentInt = (weeklyPercentage * 100).round();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 무지개 빛 테두리를 적용한 카드 디자인 영역
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade50, Colors.pink.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 상단 아이콘으로 성취감 강조
                      Icon(
                        Icons.check_circle_outline_sharp,
                        size: 40,
                        color: const Color.fromARGB(255, 64, 80, 255),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 64, 80, 255),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 하루 목표와 남은 목표를 카드 형식으로 표현
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.wb_sunny,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '하루 목표',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(personalDailyGoal),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.timelapse,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '남은 목표',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(remainingDailyGoalMinutes),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 한 주 목표와 남은 주 목표를 카드 형식으로 표현
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '한 주 목표',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$personalWeeklyGoal 일',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '남은 일수',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$remainingWeeklyGoalDays 일',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 하루 진행률을 보여주는 원형 프로그레스 인디케이터
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: dailyPercentage,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color.fromARGB(255, 64, 80, 255),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(durationInMinutes),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$dailyPercentInt%',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 하단 버튼 영역: 뒤로가기, 공유하기
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                              backgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('뒤로가기'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: 위젯 캡쳐 후 인스타그램 스토리(또는 피드) 공유 기능 구현
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('공유하기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 카드 내 정보 항목을 위한 위젯 (현재 사용되지 않음)
  Widget _buildInfoColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
