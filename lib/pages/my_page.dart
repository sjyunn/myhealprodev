// lib/pages/my_page.dart (Health Connect 의존성 제거 버전)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Health Connect 관련 임포트 모두 제거

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with TickerProviderStateMixin {

  late TabController _tabController;
  final List<String> _tabs = ['일', '주', '월']; // 탭 제목

  final Color mainColor = const Color(0xFF34d399);
  final Color sleepColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) return '${duration.inMinutes}분';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}시간 ${minutes}분';
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    // ⚠️ 모든 Health Connect 로직 제거
    final totalSleepDuration = Duration.zero; // 더미 값

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 일/주/월 탭 선택 바
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: _tabs.map((name) => Tab(text: name)).toList(),
              ),
            ),

            // 2. 탭 바 아래의 메인 콘텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 0: 일별 뷰 (원형 차트)
                  SingleChildScrollView(child: _buildDailyView(totalSleepDuration)),
                  // 1: 주별 뷰 (막대 차트)
                  SingleChildScrollView(child: _buildWeeklyView()),
                  // 2: 월별 뷰 (막대 차트)
                  SingleChildScrollView(child: _buildMonthlyView()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. 일별 뷰 (원형 차트 - 첨부 1)
  Widget _buildDailyView(Duration totalSleepDuration) {
    // ... (UI 코드 유지)
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (날짜 텍스트 유지)
          _buildUsageCircle(totalSleepDuration),
          const SizedBox(height: 30),
          _buildSleepAnalysis(),
          _buildHealthConnectSection(), // Health Connect 섹션 UI 유지
        ],
      ),
    );
  }

  // 4. 주별 뷰 (막대 차트 - 첨부 3)
  Widget _buildWeeklyView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ... (UI 코드 유지)
          SizedBox(height: 200, child: Center(child: Text('주간 막대 차트 영역 (데이터 없음)'))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('🟢 일일 평균 수면\n0시간 0분', textAlign: TextAlign.center),
              Text('🔵 일일 평균 사용\n0시간 59분', textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }

  // 5. 월별 뷰 (막대 차트 - 첨부 2)
  Widget _buildMonthlyView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ... (UI 코드 유지)
          SizedBox(height: 200, child: Center(child: Text('월간 막대 차트 영역 (데이터 없음)'))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('🟢 일일 평균 수면\n0시간 0분', textAlign: TextAlign.center),
              Text('🔵 일일 평균 사용\n1시간 0분', textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }

  // 6. 기타 UI 헬퍼 함수 (Health Connect 섹션은 버튼 기능 제거)
  Widget _buildHealthConnectSection() {
    // ⚠️ Health Connect 연동 섹션 UI (버튼 기능 제거)
    return Container(
      // ... (Container 유지)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (텍스트 및 아이콘 유지)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { print('Health Connect 기능은 나중에 구현됩니다.'); }, // ◀️ 기능 제거
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text('지금 설정하기 (UI)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 1. _buildUsageCircle (원형 차트 - 누락된 함수 1)
  // ----------------------------------------------------
  Widget _buildUsageCircle(Duration totalSleepDuration) {
    final Color sleepColor = Colors.green;
    final Color mainColor = const Color(0xFF34d399);

    return Column(
      children: [
        // 원형 차트 (더미)
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 8),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: 0.5, // 50% 더미 값
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(sleepColor),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 수면 및 힐링 사용 시간 텍스트 (더미)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 수면 시간
            Column(
              children: [
                Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: sleepColor, shape: BoxShape.circle)), const SizedBox(width: 5), const Text('수면 시간', style: TextStyle(fontSize: 12))]),
                Text('0시간 0분', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sleepColor)),
                const Text('목표: 7시간 30분', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            // 힐링핏 사용 시간 (더미)
            Column(
              children: [
                Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle)), const SizedBox(width: 5), const Text('힐링핏 사용 시간', style: TextStyle(fontSize: 12))]),
                Text('0시간 43분', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainColor)),
                const Text('목표: 1시간 30분', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 2. _buildSleepAnalysis (내 상태 분석 섹션 - 누락된 함수 2)
  // ----------------------------------------------------
  Widget _buildSleepAnalysis() {
    final Color sleepColor = Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('내 상태 분석', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // 수면 목표 설정 등 UI는 이미지와 유사하게 구현
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('오늘 수면', style: TextStyle(color: Colors.grey)),
            Text('0시간 0분', style: TextStyle(color: sleepColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(),
        Text('목표 설정', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        // 시간 선택 버튼 (더미)
        Wrap(spacing: 8.0, runSpacing: 8.0, children: [
          for (var time in ['6:00', '7:30', '8:30'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: time == '7:30' ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(5)),
              child: Text(time, style: TextStyle(color: time == '7:30' ? Colors.white : Colors.black)),
            ),
        ]),
      ],
    );
  }

}