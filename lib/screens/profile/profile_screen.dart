import 'package:flutter/material.dart';
import 'package:capstone/services/profile_service.dart';
import 'package:capstone/screens/group/group_detail_screen.dart';

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
            _buildUserInfo(profileData),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildGroupCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic>? profileData) {
    final userName = profileData?['userName'] ?? '이름 없음';
    final userTier = profileData?['userTier'] ?? '알 수 없음';
    final userPoint = profileData?['userPoint'] ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 프로필 이미지 (없으면 기본 아이콘)
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
          ),
          child: const Icon(Icons.person, size: 36, color: Colors.white),
        ),
        const SizedBox(width: 16),
        // 유저 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "티어: $userTier",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                "포인트: $userPoint",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // 설정 화면 이동 등
          },
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  Widget _buildGroupCards() {
    final groupCards = profileData!['groupCards'] as List<dynamic>;
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

    return Expanded(
      child: ListView.builder(
        itemCount: groupCards.length,
        itemBuilder: (context, index) {
          final group = groupCards[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => GroupDetailPage(groupId: group['groupId']),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 정보
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade300,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group['groupName'] ?? "알 수 없는 그룹",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${group['groupRanking'] ?? '-'}위",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    group['groupRole'] ?? "-",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.military_tech,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${group['groupPoint'] ?? 0} pts",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 목표 정보
                    Row(
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.bolt,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            "일간 목표: ${group['userDailyGoal'] ?? 0}시간",
                          ),
                          backgroundColor: Colors.blueAccent,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: Text(
                            "주간 목표: ${group['userWeeklyGoal'] ?? 0}일",
                          ),
                          backgroundColor: Colors.green,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 달성 점수 시각화
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final day = days[i];
                        final fullKey = fullDayMap[day]!;
                        final achieved =
                            group['userAchieve']?[fullKey] ?? false;
                        return Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    achieved ? Colors.green : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              koreanDayLabels[i],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
