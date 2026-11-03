import 'package:flutter/material.dart';

import '../goals/goals_screen.dart';

enum NavTab { home, goals, routines, profile }

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  NavTab _selectedTab = NavTab.home;

  Widget _getScreen(NavTab tab) {
    switch (tab) {
      case NavTab.home:
        return const Center(child: Text('Home Screen (WIP)'));
      case NavTab.goals:
        return const GoalsScreen(); // hooked to my vertical slice
      case NavTab.routines:
        return const Center(child: Text('Routines Screen (WIP)'));
      case NavTab.profile:
        return const Center(child: Text('Profile Screen (WIP)'));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedTab = NavTab.values[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_selectedTab),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab.index,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Routines',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
