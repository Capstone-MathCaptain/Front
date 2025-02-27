import 'package:flutter/material.dart';
import 'package:capstone/services/api_services.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  GroupDetailPageState createState() => GroupDetailPageState();
}

class GroupDetailPageState extends State<GroupDetailPage> {
  late Future<Map<String, dynamic>> _groupDetails;
  bool _isMemberListVisible = false;

  @override
  void initState() {
    super.initState();
    _groupDetails = fetchGroupDetails(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _groupDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("데이터를 불러오는 중 오류 발생"));
          } else {
            var groupData = snapshot.data!;
            double weeklyProgress = _calculateWeeklyProgress(
              groupData['members'],
            );

            return Stack(
              children: [
                Column(
                  children: [
                    AppBar(
                      title: Text(groupData['groupName'] ?? "그룹 정보"),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.people),
                          onPressed: () {
                            setState(() {
                              _isMemberListVisible = !_isMemberListVisible;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: () {}, child: const Text("인증하기")),

                    const Spacer(),

                    // ✅ 1주 목표 달성률 UI 개선 (색상 강조, 진행률 표시)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: Color.fromRGBO(114, 112, 112, 0.298),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "1주 목표 달성률",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ✅ Progress Bar + 숫자 표기
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300], // ✅ 배경 색상 추가
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: weeklyProgress / 100,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue.shade600,
                                      ),
                                      minHeight: 25,
                                    ),
                                  ),
                                  Positioned(
                                    child: Text(
                                      "${weeklyProgress.toStringAsFixed(1)}% / 100%",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ✅ 그룹원 목록 UI 개선 (스크롤 가능하도록 수정)
                if (_isMemberListVisible)
                  _buildMemberList(context, groupData['members']),
              ],
            );
          }
        },
      ),
    );
  }

  // ✅ 그룹원 목록 UI 수정 (스크롤 가능하게 수정)
  Widget _buildMemberList(BuildContext context, List<dynamic> members) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMemberListVisible = false;
        });
      },
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.5), // 반투명 배경
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 250,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40), // ✅ 상단 여백 추가
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "그룹원 목록",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                ),

                const Divider(),

                // ✅ 스크롤 가능하게 `Expanded` + `ListView.builder` 적용
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              members[index]['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "주간 목표: ${members[index]['weekly_goal']}일",
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 1주 목표 달성률 계산 함수
  double _calculateWeeklyProgress(List<dynamic> members) {
    if (members.isEmpty) return 0.0;

    int totalMembers = members.length;
    double individualMaxContribution = 100 / totalMembers;
    double totalProgress = 0.0;

    for (var member in members) {
      double weeklyGoal = (member['weekly_goal'] as num).toDouble();
      double currentProgress = (member['current_progress'] as num).toDouble();

      double ratio = currentProgress / weeklyGoal;
      totalProgress += ratio;
    }
    return individualMaxContribution * totalProgress;
  }
}
