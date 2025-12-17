import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AverageMarksBarChart extends StatefulWidget {
  final Map<String, double> averages;
  
  const AverageMarksBarChart({super.key, required this.averages});

  @override
  State<AverageMarksBarChart> createState() => _AverageMarksBarChartState();
}

class _AverageMarksBarChartState extends State<AverageMarksBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    final homeAvg = widget.averages['home'] ?? 0.0;
    final controlAvg = widget.averages['control'] ?? 0.0;
    final labAvg = widget.averages['lab'] ?? 0.0;
    final practicalAvg = widget.averages['practical'] ?? 0.0;
    final finalAvg = widget.averages['final'] ?? 0.0;
    final overallAvg = widget.averages['overall'] ?? 0.0;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.center,
            maxY: 5.0,
            barTouchData: BarTouchData(
              enabled: false,
            ),
            titlesData: FlTitlesData(
              show: false,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: false,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: homeAvg * _animation.value,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.red,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 5.0,
                      color: Colors.grey.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: controlAvg * _animation.value,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.green,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 5.0,
                      color: Colors.grey.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(
                    toY: labAvg * _animation.value,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.purple,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 5.0,
                      color: Colors.grey.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 3,
                barRods: [
                  BarChartRodData(
                    toY: practicalAvg * _animation.value,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.orange,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 5.0,
                      color: Colors.grey.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 4,
                barRods: [
                  BarChartRodData(
                    toY: finalAvg * _animation.value,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 5.0,
                      color: Colors.grey.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 5,
                barRods: [
                  BarChartRodData(
                    toY: overallAvg * _animation.value,
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.blue,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 5.0,
                      color: Colors.grey.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ],
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
          swapAnimationCurve: Curves.easeInOut,
        );
      },
    );
  }
}