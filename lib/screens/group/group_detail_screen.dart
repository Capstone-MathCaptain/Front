import 'package:flutter/material.dart';
import 'package:capstone/services/api_helper.dart';
import 'dart:developer';
import 'package:capstone/services/record_service.dart';
import 'package:capstone/services/group_service.dart';
import 'package:capstone/screens/group/record_screen.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  GroupDetailPageState createState() => GroupDetailPageState();
}

class GroupDetailPageState extends State<GroupDetailPage> {
  late Future<Map<String, dynamic>> _groupDetails;
  late Future<List<dynamic>> _groupMembers;
  bool _isMemberListVisible = false;

  //간단한 페이드 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _groupDetails = _loadGroupDetails();
    _groupMembers = _loadGroupMembers();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadGroupDetails() async {
    try {
      final groupData = await GroupService.fetchGroupDetails(widget.groupId);
      log('$groupData');
      return groupData;
    } catch (e) {
      log("❌ 그룹 세부 정보를 불러오는데 실패했습니다: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> _loadGroupMembers() async {
    try {
      final members = await GroupService.fetchGroupMembers(widget.groupId);
      return members;
    } catch (e) {
      log("❌ 그룹 멤버 정보를 불러오는데 실패했습니다: $e");
      return [];
    }
  }

  double _calculateWeeklyProgress(List<dynamic> members) {
    if (members.isEmpty) return 0.0;
    int totalMembers = members.length;
    double individualMaxContribution = 100 / totalMembers;
    double totalProgress = 0.0;
    for (var member in members) {
      double weeklyGoal = (member['userWeeklyGoal'] as num).toDouble();
      double currentProgress = (member['currentProgress'] as num).toDouble();
      double ratio = currentProgress / weeklyGoal;
      if (ratio > 1) ratio = 1;
      totalProgress += ratio;
    }
    return individualMaxContribution * totalProgress;
  }

  /// 잔디밭 색상 (초록 계열 예시; 원하는 색상으로 수정 가능)
  Color getIntensityColor(double percentage) {
    if (percentage == 0) {
      return const Color(0xFFEBEDF0);
    } else if (percentage <= 25) {
      return const Color(0xFF9BE9A8);
    } else if (percentage <= 50) {
      return const Color(0xFF40C463);
    } else if (percentage <= 75) {
      return const Color(0xFF30A14E);
    } else {
      return const Color(0xFF216E39);
    }
  }

  /// 멤버 목록 오버레이 (이전처럼 전체 화면 중앙에 뜨게 함)
  Widget _buildMemberList(BuildContext context, List<dynamic> members) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMemberListVisible = false;
        });
      },
      child: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.5),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isMemberListVisible = false;
                        });
                      },
                    ),
                  ],
                ),
                const Text(
                  "그룹원 목록",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(member['userName'] ?? '알 수 없는 사용자'),
                          subtitle: Text(
                            "주간 목표: ${member['userWeeklyGoal'] ?? 0}일",
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 그룹 프로필 카드 (잔디밭과 게이지를 카드 내부에 자연스럽게 통합)
  Widget _buildGroupProfileCard(Map<String, dynamic> groupData) {
    final groupName = groupData["groupName"] ?? "이름 없음";
    final groupRanking = groupData["groupRanking"] ?? 0;
    final category = groupData["category"] ?? "알 수 없음";
    final hashtags =
        groupData["hashtags"] is List ? (groupData["hashtags"] as List) : [];
    final memberCount = groupData["memberCount"] ?? 0;
    final groupPoint = groupData["groupPoint"] ?? 0;
    final weeklyGoalAchieve =
        (groupData["weeklyGoalAchieve"] ?? {}) as Map<String, dynamic>;
    final List<String> days = [
      "MONDAY",
      "TUESDAY",
      "WEDNESDAY",
      "THURSDAY",
      "FRIDAY",
      "SATURDAY",
      "SUNDAY",
    ];
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFB39DDB), Color(0xFFE1BEE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단: 그룹 이름과 랭킹
                  SizedBox(
                    height: 40,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            groupName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "랭킹 #$groupRanking",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 중간: 그룹 기본 정보
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.category,
                            size: 20,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "카테고리: $category",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.tag,
                            size: 20,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              hashtags.isNotEmpty
                                  ? "해시태그: ${hashtags.join(', ')}"
                                  : "해시태그: 없음",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 20,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "총 인원: $memberCount",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 20,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "그룹 포인트: $groupPoint",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white54, height: 32),
                  // 하단: 잔디밭과 1주 목표 달성률 게이지 (배경 없음)
                  Column(
                    children: [
                      // 잔디밭
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              days.map((day) {
                                int achieved = weeklyGoalAchieve[day] ?? 0;
                                double percentage =
                                    memberCount > 0
                                        ? (achieved / memberCount) * 100
                                        : 0;
                                Color boxColor = getIntensityColor(percentage);
                                return Column(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: boxColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      day.substring(0, 3),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 1주 목표 달성률 게이지
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FutureBuilder<List<dynamic>>(
                          future: _groupMembers,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return const Center(
                                child: Text(
                                  "멤버 정보를 불러오는 중 오류 발생",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            } else {
                              double weeklyProgress = _calculateWeeklyProgress(
                                snapshot.data!,
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    "1주 목표 달성률",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Color.fromRGBO(
                                            235,
                                            14,
                                            14,
                                            0.494,
                                          ),
                                        ),
                                      ),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: weeklyProgress / 100,
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue.shade600,
                                              ),
                                          minHeight: 12,
                                        ),
                                      ),
                                      Positioned(
                                        child: Text(
                                          "${weeklyProgress.toStringAsFixed(1)}% / 100%",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 전체 레이아웃을 Stack으로 감싸서 멤버 오버레이가 위에 뜨도록 함
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _groupDetails,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("데이터를 불러오는 중 오류 발생"));
              } else {
                final groupData = snapshot.data!;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // 스크롤 가능한 메인 콘텐츠
                        SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // 그룹 프로필 카드가 전체 높이의 90% 정도를 차지
                                  Expanded(
                                    child: _buildGroupProfileCard(groupData),
                                  ),
                                  // 하단 버튼 영역 (인증하기, 멤버 버튼)
                                  SizedBox(
                                    height: 80,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => RecordScreen(
                                                      groupId: widget.groupId,
                                                    ),
                                              ),
                                            ); // 인증하기 버튼 동작
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFB39DDB,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            "인증하기",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isMemberListVisible =
                                                  !_isMemberListVisible;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[400],
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.people,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            "멤버",
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 멤버 목록 오버레이 (멤버 버튼 클릭 시)
                        if (_isMemberListVisible)
                          FutureBuilder<List<dynamic>>(
                            future: _groupMembers,
                            builder: (context, membersSnapshot) {
                              if (membersSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (membersSnapshot.hasError) {
                                return const Center(
                                  child: Text("멤버 정보를 불러오는 중 오류 발생"),
                                );
                              } else {
                                return _buildMemberList(
                                  context,
                                  membersSnapshot.data!,
                                );
                              }
                            },
                          ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
