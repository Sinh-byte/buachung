import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'data/repository/app_state.dart';
import 'ui/widgets/theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/other_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  // Thanh status bar trong suốt
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const BuaChungApp(),
    ),
  );
}

class BuaChungApp extends StatelessWidget {
  const BuaChungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BữaChung',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    MembersScreen(),
    SettleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🍜', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 16),
                  Text(
                    'BữaChung',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.muted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: _NavIcon('🏠', _currentIndex == 0),
                  activeIcon: _NavIcon('🏠', true),
                  label: 'Bữa ăn',
                ),
                BottomNavigationBarItem(
                  icon: _NavIcon('👥', _currentIndex == 1),
                  activeIcon: _NavIcon('👥', true),
                  label: 'Thành viên',
                ),
                BottomNavigationBarItem(
                  icon: _NavIcon('💳', _currentIndex == 2),
                  activeIcon: _NavIcon('💳', true),
                  label: 'Quyết toán',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String emoji;
  final bool active;
  const _NavIcon(this.emoji, this.active);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: TextStyle(fontSize: active ? 24 : 22)),
    );
  }
}
