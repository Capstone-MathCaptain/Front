import 'package:capstone/screens/group/group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:capstone/screens/group/group_create_screen.dart';
import 'package:capstone/services/group_service.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupPage extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const GroupPage({
    super.key,
    required this.scaffoldMessengerKey,
  });

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
      _showSnackBar("그룹 정보를 불러오지 못했습니다: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 검색 다이얼로그 표시
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("그룹 검색"),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: "검색어 입력"),
          onSubmitted: (query) {
            Navigator.pop(context);
            _searchGroups(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchGroups(_searchController.text);
            },
            child: const Text("검색"),
          ),
        ],
      ),
    );
  }

  /// 그룹 검색 (API 호출)
  Future<void> _searchGroups(String query) async {
    if (query.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> searchResults =
          await GroupService.searchGroups(query: query);
      if (!mounted) return;
      setState(() {
        _userGroups = searchResults;
      });

      if (_userGroups.isEmpty) {
        _showSnackBar("검색 결과가 없습니다.");
      }
    } catch (e) {
      _showSnackBar("검색 중 오류 발생: $e");
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
      appBar: AppBar(
        title: const Text("내 그룹"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userGroups.isNotEmpty
              ? ListView.builder(
                  itemCount: _userGroups.length,
                  itemBuilder: (context, index) {
                    final group = _userGroups[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
                            Text("리더: ${group['leaderName'] ?? '알 수 없음'}"),
                            Text("카테고리: ${group['category'] ?? '알 수 없음'}"),
                            Text("그룹 포인트: ${group['groupPoint'] ?? 0}"),
                            if (group['hashtags'] != null &&
                                group['hashtags'] is List &&
                                (group['hashtags'] as List).isNotEmpty)
                              Text(
                                "해시태그: ${(group['hashtags'] as List).join(', ')}",
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GroupDetailPage(groupId: group['groupId']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                )
              : const Center(child: Text("가입된 그룹이 없습니다.")),
      floatingActionButton: SizedBox(
        width: 60, // FAB 펼쳤을 때 필요한 너비
        height: 220, // FAB 펼쳤을 때 필요한 높이(간격에 따라 조절)
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomRight,
          children: [
            // ─────────────────────────────────────
            // 1) 그룹 생성 버튼 (+ 아이콘)
            // ─────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              // 메인 FAB(아래)보다 2단계 위로
              bottom: _isFabExpanded ? 156 : 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isFabExpanded ? 1.0 : 0.0,
                child: FloatingActionButton(
                  heroTag: "create_fab",
                  backgroundColor: Colors.purple.shade400,
                  onPressed: () async {
                    // 그룹 생성 페이지로 이동
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GroupCreatePage(),
                      ),
                    );
                    // 이동 후 FAB 메뉴 닫기
                    _toggleFabMenu();
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),

            // ─────────────────────────────────────
            // 2) 검색 버튼 (돋보기 아이콘)
            // ─────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              // 메인 FAB(아래)보다 1단계 위로
              bottom: _isFabExpanded ? 86 : 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isFabExpanded ? 1.0 : 0.0,
                child: FloatingActionButton(
                  heroTag: "search_fab",
                  backgroundColor: Colors.purple.shade300,
                  onPressed: () {
                    _showSearchDialog();
                    _toggleFabMenu();
                  },
                  child: const Icon(Icons.search),
                ),
              ),
            ),

            // ─────────────────────────────────────
            // 3) 메인 FAB (플러스 → X 회전)
            // ─────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    // 0 ~ 45도(π/4) 회전
                    angle: _animationController.value * (3.14 / 4),
                    child: FloatingActionButton(
                      heroTag: "main_fab",
                      backgroundColor: Colors.purple,
                      onPressed: _toggleFabMenu,
                      child: const Icon(Icons.add),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
