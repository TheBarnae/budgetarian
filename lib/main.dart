import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const BudgetarianApp());
}

class BudgetarianApp extends StatefulWidget {
  const BudgetarianApp({super.key});

  @override
  State<BudgetarianApp> createState() => _BudgetarianAppState();
}

class _BudgetarianAppState extends State<BudgetarianApp> {
  final AppStore _store = AppStore();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Budgetarian',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
          ),
          home: _buildStage(),
        );
      },
    );
  }

  Widget _buildStage() {
    switch (_store.stage) {
      case AppStage.splash:
        return SplashScreen(onDone: _store.finishSplash);
      case AppStage.walkthrough:
        return WalkthroughScreen(onDone: _store.finishWalkthrough);
      case AppStage.auth:
        return AuthScreen(store: _store);
      case AppStage.app:
        return AppShell(store: _store);
    }
  }
}

enum AppStage { splash, walkthrough, auth, app }

enum TxType { expense, income, saving }

class AppColors {
  static const Color ink = Color(0xFF171A34);
  static const Color primary = Color(0xFF7564F7);
  static const Color primarySoft = Color(0xFFE8E5FF);
  static const Color background = Color(0xFFF4F4F6);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1F2331);
  static const Color muted = Color(0xFF80859A);
  static const Color danger = Color(0xFFE0565A);
  static const Color success = Color(0xFF1AAB77);
}

class UserAccount {
  UserAccount({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

class AppTx {
  AppTx({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.account,
  });

  final String id;
  final TxType type;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final String account;
}

class SavingsGoal {
  SavingsGoal({
    required this.title,
    required this.current,
    required this.target,
    required this.dueDate,
  });

  final String title;
  final double current;
  final double target;
  final String dueDate;
}

class FinanceAccount {
  FinanceAccount({
    required this.name,
    required this.masked,
    required this.balance,
    required this.isWallet,
  });

  final String name;
  final String masked;
  final double balance;
  final bool isWallet;
}

class AppStore extends ChangeNotifier {
  AppStage stage = AppStage.splash;
  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final List<UserAccount> _users = [
    UserAccount(name: 'Juan dela Cruz', email: 'juan@gmail.com', password: '123456'),
  ];

  UserAccount? currentUser;

  final List<AppTx> _transactions = [
    AppTx(
      id: '1',
      type: TxType.expense,
      category: 'Food',
      description: 'Grab Food',
      amount: 320,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      account: 'BDO',
    ),
    AppTx(
      id: '2',
      type: TxType.income,
      category: 'Salary',
      description: 'Monthly Salary',
      amount: 18000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      account: 'BDO',
    ),
    AppTx(
      id: '3',
      type: TxType.expense,
      category: 'Shopping',
      description: 'Shopee',
      amount: 1200,
      date: DateTime.now().subtract(const Duration(days: 3)),
      account: 'GCash',
    ),
  ];

  final List<SavingsGoal> _goals = [
    SavingsGoal(title: 'Goals 1', current: 360, target: 900, dueDate: '31.12'),
    SavingsGoal(title: 'Goals 2', current: 700, target: 3000, dueDate: '31.12'),
    SavingsGoal(title: 'Vacation', current: 5500, target: 35000, dueDate: '05.15'),
  ];

  final List<FinanceAccount> _accounts = [
    FinanceAccount(name: 'BDO', masked: '•••• 6521', balance: 45200, isWallet: false),
    FinanceAccount(name: 'BPI', masked: '•••• 7933', balance: 12840, isWallet: false),
    FinanceAccount(name: 'GCash', masked: '₱XXX,XXX.XX', balance: 1000, isWallet: true),
    FinanceAccount(name: 'Maya', masked: '₱XXX,XXX.XX', balance: 2500, isWallet: true),
  ];

  int statsMode = 1;

  List<AppTx> get transactions => List.unmodifiable(_transactions);
  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  List<FinanceAccount> get accounts => List.unmodifiable(_accounts);
  List<FinanceAccount> get bankAccounts => _accounts.where((x) => !x.isWallet).toList();
  List<FinanceAccount> get wallets => _accounts.where((x) => x.isWallet).toList();

  double get monthExpense => _transactions
      .where((x) => x.type == TxType.expense)
      .fold(0, (sum, x) => sum + x.amount);

  double get monthIncome => _transactions
      .where((x) => x.type == TxType.income)
      .fold(0, (sum, x) => sum + x.amount);

  double get totalSavings => _goals.fold(0, (sum, x) => sum + x.current);

  Map<String, double> get categoryTotals {
    final Map<String, double> out = {};
    for (final tx in _transactions.where((x) => x.type == TxType.expense)) {
      out[tx.category] = (out[tx.category] ?? 0) + tx.amount;
    }
    final sorted = out.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  List<double> get weeklyBars {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final bars = List<double>.filled(7, 0);
    for (final tx in _transactions.where((x) => x.type == TxType.expense)) {
      final diff = tx.date.difference(monday).inDays;
      if (diff >= 0 && diff < 7) {
        bars[diff] += tx.amount;
      }
    }
    final max = bars.reduce((a, b) => a > b ? a : b);
    if (max == 0) {
      return [12, 22, 18, 31, 28, 40, 22];
    }
    return bars.map((e) => (e / max) * 40 + 10).toList();
  }

  void finishSplash() {
    stage = AppStage.walkthrough;
    notifyListeners();
  }

  void finishWalkthrough() {
    stage = AppStage.auth;
    notifyListeners();
  }

  String login(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return 'Please enter email and password.';
    }
    if (!_emailRegex.hasMatch(normalizedEmail)) {
      return 'Please enter a valid email address.';
    }
    if (normalizedPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    try {
      final user = _users.firstWhere(
        (u) => u.email.toLowerCase() == normalizedEmail && u.password == normalizedPassword,
      );
      currentUser = user;
      stage = AppStage.app;
      notifyListeners();
      return 'ok';
    } catch (_) {
      return 'Invalid credentials.';
    }
  }

  String signUp(String name, String email, String password) {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedName.isEmpty || normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return 'Please complete all fields.';
    }
    if (!_emailRegex.hasMatch(normalizedEmail)) {
      return 'Please enter a valid email address.';
    }
    if (normalizedPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    final exists = _users.any((u) => u.email.toLowerCase() == normalizedEmail);
    if (exists) {
      return 'Email already exists. Try logging in.';
    }

    final user = UserAccount(
      name: normalizedName,
      email: normalizedEmail,
      password: normalizedPassword,
    );
    _users.add(user);
    currentUser = user;
    stage = AppStage.app;
    notifyListeners();
    return 'ok';
  }

  void logout() {
    currentUser = null;
    stage = AppStage.auth;
    notifyListeners();
  }

  void setStatsMode(int mode) {
    statsMode = mode;
    notifyListeners();
  }

  void addTransaction({
    required TxType type,
    required double amount,
    required String description,
    required String category,
    required String account,
  }) {
    _transactions.insert(
      0,
      AppTx(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        category: category,
        description: description,
        amount: amount,
        date: DateTime.now(),
        account: account,
      ),
    );
    notifyListeners();
  }

  void addNewGoal() {
    final int number = _goals.length + 1;
    _goals.add(
      SavingsGoal(
        title: 'Goal $number',
        current: 0,
        target: 10000,
        dueDate: '12.31',
      ),
    );
    notifyListeners();
  }

  void addBankAccount() {
    final int number = bankAccounts.length + 1;
    _accounts.add(
      FinanceAccount(
        name: 'Bank $number',
        masked: '•••• ${5000 + number}',
        balance: 0,
        isWallet: false,
      ),
    );
    notifyListeners();
  }

  void addWalletAccount() {
    final int number = wallets.length + 1;
    _accounts.add(
      FinanceAccount(
        name: 'Wallet $number',
        masked: '₱XXX,XXX.XX',
        balance: 0,
        isWallet: true,
      ),
    );
    notifyListeners();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1F46), Color(0xFF173C73)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(Icons.account_balance_wallet, size: 44, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Budgetarian',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
              ),
              SizedBox(height: 4),
              Text('Manage your money smarter', style: TextStyle(color: Color(0xFFD8E2FF))),
            ],
          ),
        ),
      ),
    );
  }
}

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final _slides = const [
    (
      Icons.insights,
      'Track Daily Spending',
      'See where your money goes with category snapshots and weekly trends.',
    ),
    (
      Icons.savings,
      'Build Goals Faster',
      'Create goals, monitor progress, and stay motivated with one-tap updates.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (_, i) {
                    final slide = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: AppColors.primarySoft,
                          child: Icon(slide.$1, size: 66, color: AppColors.primary),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          slide.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 30),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: AppColors.muted),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? AppColors.primary : const Color(0xFFD6DBEB),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  if (_page == _slides.length - 1) {
                    widget.onDone();
                    return;
                  }
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_page == _slides.length - 1 ? 'Get Started' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loginMode = true;

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1F46), Color(0xFF143467)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to', style: TextStyle(color: Color(0xFFD6E0FF))),
                SizedBox(height: 3),
                Text(
                  'Budgetarian',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Front-end only for now, with local in-memory user database.',
                  style: TextStyle(color: Color(0xFFD6E0FF)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEFF8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AuthModeButton(
                          text: 'Login',
                          active: _loginMode,
                          onTap: () => setState(() => _loginMode = true),
                        ),
                      ),
                      Expanded(
                        child: _AuthModeButton(
                          text: 'Sign Up',
                          active: !_loginMode,
                          onTap: () => setState(() => _loginMode = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_loginMode) _buildLogin() else _buildSignup(),
                const SizedBox(height: 10),
                const Text(
                  'Demo login: juan@gmail.com / 123456',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        _SimpleInput(controller: _loginEmail, hint: 'Email'),
        const SizedBox(height: 8),
        _SimpleInput(controller: _loginPassword, hint: 'Password', obscure: true),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _submitLogin,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Login'),
        ),
      ],
    );
  }

  Widget _buildSignup() {
    return Column(
      children: [
        _SimpleInput(controller: _signupName, hint: 'Full Name'),
        const SizedBox(height: 8),
        _SimpleInput(controller: _signupEmail, hint: 'Email'),
        const SizedBox(height: 8),
        _SimpleInput(controller: _signupPassword, hint: 'Password', obscure: true),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _submitSignup,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create Account'),
        ),
      ],
    );
  }

  void _submitLogin() {
    final result = widget.store.login(_loginEmail.text, _loginPassword.text);
    if (result != 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  void _submitSignup() {
    final result = widget.store.signUp(
      _signupName.text,
      _signupEmail.text,
      _signupPassword.text,
    );
    if (result != 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({required this.text, required this.active, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? AppColors.ink : AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final AppStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(store: widget.store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        store: widget.store,
        onOpenStats: () => setState(() => _tab = 1),
        onOpenProfile: () => setState(() => _tab = 4),
      ),
      StatsPage(store: widget.store),
      SavingsPage(store: widget.store),
      AccountsPage(store: widget.store),
      ProfilePage(store: widget.store),
    ];

    return Scaffold(
      body: SafeArea(top: false, child: pages[_tab]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 58,
        height: 58,
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: AppColors.primary,
          onPressed: _openAddSheet,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _tab,
        onSelected: (index) => setState(() => _tab = index),
        onAdd: _openAddSheet,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            _NavItem(
              icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onSelected(0),
            ),
            _NavItem(
              icon: currentIndex == 1 ? Icons.bar_chart : Icons.bar_chart_outlined,
              label: 'Stats',
              active: currentIndex == 1,
              onTap: () => onSelected(1),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onAdd,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 14),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _NavItem(
              icon: currentIndex == 2 ? Icons.savings : Icons.savings_outlined,
              label: 'Savings',
              active: currentIndex == 2,
              onTap: () => onSelected(2),
            ),
            _NavItem(
              icon: currentIndex == 3 ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
              label: 'Accounts',
              active: currentIndex == 3,
              onTap: () => onSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.muted),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.store,
    required this.onOpenStats,
    required this.onOpenProfile,
  });

  final AppStore store;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final name = store.currentUser?.name ?? 'Juan dela Cruz';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1F46), Color(0xFF132F63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onOpenProfile,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        border: Border.all(color: Colors.white24),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Color(0xFFE2E8FF), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 23,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Total Spent', style: TextStyle(color: Color(0xFFC9D2F7), fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                _peso(store.monthExpense),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 34),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text('Overview', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.savings,
                  title: 'Savings',
                  amount: _peso(store.totalSavings),
                  borderColor: const Color(0xFFB4A5FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.bar_chart,
                  title: 'Spending',
                  amount: _peso(store.monthExpense),
                  borderColor: const Color(0xFF8CDDB0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.account_balance_wallet,
                  title: 'Income',
                  amount: _peso(store.monthIncome),
                  borderColor: const Color(0xFFF2B56E),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Spending Activity',
          child: _SpendingActivityCard(store: store),
        ),
        SectionCard(
          title: 'By Category',
          trailing: 'See all',
          onTrailingTap: onOpenStats,
          child: _CategoryGrid(store: store),
        ),
        SectionCard(
          title: 'Recent Transactions',
          child: _RecentTransactions(store: store),
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    const modeTitles = ['Year', 'Month', 'Week'];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
          decoration: const BoxDecoration(color: AppColors.ink),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 26),
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(modeTitles.length, (i) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => store.setStatsMode(i),
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: store.statsMode == i ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          modeTitles[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: store.statsMode == i ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SpendingTrendCard(store: store),
              const SizedBox(height: 12),
              const _HistoryCard(),
              const SizedBox(height: 12),
              _CategoryBreakdownCard(store: store),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ],
    );
  }
}

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 90),
      children: [
        const Text('Savings & Goals', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const Text('Track your financial targets', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF6467F8), Color(0xFF9A80F5)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Savings Total', style: TextStyle(color: Color(0xFFE9E5FF), fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                _peso(store.totalSavings),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 36),
              ),
              const SizedBox(height: 4),
              const Text('Updated just now', style: TextStyle(color: Color(0xFFE9E5FF))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Active Goals', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 8),
        GridView.builder(
          itemCount: store.goals.length + 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (_, i) {
            if (i == store.goals.length) {
              return const _AddGoalCard();
            }
            final goal = store.goals[i];
            return _GoalCard(goal: goal);
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            store.addNewGoal();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New goal added.')),
            );
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('+ Add New Saving'),
        ),
      ],
    );
  }
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 90),
      children: [
        const Text('Banks & Accounts', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const Text('All your accounts in one place', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        const Text('BANK ACCOUNTS', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...store.bankAccounts.map((x) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccountCard(account: x),
            )),
        OutlinedButton(
          onPressed: () {
            store.addBankAccount();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bank account added.')),
            );
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('+ Add Bank'),
        ),
        const SizedBox(height: 14),
        const Text('E-WALLETS', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...store.wallets.map((x) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccountCard(account: x),
            )),
        OutlinedButton(
          onPressed: () {
            store.addWalletAccount();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('E-wallet added.')),
            );
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('+ Add E-Wallet'),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final name = store.currentUser?.name ?? 'Juan dela Cruz';
    final email = store.currentUser?.email ?? 'juan@gmail.com';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1B1E3A), Color(0xFF163466)]),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFF253E67),
                child: Icon(Icons.person, size: 45, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 23)),
              const SizedBox(height: 3),
              Text(email, style: const TextStyle(color: Color(0xFFBEC9F5))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ProfileAction(
                icon: Icons.auto_awesome,
                title: 'Chat with AI',
                subtitle: 'Get comparison of your spendings',
                onTap: () {
                  final expense = store.monthExpense;
                  final income = store.monthIncome;
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('AI Summary (Mock)'),
                      content: Text(
                        'Income: ${_peso(income)}\nExpense: ${_peso(expense)}\n\nTip: Keep expenses below 60% of monthly income to improve savings.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _ProfileAction(
                icon: Icons.print,
                title: 'Print Transactions PDF',
                subtitle: 'Export savings history',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF export is mocked on front-end for now.')),
                  );
                },
              ),
              const SizedBox(height: 8),
              _ProfileAction(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Preferences & notifications',
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const _SettingsSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => store.logout(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool push = true;
  bool weekly = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 10),
            SwitchListTile(
              value: push,
              onChanged: (value) => setState(() => push = value),
              title: const Text('Push notifications'),
            ),
            SwitchListTile(
              value: weekly,
              onChanged: (value) => setState(() => weekly = value),
              title: const Text('Weekly report'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, required this.store});

  final AppStore store;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TxType _type = TxType.saving;
  String _category = 'Food';
  String _account = 'BDO';

  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['Food', 'Shopping', 'Transport', 'Health', 'Leisure', 'Others'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Row(
                  children: [
                    const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ToggleType(
                        icon: Icons.south_west,
                        label: 'Expense',
                        active: _type == TxType.expense,
                        onTap: () => setState(() => _type = TxType.expense),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleType(
                        icon: Icons.south_east,
                        label: 'Income',
                        active: _type == TxType.income,
                        onTap: () => setState(() => _type = TxType.income),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleType(
                        icon: Icons.savings,
                        label: 'Saving',
                        active: _type == TxType.saving,
                        onTap: () => setState(() => _type = TxType.saving),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Amount', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _SimpleInput(controller: _amountController, hint: '0.00'),
                const SizedBox(height: 10),
                const Text('Description', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _SimpleInput(controller: _descController, hint: 'e.g. Grab Food, Salary...'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories
                      .map((c) => ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                const Text('Account', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _account,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: widget.store.accounts
                      .map((a) => DropdownMenuItem(value: a.name, child: Text('${a.name} ${a.masked}')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _account = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final description = _descController.text.trim();
    if (amount == null || amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a valid amount and description.')),
      );
      return;
    }

    widget.store.addTransaction(
      type: _type,
      amount: amount,
      description: description,
      category: _category,
      account: _account,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved.')),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    required this.child,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
              const Spacer(),
              if (trailing != null)
                GestureDetector(
                  onTap: onTrailingTap,
                  child: Text(
                    trailing!,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E4EE)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.title,
    required this.amount,
    required this.borderColor,
  });

  final IconData icon;
  final String title;
  final String amount;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ink, size: 18),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SpendingActivityCard extends StatelessWidget {
  const _SpendingActivityCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('This Week', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFDAF7E8), borderRadius: BorderRadius.circular(20)),
              child: const Text('+12% vs last week', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MiniBarChart(bars: store.weeklyBars),
        const SizedBox(height: 12),
        const Text('This Month', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MonthSummary(label: 'Expenses', amount: _peso(store.monthExpense), color: AppColors.danger)),
            const SizedBox(width: 8),
            Expanded(child: _MonthSummary(label: 'Incomes', amount: _peso(store.monthIncome), color: AppColors.success)),
          ],
        ),
      ],
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.bars});

  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (i) {
          final bool active = i == 5;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: bars[i],
                  width: 20,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : const Color(0xFFDCD8F8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[i], style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E5EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 18)),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final entries = store.categoryTotals.entries.toList();
    return GridView.builder(
      itemCount: entries.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (_, i) {
        final e = entries[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7FB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E6F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    Text(_peso(e.value), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final latest = store.transactions.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E5EF)),
      ),
      child: Column(
        children: List.generate(latest.length, (i) {
          final tx = latest[i];
          final positive = tx.type == TxType.income;
          return Column(
            children: [
              _TxRow(
                name: tx.description,
                date: _shortDate(tx.date),
                amount: '${positive ? '+' : '-'}${_peso(tx.amount)}',
                positive: positive,
              ),
              if (i < latest.length - 1) const Divider(height: 0),
            ],
          );
        }),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.name,
    required this.date,
    required this.amount,
    required this.positive,
  });

  final String name;
  final String date;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(date, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: positive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingTrendCard extends StatelessWidget {
  const _SpendingTrendCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final modeLabel = ['Year 2026', 'April 2026', 'Week 15'][store.statsMode];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Spending Trend', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDAF7E8), borderRadius: BorderRadius.circular(20)),
                child: Text(modeLabel, style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 90, child: _LineTrend(mode: store.statsMode)),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Apr 1', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('Apr 7', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('Apr 14', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('Apr 21', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('Apr 30', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineTrend extends StatelessWidget {
  const _LineTrend({required this.mode});

  final int mode;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(mode: mode),
      child: const SizedBox.expand(),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.mode});

  final int mode;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final variants = [
      [0.75, 0.6, 0.68, 0.5, 0.56, 0.48, 0.52, 0.44, 0.42],
      [0.7, 0.56, 0.61, 0.34, 0.45, 0.29, 0.39, 0.31, 0.36],
      [0.8, 0.66, 0.7, 0.61, 0.58, 0.45, 0.51, 0.4, 0.34],
    ];

    final points = variants[mode];
    final path = Path()..moveTo(0, size.height * points.first);

    for (int i = 1; i < points.length; i++) {
      final x = (size.width / (points.length - 1)) * i;
      path.lineTo(x, size.height * points[i]);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => oldDelegate.mode != mode;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E4EE)),
      ),
      child: const Column(
        children: [
          _HistoryRow(year: 'Year 2025', amount: '-₱48,500'),
          Divider(height: 0),
          _HistoryRow(year: 'Year 2024', amount: '-₱32,000'),
          Divider(height: 0),
          _HistoryRow(year: 'Year 2023', amount: '-₱19,800'),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.year, required this.amount});

  final String year;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Text(year, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(amount, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final entries = store.categoryTotals.entries.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E4EE)),
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final max = entries.first.value == 0 ? 1 : entries.first.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 10),
            child: _BreakdownRow(
              label: e.key,
              amount: _peso(e.value),
              percent: (e.value / max).clamp(0, 1),
            ),
          );
        }),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.percent,
  });

  final String label;
  final String amount;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.category, size: 16),
        const SizedBox(width: 6),
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: percent,
              backgroundColor: const Color(0xFFE8E8EF),
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_peso(goal.current)} / ${_peso(goal.target)}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 11),
          ),
          const Spacer(),
          Text('Date due: ${goal.dueDate}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AddGoalCard extends StatelessWidget {
  const _AddGoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCFC8FF), style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text('Add Goal', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final FinanceAccount account;

  @override
  Widget build(BuildContext context) {
    final Color bg = account.isWallet ? const Color(0xFF17315B) : Colors.white;
    final Color fg = account.isWallet ? Colors.white : AppColors.text;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: account.isWallet ? Colors.transparent : const Color(0xFFE1E4EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: account.isWallet ? Colors.white12 : const Color(0xFFEAF6F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_balance, size: 18, color: account.isWallet ? Colors.white : AppColors.success),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
                Text(account.masked, style: TextStyle(color: account.isWallet ? Colors.white54 : AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            _peso(account.balance),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: account.isWallet ? const Color(0xFFAAA4FF) : AppColors.text,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E4EE)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ToggleType extends StatelessWidget {
  const _ToggleType({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: active ? const Color(0xFFFFF5D8) : Colors.white,
          border: Border.all(color: active ? const Color(0xFFE7C74B) : const Color(0xFFD2D6E1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SimpleInput extends StatelessWidget {
  const _SimpleInput({
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0B5C7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD2D6E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

String _peso(num value) {
  return '₱${value.toStringAsFixed(2)}';
}

String _shortDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Today';
  }
  final diff = now.difference(date).inDays;
  if (diff == 1) {
    return 'Yesterday';
  }
  return '${date.month}/${date.day}/${date.year}';
}
