import 'package:flutter/material.dart';
import 'package:capstone/models/ranking.dart';
import 'package:capstone/services/ranking_service.dart';
import 'dart:developer';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _isLoading = true;
  List<RankingGroup> _rankingGroups = [];
  RankingPageInfo? _pageInfo;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      log('🔍 랭킹 데이터 로드 시작 - 페이지: $_currentPage');
      final result = await RankingService.getRankings(_currentPage);

      setState(() {
        _rankingGroups = result['rankingGroups'] as List<RankingGroup>;
        _pageInfo = result['pageInfo'] as RankingPageInfo?;
        _isLoading = false;
      });

      log('✅ 랭킹 데이터 로드 완료: ${_rankingGroups.length}개 항목');
    } catch (e) {
      log('❌ 랭킹 데이터 로드 오류: $e');
      setState(() {
        _error = '랭킹 정보를 불러올 수 없습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_pageInfo != null && !_pageInfo!.isLast) {
      setState(() {
        _currentPage++;
      });
      _loadRankings();
    }
  }

  void _previousPage() {
    if (_pageInfo != null && !_pageInfo!.isFirst) {
      setState(() {
        if (_currentPage > 0) _currentPage--;
      });
      _loadRankings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('랭킹'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRankings,
            tooltip: '새로고침',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadRankings,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadRankings,
                child: Column(
                  children: [
                    // 상위 3개 그룹 단상
                    _buildPodium(),

                    // 나머지 목록
                    Expanded(
                      child:
                          _rankingGroups.length <= 3
                              ? const Center(child: Text('더 이상 표시할 그룹이 없습니다.'))
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                itemCount:
                                    _rankingGroups.length > 3
                                        ? _rankingGroups.length - 3
                                        : 0,
                                itemBuilder: (context, index) {
                                  // 4등부터 표시 (인덱스에 3을 더해 실제 그룹 인덱스를 계산)
                                  final rankingIndex = index + 3;
                                  final group = _rankingGroups[rankingIndex];
                                  return _buildRankingItem(group);
                                },
                              ),
                    ),

                    // 페이지 네비게이션
                    if (_pageInfo != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed:
                                  _pageInfo!.isFirst ? null : _previousPage,
                              color:
                                  _pageInfo!.isFirst
                                      ? Colors.grey
                                      : Colors.blue,
                            ),
                            Text(
                              '${_pageInfo!.pageNumber + 1} / ${_pageInfo!.totalPages}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _pageInfo!.isLast ? null : _nextPage,
                              color:
                                  _pageInfo!.isLast ? Colors.grey : Colors.blue,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPodium() {
    // 상위 3개 그룹이 없는 경우 처리 - 이제 더미 데이터로 대체되므로 이 조건은 거의 발생하지 않음
    if (_rankingGroups.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('랭킹 정보를 불러오는 중입니다...')),
      );
    }

    // 각 순위별 그룹 (2등, 1등, 3등 순서로 배치)
    List<Widget> podiumItems = [];

    // 최대 3개 그룹만 추출
    List<RankingGroup> top3 =
        _rankingGroups.length < 3
            ? _rankingGroups
            : _rankingGroups.sublist(0, 3);

    // API에서 받은 순서대로 1, 2, 3등을 할당
    RankingGroup? first, second, third;

    if (top3.isNotEmpty) first = top3[0];
    if (top3.length >= 2) second = top3[1];
    if (top3.length >= 3) third = top3[2];

    // 단상 높이 설정
    const firstHeight = 120.0;
    const secondHeight = 100.0;
    const thirdHeight = 80.0;

    // 2등 단상
    if (second != null) {
      podiumItems.add(_buildPodiumItem(second, secondHeight, 2));
    } else {
      podiumItems.add(SizedBox(width: 100, height: secondHeight));
    }

    // 1등 단상
    if (first != null) {
      podiumItems.add(_buildPodiumItem(first, firstHeight, 1));
    } else {
      podiumItems.add(SizedBox(width: 100, height: firstHeight));
    }

    // 3등 단상
    if (third != null) {
      podiumItems.add(_buildPodiumItem(third, thirdHeight, 3));
    } else {
      podiumItems.add(SizedBox(width: 100, height: thirdHeight));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: podiumItems,
      ),
    );
  }

  Widget _buildPodiumItem(RankingGroup group, double height, int position) {
    Color medalColor;

    switch (position) {
      case 1:
        medalColor = Colors.amber; // 금메달
        break;
      case 2:
        medalColor = Colors.grey.shade300; // 은메달
        break;
      case 3:
        medalColor = Colors.brown.shade300; // 동메달
        break;
      default:
        medalColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 그룹 이름과 포인트
          Text(
            group.groupName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            '${group.groupPoint}점',
            style: TextStyle(
              fontSize: 12,
              color: group.groupPoint > 0 ? Colors.blue : Colors.grey,
              fontWeight:
                  group.groupPoint > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),

          // 메달 - 실제 서버에서 받은 랭킹을 표시
          CircleAvatar(
            radius: 20,
            backgroundColor: medalColor,
            child: Text(
              '${group.ranking}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 단상 - 순위와 포인트가 같은 경우를 대응하기 위한 단상 위치 구분
          Container(
            width: 100,
            height: height,
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                position == group.ranking
                    ? '$position위'
                    : '${group.ranking}위 (${position == 1
                        ? '금'
                        : position == 2
                        ? '은'
                        : '동'})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(RankingGroup group) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(child: Text('${group.ranking}')),
        title: Text(group.groupName),
        subtitle: Text('${group.groupPoint} 포인트'),
        trailing: _getRankingIcon(group.ranking),
      ),
    );
  }

  Widget? _getRankingIcon(int ranking) {
    if (ranking <= 10) {
      return const Icon(Icons.star, color: Colors.amber);
    }
    return null;
  }
}
