// lib/pages/my_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // MethodChannel을 위해 추가
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// 🚨 (가정) Hive 모델과 서비스 경로 임포트 (이전 대화 기반)
import '../services/health_connect_service.dart';
import '../models/daily_record.dart';


class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['일', '주', '월'];

  final Color mainColor = const Color(0xFF34d399);
  final Color sleepColor = Colors.green;

  // ⬇️ 🛠️ MethodChannel 상수 정의 (Kotlin과 통신) ⬇️
  static const String _checkIfShouldShowPrivacyPolicyChannel = 'app.channel.flutter.health.connect.show.privacy.policy';
  static const String _checkIfShouldShowPrivacyPolicyFunction = 'checkIfShouldShowPrivacyPolicy';
  static const MethodChannel _platformChannel = MethodChannel(_checkIfShouldShowPrivacyPolicyChannel);
  // ⬆️ 🛠️ MethodChannel 상수 정의 ⬆️

  // 데이터 관련 변수
  final HealthConnectService _hcService = HealthConnectService();
  List<DailyRecord> _dailyRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: 0);

    // 🚨 앱 시작 시, Kotlin에서 개인정보 처리방침 요청이 있었는지 확인
    _checkIfShouldShowPrivacyPolicy().then(
          (shouldShowPrivacyPolicy) {
        if (shouldShowPrivacyPolicy) {
          _showPrivacyPolicyAlert(context);
        }
      },
    );

    _loadAndSyncData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ⬇️ 🛠️ Kotlin에게 개인정보 처리방침 인텐트 상태를 질의하는 함수 ⬇️
  Future<bool> _checkIfShouldShowPrivacyPolicy() async {
    try {
      final result = await _platformChannel.invokeMethod(_checkIfShouldShowPrivacyPolicyFunction);
      return result as bool;
    } on PlatformException catch (e) {
      print("Failed to check privacy policy intent: '${e.message}'.");
      return false;
    }
  }

  // 개인정보 처리방침을 표시하는 더미 Alert
  void _showPrivacyPolicyAlert(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("개인정보 처리방침 요청"),
          content: const Text("Health Connect 권한 화면에서 요청하셨습니다.\n여기에 정책 웹뷰를 표시해야 합니다."),
          actions: <Widget>[
            TextButton(
              child: const Text("닫기"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  // ⬆️ 🛠️ Kotlin에게 개인정보 처리방침 인텐트 상태를 질의하는 함수 ⬆️


  // 데이터 로딩 및 동기화
  Future<void> _loadAndSyncData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _hcService.fetchAndSyncSleepData();

      final records = _hcService.getAllDailyRecords();
      records.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _dailyRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ⬇️ 🛠️ Health Connect 설정 화면을 여는 함수 (유지) ⬇️
  Future<void> _openHealthConnectSettings() async {
    try {
      final settingsUri = Uri.parse('android.settings.HEALTH_CONNECT_SETTINGS');
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to app info or play store
        final packageUri = Uri.parse('package:com.google.android.apps.healthdata');
        if (await canLaunchUrl(packageUri)) {
          await launchUrl(packageUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Health Connect 설정 열기 오류: $e');
    }
  }

  // ⬇️ 🛠️ 권한 요청 버튼에 연결될 함수 (핵심) ⬇️
  Future<void> _requestHealthConnectPermissions() async {
    final granted = await _hcService.checkAndRequestPermissions();

    if (granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한 허용됨. 데이터를 동기화합니다...'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadAndSyncData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한이 거부되었습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // ⬆️ 🛠️ 권한 요청 버튼에 연결될 함수 (핵심) ⬆️


  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) return '${duration.inMinutes}분';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}시간 ${minutes}분';
  }

  // 원형 차트 UI (생략된 함수 내용 포함)
  Widget _buildUsageCircle(DailyRecord record) {
    // ... (이전에 제공된 _buildUsageCircle 위젯 내용) ...
    //

    //[Image of Chart]

    final Duration sleepDuration = Duration(minutes: record.sleepDurationMinutes);
    final Duration healingDuration = Duration(minutes: record.totalHealingDuration);

    final sleepText = _formatDuration(sleepDuration);
    final healingText = _formatDuration(healingDuration);

    // 8시간 목표 (480분)
    final double progressValue = record.sleepDurationMinutes / 480.0;

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 8),
                ),
              ),
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(sleepColor),
                  backgroundColor: Colors.transparent,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '달성',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.bedtime, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text('수면', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sleepText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sleepColor),
                ),
                const Text('목표: 7시간 30분', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Column(
              children: [
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.headphones, size: 16, color: mainColor),
                    const SizedBox(width: 4),
                    const Text('힐링핏', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  healingText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainColor),
                ),
                const Text('목표: 1시간 30분', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 내 상태 분석 섹션 (생략된 함수 내용 포함)
  Widget _buildSleepAnalysis(DailyRecord record) {
    final sleepText = _formatDuration(Duration(minutes: record.sleepDurationMinutes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('내 상태 분석', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('오늘 수면', style: TextStyle(color: Colors.grey)),
            Text(
              sleepText,
              style: TextStyle(color: sleepColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        const Text('목표 설정', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('• 수면: 7시간 30분', style: TextStyle(color: Colors.grey)),
        const Text('• 힐링핏: 1시간 30분', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  // Health Connect 연동 섹션 (생략된 함수 내용 포함)
  Widget _buildHealthConnectSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Health Connect 연동',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Google Health Connect와 연동하여 삼성헬스, Better Sleep 등의 앱에서 수면, 걸음 수, 심박수 데이터를 자동으로 수집합니다.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // ⬇️ 3개의 버튼 ⬇️
          Column(
            children: [
              // 1. 권한 요청 버튼 (핵심)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestHealthConnectPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.security, color: Colors.white, size: 18),
                  label: const Text(
                    '권한 요청하기',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 2, 3. 기존 버튼들
              Row(
                children: [
                  // 데이터 동기화 버튼
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loadAndSyncData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.sync, color: Colors.white, size: 18),
                      label: const Text(
                        '동기화',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Health Connect 설정 열기 버튼
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openHealthConnectSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                      label: const Text(
                        '앱 설정',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ⬇️ 🛠️ 누락된 build 메서드 (핵심 수정) ⬇️
  @override
  Widget build(BuildContext context) {
    final todayRecord = _dailyRecords.isNotEmpty
        ? _dailyRecords.first
        : DailyRecord(date: DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 건강'),
        backgroundColor: mainColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 탭 선택 바
            Container(
              color: mainColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _tabs.map((String name) => Tab(text: name)).toList(),
              ),
            ),

            // 탭 콘텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 일별 뷰
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(child: _buildDailyView(todayRecord)),
                  // 주별 뷰
                  SingleChildScrollView(child: _buildWeeklyView()),
                  // 월별 뷰
                  SingleChildScrollView(child: _buildMonthlyView()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ⬆️ 🛠️ 누락된 build 메서드 ⬆️


  // 일별 뷰
  Widget _buildDailyView(DailyRecord todayRecord) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(todayRecord.date),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildUsageCircle(todayRecord),
          const SizedBox(height: 30),
          _buildSleepAnalysis(todayRecord),
          const SizedBox(height: 30),
          _buildHealthConnectSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 주별 뷰
  Widget _buildWeeklyView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주간 통계',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (_dailyRecords.isEmpty)
            const Center(child: Text('데이터가 없습니다'))
          else
            ..._dailyRecords.take(7).map((record) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(DateFormat('MM/dd (E)', 'ko_KR').format(record.date)),
                subtitle: Text(
                  '수면: ${_formatDuration(Duration(minutes: record.sleepDurationMinutes))} / 힐링: ${_formatDuration(Duration(minutes: record.totalHealingDuration))}',
                ),
              ),
            )),
        ],
      ),
    );
  }

  // 월별 뷰
  Widget _buildMonthlyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "월간 막대 차트 영역: 데이터 분석 구현 예정",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}