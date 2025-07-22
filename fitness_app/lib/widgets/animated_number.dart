import 'package:flutter/material.dart';

class AnimatedNumber extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0,
        end: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      ),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        // Handle different number formats (e.g., "2,450" or "4h 30m")
        if (this.value.contains('h')) {
          final hours = value ~/ 60;
          final minutes = (value % 60).toInt();
          return Text('${hours}h ${minutes}m', style: style);
        } else if (this.value.contains(',')) {
          return Text(value.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          ), style: style);
        }
        return Text(value.toInt().toString(), style: style);
      },
    );
  }
}
