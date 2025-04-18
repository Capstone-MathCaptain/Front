import 'package:flutter/material.dart';
import 'package:capstone/services/group_service.dart';

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({super.key});

  @override
  GroupCreatePageState createState() => GroupCreatePageState();
}

class GroupCreatePageState extends State<GroupCreatePage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();

  String _selectedCategory = "STUDY";
  int minDailyHours = 1;
  int minWeeklyDays = 1;
  int leaderDailyGoal = 1;
  int leaderWeeklyGoal = 1;

  final List<String> _hashtags = [];

  /// 그룹 생성 API 요청
  Future<void> _createGroup() async {
    // 조건 검증: 그룹장 목표는 그룹원 목표보다 작으면 안됨.
    if (leaderDailyGoal < minDailyHours) {
      _showSnackBar("그룹장의 최소 하루 목표는 그룹원보다 같거나 커야 합니다.");
      return;
    }
    if (leaderWeeklyGoal < minWeeklyDays) {
      _showSnackBar("그룹장의 최소 주간 목표는 그룹원보다 같거나 커야 합니다.");
      return;
    }

    try {
      bool success = await GroupService.createGroup(
        groupName: _groupNameController.text.trim(),
        category: _selectedCategory,
        minDailyHours: minDailyHours,
        minWeeklyDays: minWeeklyDays,
        leaderDailyGoal: leaderDailyGoal,
        leaderWeeklyGoal: leaderWeeklyGoal,
        hashtags: _hashtags,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar("그룹이 성공적으로 생성되었습니다! (ID: $success)");
        Navigator.pop(context, true);
      } else {
        _showSnackBar("그룹 생성 실패");
      }
    } catch (e) {
      _showSnackBar("오류 발생: $e");
    }
  }

  /// 해시태그 추가 (최대 5개 제한)
  void _addHashtag(String value) {
    if (_hashtags.length >= 5) {
      _showSnackBar("해시태그는 최대 5개까지만 입력할 수 있습니다.");
      return;
    }
    if (value.isNotEmpty && !_hashtags.contains(value)) {
      setState(() {
        _hashtags.add(value);
        _hashtagsController.clear();
      });
    }
  }

  /// 해시태그 삭제
  void _removeHashtag(String tag) {
    setState(() {
      _hashtags.remove(tag);
    });
  }

  /// 스낵바 메시지 표시 함수
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "그룹 생성",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 그룹명
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: "그룹명",
                  prefixIcon: Icon(Icons.group, color: Colors.blueGrey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 카테고리
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "카테고리",
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: "STUDY",
                    child: Row(
                      children: const [
                        Icon(Icons.school, size: 18, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text("공부"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "FITNESS",
                    child: Row(
                      children: const [
                        Icon(
                          Icons.fitness_center,
                          size: 18,
                          color: Colors.blueAccent,
                        ),
                        SizedBox(width: 8),
                        Text("헬스"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "READING",
                    child: Row(
                      children: const [
                        Icon(
                          Icons.directions_run,
                          size: 18,
                          color: Colors.blueAccent,
                        ),
                        SizedBox(width: 8),
                        Text("러닝"),
                      ],
                    ),
                  ),
                ],
                onChanged:
                    (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              // 해시태그 입력
              TextField(
                controller: _hashtagsController,
                decoration: InputDecoration(
                  labelText: "해시태그 입력 (최대 5개)",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed:
                        () => _addHashtag(_hashtagsController.text.trim()),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) => _addHashtag(value.trim()),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8.0,
                children:
                    _hashtags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeHashtag(tag),
                        backgroundColor: Colors.grey[200],
                        labelStyle: const TextStyle(color: Colors.black87),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // 그룹원 최소 하루 목표 시간
              DropdownButtonFormField<int>(
                value: minDailyHours,
                decoration: const InputDecoration(
                  labelText: "그룹원 최소 하루 목표 시간",
                  border: OutlineInputBorder(),
                ),
                items:
                    List.generate(12, (index) => index + 1).map((hour) {
                      return DropdownMenuItem(
                        value: hour,
                        child: Text("$hour 시간"),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    minDailyHours = value!;
                    if (leaderDailyGoal < minDailyHours) {
                      leaderDailyGoal = minDailyHours;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // 그룹장 하루 목표
              DropdownButtonFormField<int>(
                value: leaderDailyGoal,
                decoration: const InputDecoration(
                  labelText: "그룹장 최소 하루 목표 시간",
                  border: OutlineInputBorder(),
                ),
                items:
                    List.generate(12, (index) => index + 1)
                        .where((hour) => hour >= minDailyHours)
                        .map(
                          (hour) => DropdownMenuItem(
                            value: hour,
                            child: Text("$hour 시간"),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => leaderDailyGoal = value!),
              ),
              const SizedBox(height: 16),

              // 주간 목표 일수
              DropdownButtonFormField<int>(
                value: minWeeklyDays,
                decoration: const InputDecoration(
                  labelText: "그룹원 최소 주간 목표 일수",
                  border: OutlineInputBorder(),
                ),
                items:
                    List.generate(7, (index) => index + 1).map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text("$day 일"),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    minWeeklyDays = value!;
                    if (leaderWeeklyGoal < minWeeklyDays) {
                      leaderWeeklyGoal = minWeeklyDays;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: leaderWeeklyGoal,
                decoration: const InputDecoration(
                  labelText: "그룹장 최소 주간 목표 일수",
                  border: OutlineInputBorder(),
                ),
                items:
                    List.generate(7, (index) => index + 1)
                        .where((day) => day >= minWeeklyDays)
                        .map(
                          (day) => DropdownMenuItem(
                            value: day,
                            child: Text("$day 일"),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => leaderWeeklyGoal = value!),
              ),
              const SizedBox(height: 24),

              // 그룹 생성 버튼
              Center(
                child: ElevatedButton.icon(
                  onPressed: _createGroup,
                  icon: const Icon(Icons.group_add),
                  label: const Text("그룹 생성"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
