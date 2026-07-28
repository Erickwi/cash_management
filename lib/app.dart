import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'providers/room_provider.dart';
import 'features/room/room_screen.dart';
import 'features/home/home_screen.dart';
import 'features/income/income_screen.dart';
import 'features/expenses/expense_screen.dart';
import 'features/savings/savings_screen.dart';
import 'features/emergency/emergency_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/reports/report_screen.dart';

class CashManagementApp extends StatelessWidget {
  const CashManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash Management',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);

    if (!roomState.isConnected) {
      return const RoomScreen();
    }

    return const MainShell();
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _titles = [
    'Inicio',
    'Ingresos',
    'Gastos',
    'Ahorros',
    'Emergencia',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(title: Text(_titles[_currentIndex])),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            IncomeBody(),
            ExpenseBody(),
            SavingsBody(),
            EmergencyBody(),
          ],
        ),
      ),
      floatingActionButton: _fabForIndex(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Ingresos'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_upward), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Ahorros'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Emergencia'),
        ],
      ),
    );
  }

  Widget? _fabForIndex(int index) {
    switch (index) {
      case 1: return FloatingActionButton(onPressed: () => showIncomeForm(context, ref), child: const Icon(Icons.add));
      case 2: return FloatingActionButton(onPressed: () => showExpenseForm(context, ref), child: const Icon(Icons.add));
      case 3: return FloatingActionButton(onPressed: () => showSavingsForm(context, ref), child: const Icon(Icons.add));
      case 4: return FloatingActionButton(onPressed: () => showEmergencyForm(context, ref), child: const Icon(Icons.add));
      default: return null;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Cash Management',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer(builder: (_, ref, _) {
                    final roomState = ref.watch(roomProvider);
                    return Text(
                      'Sala: ${roomState.room?.code ?? ''}',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                    );
                  }),
                ],
              ),
            ),
            _drawerItem(Icons.repeat, 'Gastos Recurrentes', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()));
            }),
            _drawerItem(Icons.picture_as_pdf, 'Reportes', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
            }),
            const Divider(),
            _drawerItem(Icons.logout, 'Desconectar', () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Desconectar?'),
                  content: const Text('Se eliminarán los datos locales de la sala.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(roomProvider.notifier).disconnect();
                      },
                      child: const Text('Desconectar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue),
      title: Text(label, style: GoogleFonts.inter()),
      onTap: onTap,
    );
  }
}
