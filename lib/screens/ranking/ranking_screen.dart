import 'package:flutter/material.dart';
import 'package:capstone/services/ranking_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  int currentPage = 0;
  RankingPageResponse? rankingData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRanking(currentPage);
  }

  Future<void> loadRanking(int page) async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await RankingService.fetchRanking(page);
      setState(() {
        currentPage = page;
        rankingData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("랭킹 데이터를 불러오는데 실패했습니다: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rankingData == null) {
      return const Center(child: Text("데이터를 불러올 수 없습니다."));
    }

    final podium = rankingData!.items.where((e) => e.ranking <= 3).toList();
    final others = rankingData!.items.where((e) => e.ranking > 3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('랭킹')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          _buildPodium(podium),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(child: _buildRankingList(others)),
          const SizedBox(height: 8),
          _buildPagination(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPodium(List<RankingItem> podium) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          podium.map((item) {
            return _PodiumCard(item: item);
          }).toList(),
    );
  }

  Widget _buildRankingList(List<RankingItem> others) {
    return ListView.builder(
      itemCount: others.length,
      itemBuilder: (context, index) {
        final item = others[index];
        return ListTile(
          leading: Text("${item.ranking}위"),
          title: Text(item.groupName),
          trailing: Text("${item.groupPoint}점"),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      children: List.generate(rankingData!.pageInfo.totalPages, (index) {
        final isSelected = index == currentPage;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
          ),
          onPressed: () => loadRanking(index),
          child: Text("${index + 1}"),
        );
      }),
    );
  }
}

// 🏅 단상 카드 위젯
class _PodiumCard extends StatelessWidget {
  final RankingItem item;

  const _PodiumCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final height = switch (item.ranking) {
      1 => 150.0,
      2 => 120.0,
      3 => 100.0,
      _ => 100.0,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 80,
      height: height,
      decoration: BoxDecoration(
        color: Colors.amber[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${item.ranking}등",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(item.groupName, textAlign: TextAlign.center),
          Text("${item.groupPoint}점"),
        ],
      ),
    );
  }
}
