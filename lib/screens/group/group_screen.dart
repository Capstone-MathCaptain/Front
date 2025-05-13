import 'package:capstone/screens/group/group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:capstone/screens/group/group_create_screen.dart';
import 'package:capstone/services/group_service.dart';
import 'dart:developer';
import 'package:capstone/services/group_join_service.dart';

class GroupPage extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const GroupPage({super.key, required this.scaffoldMessengerKey});

  @override
  GroupPageState createState() => GroupPageState();
}

class GroupPageState extends State<GroupPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _userGroups = [];
  bool _isLoading = false;
  bool _isFabExpanded = false;

  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserGroups();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFabMenu() {
    if (_isFabExpanded) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
  }

  void _showSearchOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
            Align(alignment: Alignment.bottomCenter, child: SearchOverlay()),
          ],
        );
      },
    );
  }

  Future<void> fetchUserGroups() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<dynamic> groups = await GroupService.fetchUserGroups();
      if (!mounted) return;
      setState(() => _userGroups = groups);

      if (_userGroups.isEmpty) {
        _showSnackBar("가입된 그룹이 없습니다.");
      }
    } catch (e) {
      _showSnackBar("그룹 정보를 불러오는데 실패했습니다: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildGroupCard(dynamic group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailPage(groupId: group['groupId']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueGrey,
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 30),
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
                          group['category'] == '공부'
                              ? Icons.school
                              : group['category'] == '헬스'
                                  ? Icons.fitness_center
                                  : Icons.directions_run,
                          size: 16,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group['category'] ?? "카테고리 없음",
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.bolt,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text("하루 ${group['minDailyHours']}시간"),
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
                          label: Text("주간 ${group['minWeeklyDays']}일"),
                          backgroundColor: Colors.green,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    if (group['hashtags'] != null &&
                        group['hashtags'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: (group['hashtags'] as List<dynamic>)
                              .map<Widget>(
                                (tag) => Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black12,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("내 그룹 👥"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userGroups.isNotEmpty
              ? ListView.builder(
                  itemCount: _userGroups.length,
                  itemBuilder: (context, index) =>
                      _buildGroupCard(_userGroups[index]),
                )
              : const Center(child: Text("가입된 그룹이 없습니다.")),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            FloatingActionButton(
              heroTag: "search_fab",
              backgroundColor: const Color(0xFFEEF4FF),
              onPressed: () {
                _showSearchOverlay();
                _toggleFabMenu();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF5C6BC0)),
              ),
              child: const Icon(Icons.search, color: Color(0xFF5C6BC0)),
            ),
            const SizedBox(height: 18),
            FloatingActionButton(
              heroTag: "create_fab",
              backgroundColor: const Color(0xFFEEF4FF),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupCreatePage(),
                  ),
                ).then((result) {
                  if (result == true) fetchUserGroups();
                });
                _toggleFabMenu();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF5C6BC0)),
              ),
              child: const Icon(Icons.add, color: Color(0xFF5C6BC0)),
            ),
            const SizedBox(height: 24),
          ],
          FloatingActionButton(
            heroTag: "chat_fab",
            backgroundColor: const Color(0xFFFFF176),
            onPressed: () {
              Navigator.pushNamed(context, '/chat');
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.yellow),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 18),
          FloatingActionButton(
            heroTag: "main_fab",
            backgroundColor: Colors.white,
            onPressed: _toggleFabMenu,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF009688)),
            ),
            child: Icon(
              _isFabExpanded ? Icons.close : Icons.add,
              color: const Color(0xFF009688),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// 🔍 **검색 오버레이 위젯 (카테고리별 그룹 검색)**
class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  SearchOverlayState createState() => SearchOverlayState();
}

class SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "FITNESS"; // 기본 헬스
  List<dynamic> _groups = [];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  /// 선택된 카테고리에 해당하는 그룹 데이터를 불러옴
  void _fetchGroups() async {
    try {
      final groups = await GroupService.fetchGroups(
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      log("Error fetching groups: $e");
    }
  }

  /// 카테고리 버튼 클릭 시 동작
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _groups = [];
    });
    _fetchGroups();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 검색 텍스트필드와 검색 버튼 (흰색 블럭)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "그룹명을 입력하세요...",
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        // TODO: searchGroups 구현
                      },
                      child: const Text("검색"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 카테고리 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _categoryButton("STUDY"),
                  _categoryButton("FITNESS"),
                  _categoryButton("READING"),
                ],
              ),
              const SizedBox(height: 16),
              // 그룹 리스트
              Expanded(
                child: _groups.isEmpty
                    ? const Center(child: Text("그룹이 없습니다."))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(group['groupName'] ?? "알 수 없는 그룹"),
                              subtitle: Text(
                                "리더: ${group['leaderName'] ?? '알 수 없음'}",
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  int selectedDaily =
                                      group['minDailyHours'] as int;
                                  int selectedWeekly =
                                      group['minWeeklyDays'] as int;
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                        title: const Text(
                                          '가입 요청',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        content: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: StatefulBuilder(
                                            builder: (
                                              context,
                                              setDialogState,
                                            ) {
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  DropdownButtonFormField<int>(
                                                    value: selectedDaily,
                                                    decoration: InputDecoration(
                                                      labelText: '하루 목표 시간',
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10,
                                                        ),
                                                      ),
                                                    ),
                                                    items: List.generate(
                                                      24,
                                                      (i) => i + 1,
                                                    )
                                                        .map(
                                                          (
                                                            h,
                                                          ) =>
                                                              DropdownMenuItem(
                                                            value: h,
                                                            child: Text(
                                                              '$h 시간',
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (v) {
                                                      setDialogState(
                                                        () =>
                                                            selectedDaily = v!,
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 12),
                                                  DropdownButtonFormField<int>(
                                                    value: selectedWeekly,
                                                    decoration: InputDecoration(
                                                      labelText: '주간 목표 일수',
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10,
                                                        ),
                                                      ),
                                                    ),
                                                    items: List.generate(
                                                      7,
                                                      (i) => i + 1,
                                                    )
                                                        .map(
                                                          (
                                                            d,
                                                          ) =>
                                                              DropdownMenuItem(
                                                            value: d,
                                                            child: Text(
                                                              '$d 일',
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (v) {
                                                      setDialogState(
                                                        () =>
                                                            selectedWeekly = v!,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.black54,
                                            ),
                                            child: const Text('취소'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              try {
                                                bool success =
                                                    await GroupJoinService
                                                        .joinGroup(
                                                  groupId:
                                                      group['groupId'] as int,
                                                  request: GroupJoinRequest(
                                                    personalDailyGoal:
                                                        selectedDaily,
                                                    personalWeeklyGoal:
                                                        selectedWeekly,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '가입 요청을 전송했습니다',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '가입 요청 실패: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('전송'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text('가입'),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GroupDetailPage(
                                      groupId: group['groupId'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 카테고리 버튼 위젯
  Widget _categoryButton(String category) {
    final bool isSelected = _selectedCategory == category;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black54,
      ),
      onPressed: () => _onCategorySelected(category),
      child: Text(
        category == "FITNESS"
            ? "헬스"
            : category == "STUDY"
                ? "공부"
                : "러닝",
      ),
    );
  }
}
