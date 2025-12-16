import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendancePieChart extends StatefulWidget {
  final Map<String, double> attendance;
  
  const AttendancePieChart({super.key, required this.attendance});

  @override
  State<AttendancePieChart> createState() => _AttendancePieChartState();
}

class _AttendancePieChartState extends State<AttendancePieChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final attendedPercent = widget.attendance['attended_percent'] ?? 0.0;
    final latePercent = widget.attendance['late_percent'] ?? 0.0;
    final missedPercent = widget.attendance['missed_percent'] ?? 0.0;
    final total = widget.attendance['total'] ?? 0.0;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: attendedPercent > 0 ? attendedPercent * _animation.value : 0.1,
                    color: Colors.green,
                    title: '',
                    radius: 25 * _animation.value,
                  ),
                  PieChartSectionData(
                    value: latePercent > 0 ? latePercent * _animation.value : 0.1,
                    color: Colors.orange,
                    title: '',
                    radius: 25 * _animation.value,
                  ),
                  PieChartSectionData(
                    value: missedPercent > 0 ? missedPercent * _animation.value : 0.1,
                    color: Colors.red,
                    title: '',
                    radius: 25 * _animation.value,
                  ),
                ],
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeInOut,
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    total.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'пар',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}