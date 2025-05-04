import 'package:flutter/material.dart';
import 'package:capstone/services/ranking_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  int currentPage = 1;
  RankingPageResponse? rankingData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRanking(1);
  }

  Future<void> loadRanking(int page) async {
    if (page < 1 ||
        (rankingData != null && page > rankingData!.pageInfo.totalPages)) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await RankingService.fetchRanking(page);
      setState(() {
        currentPage = page;
        rankingData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("랭킹 데이터를 불러오는데 실패했습니다: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (rankingData == null) {
      return const Center(child: Text("데이터를 불러올 수 없습니다."));
    }

    final podium = rankingData!.items.where((e) => e.ranking <= 3).toList();
    final others = rankingData!.items.where((e) => e.ranking > 3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('🏆 그룹 랭킹'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildPodium(podium),
          const Divider(height: 32),
          Expanded(child: _buildRankingList(others)),
          const SizedBox(height: 12),
          _buildPagination(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPodium(List<RankingItem> podium) {
    if (podium.length < 3) return const SizedBox();

    final first = podium.firstWhere(
      (e) => e.ranking == 1,
      orElse: () => podium[0],
    );
    final second = podium.firstWhere(
      (e) => e.ranking == 2,
      orElse: () => podium[1],
    );
    final third = podium.firstWhere(
      (e) => e.ranking == 3,
      orElse: () => podium[2],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatarPodium(third, 60, '🥉'),
          _buildAvatarPodium(first, 80, '👑'),
          _buildAvatarPodium(second, 70, '🥈'),
        ],
      ),
    );
  }

  Widget _buildAvatarPodium(RankingItem item, double size, String emoji) {
    return Column(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.shade300,
          child: Icon(Icons.group, size: size * 0.6, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  item.groupName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          "${item.groupPoint}점",
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildRankingList(List<RankingItem> others) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: others.length,
      itemBuilder: (context, index) {
        final item = others[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                "${item.ranking}",
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                const Icon(Icons.group, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.groupName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 18, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  "${item.groupPoint}점",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      children: List.generate(rankingData!.pageInfo.totalPages, (index) {
        final isSelected = index + 1 == currentPage;
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blueAccent : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => loadRanking(index + 1),
          child: Text("${index + 1}"),
        );
      }),
    );
  }
}
