// lib/widgets/tes_control.dart

import 'package:flutter/material.dart';

// TesControl 클래스: 수평 슬라이더 형태로 TES 세기를 제어합니다.
class TesControl extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChange;

  const TesControl({super.key, required this.value, required this.onChange});

  @override
  State<TesControl> createState() => _TesControlState();
}

class _TesControlState extends State<TesControl> {
  late double _currentValue;
  final int numSteps = 15; // 최대 세기 레벨

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant TesControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 value가 변경되면 내부 상태도 업데이트
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Theme.of(context).colorScheme.primary; // 테마에서 메인 색상 가져오기

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      // 높이를 낮추기 위해 Container 대신 Column 사용
      child: Column(
        mainAxisSize: MainAxisSize.min, // 최소 높이만 사용
        children: [
          // 1. 현재 세기 레벨 표시 (원형 컨트롤의 중앙 텍스트 대체)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '세기 레벨',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                _currentValue.round().toString(),
                style: TextStyle(
                  fontSize: 32, // 큰 폰트 크기 유지
                  fontWeight: FontWeight.w900,
                  color: mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // 2. 수평 슬라이더 위젯
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              activeTrackColor: mainColor,
              inactiveTrackColor: mainColor.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: mainColor.withOpacity(0.2),

              // 15단계 조절을 위해 discrete(이산적) 설정
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              min: 0,
              max: numSteps.toDouble(),
              divisions: numSteps - 1, // 1부터 15까지 15단계 (14칸)
              value: _currentValue,
              onChanged: (double newValue) {
                setState(() {
                  _currentValue = newValue;
                });
                widget.onChange(newValue);
              },
            ),
          ),

          // 3. 최소/최대 라벨
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min (1)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('Max (15)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}