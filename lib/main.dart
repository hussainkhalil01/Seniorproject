import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/firebase_auth/firebase_user_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';
import 'notifications/in_app_notification_center.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  GoRouter.optionURLReflectsImperativeAPIs = true;

  await initFirebase();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

abstract class MyAppController {
  void setLocale(String language);
  void setThemeMode(ThemeMode mode);
  String getRoute([RouteMatch? routeMatch]);
  List<String> getRouteStack();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static MyAppController of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver
    implements MyAppController {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  @override
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  @override
  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    InAppNotificationCenter.instance.configure(_scaffoldMessengerKey);
    userStream = amanBuildFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
        final uid = user.authUserInfo.uid;
        InAppNotificationCenter.instance.onAuthChanged(uid);
        if (user.loggedIn) {
          currentUserReference?.set(
            {'is_online': true},
            SetOptions(merge: true),
          );
        }
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    authUserSub.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!loggedIn || currentUserReference == null) return;
    if (state == AppLifecycleState.resumed) {
      currentUserReference!.set({'is_online': true}, SetOptions(merge: true));
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      currentUserReference!.set({
        'is_online': false,
        'last_active_time': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  @override
  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp.router(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'AmanBuild',
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackMaterialLocalizationDelegate(),
          FallbackCupertinoLocalizationDelegate(),
        ],
        locale: _locale,
        supportedLocales: const [
          Locale('en'),
        ],
        theme: ThemeData(
          brightness: Brightness.light,
          scrollbarTheme: ScrollbarThemeData(
            interactive: true,
            thickness: WidgetStateProperty.all(5.0),
            radius: const Radius.circular(10.0),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.dragged)) {
                return const Color(0x981f4f8b);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x981f4f8b);
              }
              return const Color(0x981f4f8b);
            }),
            minThumbLength: 48.0,
            crossAxisMargin: 4.0,
            mainAxisMargin: 6.0,
          ),
          useMaterial3: false,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scrollbarTheme: ScrollbarThemeData(
            interactive: true,
            thickness: WidgetStateProperty.all(5.0),
            radius: const Radius.circular(10.0),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.dragged)) {
                return const Color(0x981f4f8b);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x981f4f8b);
              }
              return const Color(0x981f4f8b);
            }),
            minThumbLength: 48.0,
            crossAxisMargin: 4.0,
            mainAxisMargin: 6.0,
          ),
          useMaterial3: false,
        ),
        themeMode: _themeMode,
        routerConfig: _router,
      ),
    );
  }
}

class NavBarPage extends StatefulWidget {
  const NavBarPage({
    super.key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  });

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'HomePage';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = currentUserDocument?.role == 'admin';
    final tabs = {
      'HomePage': const HomePageWidget(),
      'ChatsPage': const ChatsPageWidget(),
      if (isAdmin)
        'AdminDashboard': const AdminDashboardPage()
      else
        'MyOrdersPage': const MyOrdersPageWidget(),
      'ProfilePage': const ProfilePageWidget(),
    };
    if (!tabs.containsKey(_currentPageName)) {
      _currentPageName = tabs.keys.first;
    }
    final currentIndex = tabs.keys.toList().indexOf(_currentPageName);

    return AuthUserStreamWidget(
      builder: (context) => Scaffold(
        resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
        body: _currentPage ?? tabs[_currentPageName],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex >= 0 ? currentIndex : 0,
          onTap: (i) => safeSetState(() {
            _currentPage = null;
            _currentPageName = tabs.keys.toList()[i];
          }),
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          selectedItemColor: FlutterFlowTheme.of(context).secondary,
          unselectedItemColor: FlutterFlowTheme.of(context).secondaryText,
          selectedLabelStyle: GoogleFonts.ubuntu(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.ubuntu(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.home_rounded,
                size: 24.0,
              ),
              label: 'Home',
              tooltip: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.chat_rounded,
                size: 24.0,
              ),
              label: 'Chats',
              tooltip: '',
            ),
            if (isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(
                  Icons.dashboard_rounded,
                  size: 24.0,
                ),
                label: 'Dashboard',
                tooltip: '',
              )
            else
              BottomNavigationBarItem(
                icon: const Icon(
                  Icons.receipt_long_rounded,
                  size: 24.0,
                ),
                label: currentUserDocument?.role == 'service_provider'
                    ? 'Orders'
                    : 'My Orders',
                tooltip: '',
              ),
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.person_rounded,
                size: 24.0,
              ),
              label: 'Profile',
              tooltip: '',
            )
          ],
        ),
      ),
    );
  }
}
