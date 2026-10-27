import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'presenters/assignment_presenter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AssignmentPresenter _presenter = AssignmentPresenter();

  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      await _presenter.loadAssignments();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = _presenter.completionRatio;
    final remaining = _presenter.totalAssignments -
        _presenter.completedAssignments;
    final unfinishedAssignments = _presenter.assignments
      .where((assignment) => !assignment.isCompleted)
      .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Tracker'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadFailed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load assignments.'),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _loadFailed = false;
                          });

                          _loadAssignments();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: CircularPercentIndicator(
                          radius: 120,
                          lineWidth: 14,
                          percent: percent,
                          center: Text(
                            '${(percent * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          progressColor: Colors.purple,
                          backgroundColor: Colors.grey.shade300,
                          animation: true,
                          animationDuration: 800,
                          footer: const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('Assignments Completed'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Card(
                        child: ListTile(
                          title: const Text('Total Assignments'),
                          trailing: Text(
                            '${_presenter.totalAssignments}',
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('Completed Assignments'),
                          trailing: Text(
                            '${_presenter.completedAssignments}',
                          ),
                        ),
                      ),

                      // Extra widget for the assignment.
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.pending_actions,
                            color: Colors.orange,
                          ),
                          title: const Text('Assignments Remaining'),
                          trailing: Text('$remaining'),
                        ),
                      ),
                      Card(
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.checklist,
                            color: Colors.purple,
                          ),
                          title: const Text('Unfinished Assignments'),
                          subtitle: Text(
                            '${unfinishedAssignments.length} left to finish',
                          ),
                          children: [
                            if (unfinishedAssignments.isEmpty)
                              const ListTile(
                                leading: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                title: Text('No unfinished assignments!'),
                              ),
                            ...unfinishedAssignments.map(
                              (assignment) => ListTile(
                                leading: const Icon(Icons.assignment_outlined),
                                title: Text(assignment.title),
                                subtitle: Text('Course: ${assignment.courseName}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}