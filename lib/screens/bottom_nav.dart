import 'package:flutter/material.dart';
import 'homepage.dart';
import 'my_devices.dart';
import 'my_reservations.dart';
import 'reservation_requests.dart';
import 'profile.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const MyDevicesScreen(),
      const ReservationsTabScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: const Color(0xFFB6B6B6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Toestellen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Verhuur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Reservaties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profiel',
          ),
        ],
      ),
    );
  }
}

class ReservationsTabScreen extends StatelessWidget {
  const ReservationsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservaties'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mijn aanvragen'),
              Tab(text: 'Binnenkomende aanvragen'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyReservationsScreen(),
            ReservationRequestsScreen(),
          ],
        ),
      ),
    );
  }
}
