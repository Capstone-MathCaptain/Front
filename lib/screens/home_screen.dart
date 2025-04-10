import 'package:capstone/screens/group/group_screen.dart';
import 'package:capstone/screens/recruitment/recruitment_screen.dart';
import 'package:capstone/screens/ranking/ranking_screen.dart';
import 'package:capstone/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1) 스낵바 표시를 위한 GlobalKey
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // 2) GroupPage의 state에 직접 접근하기 위한 GlobalKey
  final GlobalKey<GroupPageState> _groupPageKey = GlobalKey<GroupPageState>();

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    // 만약 이미 "그룹" 탭(index=0)에 있는데 또 누르면, 그룹 페이지를 새로고침
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
        // IndexedStack으로 탭 전환 시 상태 유지
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // GroupPage에 key 전달
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
          backgroundColor: Colors.black,
          selectedItemColor: const Color.fromARGB(255, 142, 3, 3),
          unselectedItemColor: Colors.grey,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.group), label: '그룹'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: '랭킹'),
            BottomNavigationBarItem(icon: Icon(Icons.person_add), label: '모집'),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: '프로필',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
