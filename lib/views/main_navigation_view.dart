import 'package:flutter/material.dart';

import '../screens/exercise_log_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/workout_routine_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/home_screen.dart';

enum NavTab { home, goals, routines, profile }

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  NavTab _selectedTab = NavTab.home;

  int _refreshCounter = 0;

  Widget _getScreen(NavTab tab) {
    switch (tab) {
      case NavTab.home:
        return HomeScreen(key: ValueKey('home_$_refreshCounter'));
      case NavTab.goals:
        return GoalsScreen(key: ValueKey('goals_$_refreshCounter'));
      case NavTab.routines:
        return const WorkoutRoutineScreen();
      case NavTab.profile:
        return ProfileScreen(key: ValueKey('profile_$_refreshCounter'));
    }
  }

  Future<void> _openExerciseLog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseLogScreen()),
    );
    // Re-mounts active tab (e.g., GoalsScreen) so weekly progress bars refresh
    // immediately after logging a workout.
    if (!mounted) return;
    setState(() => _refreshCounter++);
  }

  // Build function renders each tab at the bottom of the screen(parameters are icon and label)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_selectedTab),
      floatingActionButton: FloatingActionButton(
        onPressed: _openExerciseLog,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(NavTab.home, Icons.home, 'Home'),
            _buildNavItem(NavTab.goals, Icons.track_changes, 'Goals'),
            const SizedBox(width: 48), // Space for center FAB
            _buildNavItem(NavTab.routines, Icons.fitness_center, 'Routines'),
            _buildNavItem(NavTab.profile, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(NavTab tab, IconData icon, String label) {
    final isSelected = _selectedTab == tab;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
