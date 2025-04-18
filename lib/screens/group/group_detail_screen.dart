import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:capstone/services/group_service.dart';
import 'package:capstone/screens/group/record_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  GroupDetailPageState createState() => GroupDetailPageState();
}

final ScrollController _memberScrollController = ScrollController();

class GroupDetailPageState extends State<GroupDetailPage>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _groupDetails;
  late Future<List<dynamic>> _groupMembers;
  bool _isMemberListVisible = false;

  //간단한 페이드 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    _groupDetails = _loadGroupDetails();
    _groupMembers = _loadGroupMembers();
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
      return const Color(0xFFBFDDE2); // 연한 회색-블루
    } else if (percentage <= 25) {
      return const Color(0xFFB4E6DF); // 연한 민트
    } else if (percentage <= 50) {
      return const Color(0xFF82DCD0); // 밝은 민트
    } else if (percentage <= 75) {
      return const Color(0xFF4FCBC1); // 중간 민트
    } else {
      return const Color(0xFF06D5CD); // 진한 민트 (메인 컬러)
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
        color: const Color.fromRGBO(0, 0, 0, 0.5), // 배경: 반투명 어둡게
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Scrollbar(
              thumbVisibility: true, // 항상 스크롤바 표시
              controller: _memberScrollController,
              radius: const Radius.circular(8),
              thickness: 6,
              child: SingleChildScrollView(
                controller: _memberScrollController,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 닫기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              setState(() {
                                _isMemberListVisible = false;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 제목
                      const Text(
                        "그룹원 목록",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: Colors.black26),

                      // 멤버 리스트
                      members.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                "그룹원이 없습니다.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final member = members[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.person,
                                    color: Colors.black87,
                                  ),
                                  title: Text(
                                    member['userName'] ?? '알 수 없는 사용자',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "주간 목표: ${member['userWeeklyGoal'] ?? 0}일",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
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
              colors: [Color(0xFF06D5CD), Color(0xFF3A86FF)],
              begin: AlignmentDirectional(1, 1),
              end: AlignmentDirectional(-1, -1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 그룹 이름 + 총 인원
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      groupName,
                      style: GoogleFonts.readexPro(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "인원 : $memberCount명",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 랭킹 & 포인트 강조
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.military_tech,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "랭킹 #$groupRanking",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, color: Colors.white70, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "포인트 $groupPoint",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 카테고리 / 해시태그 (infoChip)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoChip(Icons.category, "카테고리: $category"),
                    _buildInfoChip(
                      Icons.tag,
                      hashtags.isNotEmpty
                          ? "해시태그: ${hashtags.join(', ')}"
                          : "해시태그 없음",
                    ),
                  ],
                ),

                const Divider(color: Colors.white54, height: 32),

                // 잔디밭 시각화
                Row(
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

                const SizedBox(height: 24),

                // 1주 목표 달성률 게이지
                FutureBuilder<List<dynamic>>(
                  future: _groupMembers,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    double weeklyProgress = _calculateWeeklyProgress(
                      snapshot.data!,
                    );
                    return Column(
                      children: [
                        const Text(
                          "1주 목표 달성률",
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
                              height: 12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: const Color(0xFFE0E3E7),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: weeklyProgress / 100,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF06D5CD),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "${weeklyProgress.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                children: [
                                  // ✅ 뒤로가기 버튼과 타이틀
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios,
                                          color: Colors.black,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '상세 정보',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // 그룹 프로필 카드
                                  _buildGroupProfileCard(groupData),

                                  const Spacer(),

                                  // 하단 버튼
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
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF06D5CD,
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
                                            backgroundColor: const Color(
                                              0xFF3A86FF,
                                            ),
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
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "멤버",
                                            style: TextStyle(
                                              color: Colors.white,
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

                        // 멤버 오버레이
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
