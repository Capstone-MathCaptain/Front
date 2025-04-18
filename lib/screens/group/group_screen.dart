import 'package:capstone/screens/group/group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:capstone/screens/group/group_create_screen.dart';
import 'package:capstone/services/group_service.dart';
import 'dart:developer';

class GroupPage extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const GroupPage({super.key, required this.scaffoldMessengerKey});

  @override
  GroupPageState createState() => GroupPageState();
}

class SearchOverlay extends StatelessWidget {
  const SearchOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(child: Text('🔍 Search Overlay Placeholder')),
    );
  }
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
            Align(
              alignment: Alignment.bottomCenter,
              child: const SearchOverlay(),
            ),
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
                          children:
                              (group['hashtags'] as List<dynamic>)
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
      appBar: AppBar(title: const Text("내 그룹")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userGroups.isNotEmpty
              ? ListView.builder(
                itemCount: _userGroups.length,
                itemBuilder:
                    (context, index) => _buildGroupCard(_userGroups[index]),
              )
              : const Center(child: Text("가입된 그룹이 없습니다.")),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end, // 오른쪽 정렬 명확하게
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
            const SizedBox(height: 18), // ✅ 간격 넉넉하게
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
            const SizedBox(height: 24), // ✅ X 버튼과는 더 넉넉히!
          ],
          FloatingActionButton(
            heroTag: "main_fab",
            backgroundColor: const Color(0xFFE0F2F1),
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
          const SizedBox(height: 12), // 혹시 하단 여백
        ],
      ),
    );
  }
}
