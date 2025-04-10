import 'package:flutter/material.dart';
import 'package:capstone/models/profile.dart';
import 'package:capstone/services/profile_service.dart';
import 'dart:developer';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserProfile? _userProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      log('🔍 프로필 데이터 로드 시작');
      final userProfile = await ProfileService.getUserProfile();

      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });

      log('✅ 프로필 데이터 로드 완료');
    } catch (e) {
      log('❌ 프로필 데이터 로드 오류: $e');
      setState(() {
        _error = '프로필 정보를 불러올 수 없습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _userProfile == null
              ? const Center(child: Text('프로필 정보가 없습니다.'))
              : RefreshIndicator(
                onRefresh: _loadProfileData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사용자 정보 카드
                        _buildUserInfoCard(),

                        const SizedBox(height: 24),

                        // 그룹 카드 제목
                        Text(
                          '소속 그룹 (${_userProfile!.groupCards.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                        const SizedBox(height: 8),

                        // 그룹 카드 목록
                        _userProfile!.groupCards.isEmpty
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('소속된 그룹이 없습니다.'),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _userProfile!.groupCards.length,
                              itemBuilder: (context, index) {
                                return _buildGroupCard(
                                  _userProfile!.groupCards[index],
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildUserInfoCard() {
    // 티어 정보 가져오기
    final tierInfo = ProfileService.getTierInfo(_userProfile!.userTier);
    final tierColor = Color(
      int.parse(tierInfo['color']!.substring(1, 7), radix: 16) + 0xFF000000,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 사용자 아바타와 이름
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userProfile!.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            IconData(
                              0xe8e8, // Default shield icon
                              fontFamily: 'MaterialIcons',
                            ),
                            color: tierColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _userProfile!.userTier,
                            style: TextStyle(
                              color: tierColor,
                              fontWeight: FontWeight.bold,
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
            const Divider(),
            const SizedBox(height: 8),

            // 포인트 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '포인트',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_userProfile!.userPoint}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupCard card) {
    // 완료한 요일 수와 주간 목표 달성 비율
    final completedDays = card.getCompletedDays();
    final progressRate = card.getWeeklyProgressRate();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 그룹 이름과 역할
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    card.groupName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        card.groupRole == 'LEADER'
                            ? Colors.amber.shade100
                            : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.groupRole == 'LEADER' ? '리더' : '멤버',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          card.groupRole == 'LEADER'
                              ? Colors.orange.shade800
                              : Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 그룹 포인트와 랭킹
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${card.groupPoint} 포인트'),
                const SizedBox(width: 12),
                const Icon(Icons.leaderboard, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(card.groupRanking > 0 ? '${card.groupRanking}위' : '랭킹 없음'),
              ],
            ),

            const SizedBox(height: 16),

            // 주간 목표 진행 상황
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '주간 목표: $completedDays / ${card.userWeeklyGoal}일',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progressRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressRate >= 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 진행 바
            LinearProgressIndicator(
              value: progressRate,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressRate >= 1.0 ? Colors.green : Colors.blue,
              ),
            ),

            const SizedBox(height: 16),

            // 요일별 달성 상태
            _buildWeekdayStatus(card),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayStatus(GroupCard card) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          [
            'MONDAY',
            'TUESDAY',
            'WEDNESDAY',
            'THURSDAY',
            'FRIDAY',
            'SATURDAY',
            'SUNDAY',
          ].map((day) {
            final achieved = card.userAchieve[day] ?? false;
            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: achieved ? Colors.green : Colors.grey.shade300,
                  ),
                  child: Center(
                    child:
                        achieved
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ProfileService.getDayNameInKorean(day),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}
