// lib/pages/main_shell.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'controller_page.dart'; // 기존 컨트롤러 페이지
import 'manual_page.dart';       // 새로 만들 메뉴 페이지
import 'my_page.dart';         // 새로 만들 마이페이지

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 1; // 1: 컨트롤러(기본값), 0: 메뉴, 2: 마이페이지
  final Color mainColor = const Color(0xFF34d399);

  // 1. 메뉴에 표시될 페이지 목록
  final List<Widget> _widgetOptions = <Widget>[
    const ManualPage(),       // 0번 인덱스: 메뉴 페이지 (Health Connect 데이터 표시 예정)
    const ControllerPage(), // 1번 인덱스: 컨트롤러 페이지 (기존 BLE 제어 화면)
    const MyPage(),         // 2번 인덱스: 마이페이지
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 페이지를 표시
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // 2. 하단 내비게이션 바 구현
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: '메뉴얼',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.playCircle), // 컨트롤러를 Play 아이콘으로 표현
            label: '컨트롤러',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: mainColor, // 선택된 아이콘 색상
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이콘 색상
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // 아이템 수가 적을 때 사용
      ),
    );
  }
}