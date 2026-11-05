import 'package:fallguys_fitness_app/screens/profile_screen.dart';
import 'package:fallguys_fitness_app/screens/signup_screen.dart';
import 'package:flutter/material.dart';

import 'goals_screen.dart';
import 'workout_routine_screen.dart';
import '../screens/signup_screen.dart';
import 'profile_screen.dart';

enum NavTab { home, goals, routines, profile, signupScreen }

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  NavTab _selectedTab = NavTab.signupScreen;

  Widget _getScreen(NavTab tab) {
    switch (tab) {
      case NavTab.signupScreen:
        return const SignupScreen();
      case NavTab.home:
        return const Center(child: Text('Home Screen (WIP)'));
      case NavTab.goals:
        return const GoalsScreen(); // hooked to my vertical slice
      case NavTab.routines:
        return const WorkoutRoutineScreen();
      case NavTab.profile:
        return ProfileScreen();
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
