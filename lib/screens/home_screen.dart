//dont worry this will be added
import 'package:flutter/material.dart';
import '../widgets/calendar_strip.dart';
import '../presenters/calendar_presenter.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final CalendarPresenter _calendarPresenter = CalendarPresenter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CalendarStrip(
              presenter: _calendarPresenter,
              onDaySelected: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            //Temp text box that reflects the return dateGiven from presenter
            Text(
              _calendarPresenter.selectedDayLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}



