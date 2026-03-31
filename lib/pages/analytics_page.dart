import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Practice Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Insights from your automated clinical documentation', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 24),
          
          _buildSummaryCards(),
          
          const SizedBox(height: 24),
          const Text('Documentation Efficiency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSpeedChart(),
          
          const SizedBox(height: 30),
          const Text('Consultation Volume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildVolumeChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSimpleCard('Avg. Time Saved', '72%', '↑ 12%')),
        const SizedBox(width: 12),
        Expanded(child: _buildSimpleCard('Accuracy Rate', '98.4%', '↑ 0.5%')),
      ],
    );
  }

  Widget _buildSimpleCard(String label, String value, String delta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF22D3EE))),
          Text(delta, style: const TextStyle(fontSize: 10, color: Color(0xFF34D399))),
        ],
      ),
    );
  }

  Widget _buildSpeedChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(val == 0 ? 'Manual' : 'VaakSetu', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.white24, width: 40, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 2.1, color: const Color(0xFF22D3EE), width: 40, borderRadius: BorderRadius.circular(4))]),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Text(days[val.toInt() % 7], style: const TextStyle(color: Colors.white38, fontSize: 10));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 12),
                FlSpot(1, 15),
                FlSpot(2, 9),
                FlSpot(3, 18),
                FlSpot(4, 22),
                FlSpot(5, 14),
                FlSpot(6, 16),
              ],
              isCurved: true,
              color: const Color(0xFF818CF8),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF818CF8).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
