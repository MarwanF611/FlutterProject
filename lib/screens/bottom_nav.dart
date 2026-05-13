import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/chat_provider.dart';
import '../providers/reservation_provider.dart';
import '../services/notification_service.dart';
import 'homepage.dart';
import 'map_screen.dart';
import 'my_devices.dart';
import 'my_reservations.dart';
import 'reservation_requests.dart';
import 'profile.dart';
import 'chats_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request notification permission now that the UI is fully visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  static const int _reservationTabIndex = 2;
  static const int _chatTabIndex = 4;

  static const _pages = [
    HomeScreen(),
    MyDevicesScreen(),
    ReservationsTabScreen(),
    MapScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  void _onTabTap(int index) {
    if (index == _chatTabIndex) {
      context.read<ChatProvider>().clearUnread();
    }
    if (index == _reservationTabIndex) {
      context.read<ReservationProvider>().clearUnread();
    }
    setState(() => _currentIndex = index);
  }

  Widget _badgeIcon(int count, {required IconData icon}) {
    if (count == 0) return Icon(icon);
    return Badge.count(
      count: count,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadChats = context.watch<ChatProvider>().unreadCount;
    final unreadReservations = context.watch<ReservationProvider>().unreadCount;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        backgroundColor: AppColors.bgLight,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Toestellen',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Verhuur',
          ),
          BottomNavigationBarItem(
            icon: _badgeIcon(unreadReservations, icon: Icons.calendar_month_outlined),
            activeIcon: _badgeIcon(unreadReservations, icon: Icons.calendar_month),
            label: 'Reservaties',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Kaart',
          ),
          BottomNavigationBarItem(
            icon: _badgeIcon(unreadChats, icon: Icons.chat_bubble_outline),
            activeIcon: _badgeIcon(unreadChats, icon: Icons.chat_bubble),
            label: 'Berichten',
          ),
          const BottomNavigationBarItem(
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
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
