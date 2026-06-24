import 'package:admin_dashboard/core/di/setup_locator.dart';
import 'package:admin_dashboard/features/users/presentation/controllers/device_controller.dart';
import 'package:admin_dashboard/features/users/presentation/controllers/users_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/routes/app_routes.dart';
import 'core/services/auth_service.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/admin_login_page.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/dashboard/presentation/pages/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthController(
            loginUseCase: LoginUseCase(
              AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSource()),
            ),
            logoutUseCase: LogoutUseCase(
              AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSource()),
            ),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DeviceManagementController()),
      ],
      child: MaterialApp(
        title: 'WeightCare Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Cairo',
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        themeMode: ThemeMode.system,
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate, // ✅ مهم جداً
          GlobalWidgetsLocalizations.delegate, // ✅ مهم جداً
          GlobalCupertinoLocalizations.delegate, // ✅ مهم جداً
        ],
        initialRoute: '/',
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const AuthCheckWrapper(),
        );
      case AppRoutes.adminLogin:
        return MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
        );
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const AuthCheckWrapper(),
        );
    }
  }
}

class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.adminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
