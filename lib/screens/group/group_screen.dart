import 'package:capstone/screens/group/group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:capstone/screens/group/group_create_screen.dart';
import 'package:capstone/services/group_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer';

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
    // FAB 애니메이션 컨트롤러 설정
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

  /// FAB 메뉴 토글 함수
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

  /// 검색 오버레이 실행 (오버레이 바깥 터치 시 닫힘)
  void _showSearchOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      builder: (context) {
        return Stack(
          children: [
            // 화면 전체를 뒤덮는 투명 컨테이너
            // 이 영역을 탭하면 bottomSheet가 닫힘
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),

            // 아래쪽에 붙는 DraggableScrollableSheet
            Align(
              alignment: Alignment.bottomCenter,
              child: SearchOverlay(), // <-- 기존 SearchOverlay 위젯
            ),
          ],
        );
      },
    );
  }

  /// 그룹 목록 불러오기
  Future<void> fetchUserGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> groups = await GroupService.fetchUserGroups();

      if (!mounted) return;
      setState(() {
        _userGroups = groups;
      });

      if (_userGroups.isEmpty) {
        _showSnackBar("가입된 그룹이 없습니다.");
      }
    } catch (e) {
      _showSnackBar("그룹 정보를 불러오는데 실패했습니다: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 스낵바 메시지 표시
  void _showSnackBar(String message) {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
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
                itemBuilder: (context, index) {
                  final group = _userGroups[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(
                        group['groupName'] ?? "알 수 없는 그룹",
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("리더 : ${group['leaderName'] ?? "알 수 없음"}"),
                          Text("카테고리 : ${group['category'] ?? "알 수 없음"}"),
                          Text("그룹 포인트 : ${group['groupPoint'] ?? 0}"),
                          if (group['hashtag'] != null &&
                              group['hashtag'] is List &&
                              (group['hashtag'] as List).isNotEmpty)
                            Text(
                              "해시태그: ${(group['hashtag'] as List).join(', ')}",
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    GroupDetailPage(groupId: group['groupId']),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
              : const Center(child: Text("가입된 그룹이 없습니다.")),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isFabExpanded) ...[
            FloatingActionButton(
              heroTag: "search_fab",
              backgroundColor: const Color.fromARGB(255, 192, 143, 200),
              onPressed: () {
                _showSearchOverlay(); // 검색 오버레이 실행
                _toggleFabMenu();
              },
              child: const Icon(Icons.search),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: "create_fab",
              backgroundColor: const Color.fromARGB(255, 192, 143, 200),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupCreatePage(),
                  ),
                ).then((result) {
                  if (result == true) {
                    fetchUserGroups();
                  }
                });
                _toggleFabMenu();
              },
              child: const Icon(Icons.add),
            ),
          ],
          FloatingActionButton(
            heroTag: "main_fab",
            backgroundColor: Colors.purple,
            onPressed: _toggleFabMenu,
            child: Icon(_isFabExpanded ? Icons.close : Icons.add),
          ),
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
  String _selectedCategory = "STUDY";
  List<dynamic> _groups = [];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  /// 선택된 카테고리에 해당하는 그룹 데이터를 불러옴
  void _fetchGroups() async {
    try {
      final groups = await GroupService.fetchCategoryGroup(_selectedCategory);
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
              // 검색 텍스트필드와 검색(확인) 버튼
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "그룹명을 입력하세요...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // 추후 검색 기능 구현 예정
                    },
                    child: const Text("검색"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 가로 정렬된 카테고리 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _categoryButton("STUDY"),
                  _categoryButton("FITNESS"),
                  _categoryButton("READING"),
                ],
              ),
              const SizedBox(height: 16),
              // 그룹 리스트 표시
              Expanded(
                child:
                    _groups.isEmpty
                        ? const Center(child: Text("그룹이 없습니다."))
                        : ListView.builder(
                          controller: scrollController,
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            final group = _groups[index];
                            return Card(
                              child: ListTile(
                                title: Text(group['groupName'] ?? "알 수 없는 그룹"),
                                subtitle: Text(
                                  "리더: ${group['leaderName'] ?? '알 수 없음'}",
                                ),
                                onTap: () {
                                  // 그룹 상세 화면으로 이동
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
        backgroundColor:
            isSelected ? const Color.fromARGB(255, 188, 131, 198) : Colors.grey,
      ),
      onPressed: () => _onCategorySelected(category),
      child: Text(category),
    );
  }
}
