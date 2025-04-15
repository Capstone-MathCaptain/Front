import 'package:flutter/material.dart';
import 'package:capstone/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileService.getProfile();
      setState(() {
        profileData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("프로필 데이터를 불러오는데 실패했습니다: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profileData == null) {
      return const Center(child: Text("데이터를 불러올 수 없습니다."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildGroupCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "이름: ${profileData!['userName']}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text("등급: ${profileData!['userTier']}"),
        Text("포인트: ${profileData!['userPoint']}"),
      ],
    );
  }

  Widget _buildGroupCards() {
    final groupCards = profileData!['groupCards'] as List<dynamic>;

    return Expanded(
      child: ListView.builder(
        itemCount: groupCards.length,
        itemBuilder: (context, index) {
          final group = groupCards[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Image.network(group['groupImageUrl']),
              title: Text(group['groupName']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("역할: ${group['groupRole']}"),
                  Text("랭킹: ${group['groupRanking']}"),
                  Text("점수: ${group['groupPoint']}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
