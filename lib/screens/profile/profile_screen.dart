import 'package:flutter/material.dart';
import 'package:capstone/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileService.getProfile();
      setState(() {
        profileData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("프로필 데이터를 불러오는데 실패했습니다: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profileData == null) {
      return const Center(child: Text("데이터를 불러올 수 없습니다."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildGroupCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "이름: ${profileData!['userName']}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text("등급: ${profileData!['userTier']}"),
        Text("포인트: ${profileData!['userPoint']}"),
      ],
    );
  }

  Widget _buildGroupCards() {
    final groupCards = profileData!['groupCards'] as List<dynamic>;

    return Expanded(
      child: ListView.builder(
        itemCount: groupCards.length,
        itemBuilder: (context, index) {
          final group = groupCards[index];
          final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
          final fullDayMap = {
            'MON': 'MONDAY',
            'TUE': 'TUESDAY',
            'WED': 'WEDNESDAY',
            'THU': 'THURSDAY',
            'FRI': 'FRIDAY',
            'SAT': 'SATURDAY',
            'SUN': 'SUNDAY',
          };
          final koreanDayLabels = ['월', '화', '수', '목', '금', '토', '일'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.group, size: 40),
                    title: Text(group['groupName'] ?? '이름 없음'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("역할: ${group['groupRole'] ?? '-'}"),
                        Text("랭킹: ${group['groupRanking'] ?? '-'}"),
                        Text("점수: ${group['groupPoint'] ?? 0}"),
                        Text("일간 목표: ${group['userDailyGoal'] ?? 0}시간"),
                        Text("주간 목표: ${group['userWeeklyGoal'] ?? 0}일"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ 수행 여부 원 표시
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        days.map((day) {
                          final fullKey = fullDayMap[day]!;
                          final achieved =
                              group['userAchieve']?[fullKey] ?? false;

                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: achieved ? Colors.green : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 4),

                  // ✅ 요일 텍스트
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        koreanDayLabels.map((label) {
                          return Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
