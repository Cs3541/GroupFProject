import 'package:flutter/material.dart';

import '../widgets/main_widget_sub_widgets/first_page.dart';
import '../widgets/main_widget_sub_widgets/goals_progress_page.dart';
import '../widgets/main_widget_sub_widgets/temporary_last_page.dart';

class MainWidget{
  final String label;
  final Widget page;
  const MainWidget({required this.label, required this.page});
}

class MainWidgetList extends StatelessWidget {
  final String selectedDayLabel;
  final double aspectRatio;

  const MainWidgetList({super.key, required this.selectedDayLabel, this.aspectRatio = 1.6});


  //Note for Carson : Whenever we decide what to put on each tab
  //come back here and change the label name as well as the page
  //name to whatever we rename the files depending on the purpose of each
  List<MainWidget> _buildTabs() => [
    MainWidget(label: selectedDayLabel, page: const FirstPage()),
    const MainWidget(label: 'Goals', page: GoalsProgressPage()),
    const MainWidget(label: 'Undecided', page: TemporaryLastPage()),
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
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: TabBarView(children: tabs.map((tab) => tab.page).toList()),
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