import 'package:capstone/screens/group/group_screen.dart';
import 'package:capstone/screens/recruitment/recruitment_screen.dart';
import 'package:capstone/screens/ranking/ranking_screen.dart';
import 'package:capstone/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:capstone/services/notification_icon.dart'; // ✅ 알림 아이콘 import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<GroupPageState> _groupPageKey = GlobalKey<GroupPageState>();

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (_selectedIndex == index && index == 0) {
      _groupPageKey.currentState?.fetchUserGroups();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(241, 250, 250, 250),
        appBar: AppBar(
          title: const Text('의지박약'),
          backgroundColor: const Color.fromARGB(241, 250, 250, 250),
          elevation: 0,
          actions: const [
            NotificationIcon(), // ✅ 종 아이콘
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            GroupPage(
              key: _groupPageKey,
              scaffoldMessengerKey: _scaffoldMessengerKey,
            ),
            const RankingScreen(),
            const RecruitmentListScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(241, 250, 250, 250),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.group), label: '그룹'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: '랭킹'),
            BottomNavigationBarItem(icon: Icon(Icons.person_add), label: '모집'),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}
