import 'package:flutter/material.dart';
import 'package:capstone/services/record_service.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 추가
import 'dart:developer';

class MemoScreen extends StatefulWidget {
  final int groupId;
  final String category;
  final String startTime;
  final String endTime;
  final int activityTimeMinutes;

  const MemoScreen({
    super.key,
    required this.groupId,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.activityTimeMinutes,
  });

  @override
  MemoScreenState createState() => MemoScreenState();
}

class MemoScreenState extends State<MemoScreen> {
  final TextEditingController memoController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController distanceController = TextEditingController();
  final TextEditingController exerciseNameController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  List<Map<String, dynamic>> exerciseInfoList = [];
  List<Map<String, TextEditingController>> exerciseControllers = [];

  @override
  void initState() {
    super.initState();
    // 초기 exerciseInfoList 항목 생성
    if (widget.category == '헬스') {
      _addNewExercise(); // exerciseInfoList와 exerciseControllers 모두 추가
    }
  }

  // ISO 날짜 형식을 사용자 친화적인 형식으로 변환
  String formatDateTime(String isoString) {
    final DateTime dateTime = DateTime.parse(isoString);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('인증 정보 입력')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 공통 정보 표시
              Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '활동 요약',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '활동 시간: ${widget.activityTimeMinutes}분',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '시작 시간: ${formatDateTime(widget.startTime)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '종료 시간: ${formatDateTime(widget.endTime)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // 카테고리에 따라 다른 입력 필드 표시
              if (widget.category == '헬스')
                _buildFitnessFields()
              else if (widget.category == '러닝')
                _buildRunningFields()
              else if (widget.category == '공부')
                _buildStudyFields(),

              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _completeActivity,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFitnessFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '헬스 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),

            // 각 운동 정보 표시
            ...List.generate(exerciseInfoList.length, (index) {
              return _buildExerciseItem(index);
            }),

            // 운동 추가 버튼
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewExercise,
              icon: Icon(Icons.add),
              label: Text('exercise 추가하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(int index) {
    var controllers = exerciseControllers[index];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'exercise ${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              if (exerciseInfoList.length > 1) // 최소 하나의 운동은 유지
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeExercise(index),
                  tooltip: '이 exercise 삭제',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: 20,
                ),
            ],
          ),
          SizedBox(height: 10),
          TextField(
            controller: controllers['exerciseName'],
            decoration: InputDecoration(
              labelText: '운동 이름',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fitness_center),
            ),
            onChanged: (value) {
              setState(() {
                exerciseInfoList[index]['exerciseName'] = value;
              });
            },
          ),
          SizedBox(height: 8),
          TextField(
            controller: controllers['sets'],
            decoration: InputDecoration(
              labelText: '세트 수',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.repeat),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                exerciseInfoList[index]['sets'] = int.tryParse(value) ?? 0;
              });
            },
          ),
          SizedBox(height: 8),
          TextField(
            controller: controllers['reps'],
            decoration: InputDecoration(
              labelText: '반복 횟수',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.loop),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                exerciseInfoList[index]['reps'] = int.tryParse(value) ?? 0;
              });
            },
          ),
          SizedBox(height: 8),
          TextField(
            controller: controllers['weight'],
            decoration: InputDecoration(
              labelText: '무게 (kg)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.monitor_weight),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                exerciseInfoList[index]['weight'] = int.tryParse(value) ?? 0;
              });
            },
          ),
        ],
      ),
    );
  }

  void _addNewExercise() {
    // 각 필드에 대한 컨트롤러 생성
    final exerciseNameController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();

    // 컨트롤러 리스트에 추가
    exerciseControllers.add({
      'exerciseName': exerciseNameController,
      'sets': setsController,
      'reps': repsController,
      'weight': weightController,
    });

    // 운동 정보 리스트에 추가
    exerciseInfoList.add({
      'exerciseName': '',
      'sets': 0,
      'reps': 0,
      'weight': 0,
    });

    setState(() {});
  }

  void _removeExercise(int index) {
    if (exerciseInfoList.length <= 1) {
      // 최소 하나의 운동은 유지
      return;
    }

    setState(() {
      exerciseInfoList.removeAt(index);
    });
  }

  Widget _buildRunningFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '달리기 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: distanceController,
              decoration: InputDecoration(
                labelText: '달린 거리 (km)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_run),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: memoController,
              decoration: InputDecoration(
                labelText: '메모',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: '오늘의 달리기에 대한 메모를 남겨주세요',
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '학습 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: '공부한 과목',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: memoController,
              decoration: InputDecoration(
                labelText: '메모',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: '오늘의 학습에 대한 메모를 남겨주세요',
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  void _completeActivity() async {
    Map<String, dynamic>? responseData;

    try {
      // 카테고리에 따라 적절한 함수 호출
      if (widget.category == '헬스') {
        // 모든 운동 정보가 올바르게 입력되었는지 확인
        bool hasEmptyField = false;

        for (int i = 0; i < exerciseInfoList.length; i++) {
          var exercise = exerciseInfoList[i];
          if (exercise['exerciseName'].toString().isEmpty &&
              exercise['sets'].toInt() == 0 &&
              exercise['reps'].toInt() == 0 &&
              exercise['weight'].toInt() == 0) {
            hasEmptyField = true;
            break;
          }
        }

        if (hasEmptyField) {
          if (!mounted) return;
          _showErrorSnackBar('모든 운동 내용을 입력해주세요');
          return;
        }

        responseData = await RecordService.sendfitnessRecord(
          widget.groupId,
          widget.activityTimeMinutes,
          widget.startTime,
          widget.endTime,
          exerciseInfoList,
        );
        log('responseData: $responseData');
      } else if (widget.category == '러닝') {
        // 거리 필드가 비어있는지 확인
        if (distanceController.text.isEmpty) {
          if (!mounted) return;
          _showErrorSnackBar('달린 거리를 입력해주세요');
          return;
        }
        if (memoController.text.isEmpty) {
          if (!mounted) return;
          _showErrorSnackBar('메모를 입력해주세요');
          return;
        }

        int distance = int.tryParse(distanceController.text) ?? 0;
        String memo = memoController.text;

        responseData = await RecordService.sendrunningRecord(
          widget.groupId,
          widget.activityTimeMinutes,
          widget.startTime,
          widget.endTime,
          distance,
          memo,
        );
        log('responseData: $responseData');
      } else if (widget.category == '공부') {
        // 과목 필드가 비어있는지 확인
        if (subjectController.text.isEmpty) {
          if (!mounted) return;
          _showErrorSnackBar('공부한 과목을 입력해주세요');
          return;
        }
        if (memoController.text.isEmpty) {
          if (!mounted) return;
          _showErrorSnackBar('메모를 입력해주세요');
          return;
        }

        String subject = subjectController.text;
        String memo = memoController.text;

        responseData = await RecordService.sendstudyRecord(
          widget.groupId,
          widget.activityTimeMinutes,
          widget.startTime,
          widget.endTime,
          subject,
          memo,
        );
        log('responseData: $responseData');
      }

      if (responseData == null) {
        if (!mounted) return;
        _showErrorSnackBar('서버에서 응답을 받지 못했습니다');
        return;
      }

      // 결과와 함께 이전 화면으로 돌아가기
      if (!mounted) return;
      Navigator.pop(context, responseData);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('오류가 발생했습니다: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
