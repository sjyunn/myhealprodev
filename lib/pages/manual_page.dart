// lib/pages/manual_page.dart (전체 교체)

import 'package:flutter/material.dart';

class ManualPage extends StatelessWidget {
  const ManualPage({super.key});

  final Color mainColor = const Color(0xFF34d399); // 힐링핏 메인 색상

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HEALINGFITPRO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        // AppBar 하단 탭 바 디자인 (메뉴얼/제품 소개/정보)
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text('메뉴얼', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(width: 20),
                Text('제품 소개', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(width: 20),
                Text('정보', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.article_outlined,
              color: Colors.grey[500]!,
              title: '간편 사용설명서',
              subtitle: '쉽고 간단한 가이드',
            ),
            const SizedBox(height: 20),
            _buildMenuItem(
              icon: Icons.library_books_outlined,
              color: mainColor,
              title: '상세 사용설명서',
              subtitle: '보다 자세한 설명이 필요하다면?',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required  Color color, required  String title, required  String subtitle}) {
    // ... (_buildMenuItem 로직 유지)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}