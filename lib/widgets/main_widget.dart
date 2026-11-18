import 'package:flutter/material.dart';

import 'main_widget_sub_pages/first_page.dart';
import 'main_widget_sub_pages/goals_progress_page.dart';
import 'main_widget_sub_pages/temporary_last_page.dart';

class MainWidget{
  final String label;
  final Widget page;
  const MainWidget({required this.label, required this.page});
}

class MainWidgetList extends StatelessWidget {
  final String selectedDayLabel;
  final double aspectRatio;

  const MainWidgetList({super.key, required this.selectedDayLabel, this.aspectRatio = 1.6});

  List<MainWidget> _buildTabs() => const [
    MainWidget(label: 'Calories', page: CaloriesGraph()),
    MainWidget(label: 'Weight', page: GoalsProgressPage()),
    MainWidget(label: 'Strength', page: StrengthPlaceholder()),
  ];
  @override
  Widget build(BuildContext context){
    final tabs = _buildTabs();
    final color = Theme.of(context).colorScheme.primary;
    return DefaultTabController(
      length : tabs.length,
      child : Column(
        mainAxisSize : MainAxisSize.min,
        children : [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = (constraints.maxWidth / aspectRatio)
                    .clamp(360.0, 440.0)
                    .toDouble();

                return SizedBox(
                  height: height,
                  child: TabBarView(
                    children: tabs.map((tab) => tab.page).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              tabs: tabs.map((tab) => Tab(text: tab.label,height: 36)).toList(),
              indicator: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              splashBorderRadius: BorderRadius.circular(12), 
            ),
          ),
        ],
      ),
    );
  }
}