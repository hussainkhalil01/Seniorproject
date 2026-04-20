import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/startchatting_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

enum _HomeSort { none, nearest, highestRated }

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _notificationsEnabled = true;
  Position? _userPosition;
  _HomeSort _sort = _HomeSort.none;
  String _searchQuery = '';
  Timer? _searchDebounce;
  final Map<String, double> _distCache = {};

  static const _kNotifKey = 'push_notifications';

  String _preferredDisplayName() {
    final fullName = currentUserDocument?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    final displayName = currentUserDisplayName.trim();
    if (displayName.isNotEmpty) return displayName;
    return 'there';
  }

  String _homeTitleForRole() {
    switch (currentUserDocument?.role) {
      case 'service_provider':
      case 'admin':
        return 'Provider Directory';
      default:
        return 'Explore Providers';
    }
  }

  bool _matchesSearch(UsersRecord contractor) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery;
    return contractor.fullName.toLowerCase().contains(q) ||
        contractor.displayName.toLowerCase().contains(q) ||
        contractor.email.toLowerCase().contains(q) ||
        contractor.phoneNumber.toLowerCase().contains(q);
  }

  Future<void> _loadUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low));
      if (mounted) {
        setState(() {
          _userPosition = pos;
          _distCache.clear();
        });
      }
    } catch (_) {}
  }

  double _distKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String _formatDist(UsersRecord c) {
    if (_userPosition == null || (c.latitude == 0.0 && c.longitude == 0.0)) {
      return '';
    }
    final km = _distKm(_userPosition!.latitude, _userPosition!.longitude,
        c.latitude, c.longitude);
    return km < 1
        ? '${(km * 1000).toStringAsFixed(0)} m away'
        : '${km.toStringAsFixed(1)} km away';
  }

  Future<void> _loadNotifPref() async {
    final prefs = await SharedPreferences.getInstance();
    final remoteValue =
        currentUserDocument?.snapshotData['push_notifications'] as bool?;
    if (mounted) {
      setState(() {
        _notificationsEnabled =
            remoteValue ?? prefs.getBool(_kNotifKey) ?? true;
      });
    }
  }

  Future<void> _toggleNotifications() async {
    final next = !_notificationsEnabled;
    setState(() => _notificationsEnabled = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, next);
    if (currentUserReference != null) {
      await currentUserReference!.set(
        {'push_notifications': next},
        SetOptions(merge: true),
      );
    }
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.secondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_repair_service_rounded,
                size: 40,
                color: theme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No service providers yet',
              style: GoogleFonts.ubuntu(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Service providers will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await authManager.refreshUser();
      await actions.trackUserPresence();
      if (currentUserEmailVerified ||
          currentUserDocument?.role == 'service_provider') {
        return;
      }
      if (!mounted) return;

      context.goNamed(
        EmailVerifyPageWidget.routeName,
        extra: <String, dynamic>{
          '__transition_info__': const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: Duration(milliseconds: 150),
          ),
        },
      );

      await authManager.sendEmailVerification();
      return;
    });

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _loadNotifPref();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: _model.columnController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primary,
                          FlutterFlowTheme.of(context).secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.of(context).padding.top + 20,
                        20,
                        16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, ${_preferredDisplayName()} ??',
                                    style: GoogleFonts.ubuntu(
                                      color: const Color(0xE6FFFFFF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _homeTitleForRole(),
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _toggleNotifications,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _notificationsEnabled
                                        ? Colors.white
                                        : const Color(0x33FFFFFF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _notificationsEnabled
                                          ? Colors.white
                                          : const Color(0x66FFFFFF),
                                    ),
                                  ),
                                  child: Icon(
                                    _notificationsEnabled
                                        ? Icons.notifications_rounded
                                        : Icons.notifications_off_outlined,
                                    color: _notificationsEnabled
                                        ? FlutterFlowTheme.of(context).primary
                                        : Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                            child: TextFormField(
                              controller: _model.textController,
                              focusNode: _model.textFieldFocusNode,
                              onChanged: (val) {
                                _searchDebounce?.cancel();
                                _searchDebounce = Timer(
                                  const Duration(milliseconds: 300),
                                  () => setState(() =>
                                      _searchQuery = val.trim().toLowerCase()),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by name, email, or phone...',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.ubuntu(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0,
                                    ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20,
                                ),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.ubuntu(),
                                    fontSize: 15,
                                    letterSpacing: 0,
                                  ),
                              validator: _model.textControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FlutterFlowTheme.of(context).primary,
                            const Color(0xFF1565C0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -24,
                              bottom: -24,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  color: Color(0x12FFFFFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 40,
                              top: -30,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Color(0x12FFFFFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Trusted Contractors\nAt Your Fingertips',
                                    style: GoogleFonts.ubuntu(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Verified professionals for every job',
                                    style: GoogleFonts.ubuntu(
                                      color: const Color(0xCCFFFFFF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Categories',
                      style: GoogleFonts.ubuntu(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      controller: _model.listViewController1,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _HomeCategory(
                          label: 'All',
                          icon: Icons.apps_rounded,
                          selected: FFAppState().selectedCategory.isEmpty,
                          onTap: () {
                            FFAppState().selectedCategory = '';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Contractors & Handymen',
                          icon: Icons.handyman_rounded,
                          selected: FFAppState().selectedCategory ==
                              'Contractors & Handymen',
                          onTap: () {
                            FFAppState().selectedCategory =
                                'Contractors & Handymen';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Plumbers',
                          icon: Icons.plumbing_rounded,
                          selected: FFAppState().selectedCategory == 'Plumbers',
                          onTap: () {
                            FFAppState().selectedCategory = 'Plumbers';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Electricians',
                          icon: Icons.electrical_services_rounded,
                          selected:
                              FFAppState().selectedCategory == 'Electricians',
                          onTap: () {
                            FFAppState().selectedCategory = 'Electricians';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Heating',
                          icon: Icons.local_fire_department_rounded,
                          selected: FFAppState().selectedCategory == 'Heating',
                          onTap: () {
                            FFAppState().selectedCategory = 'Heating';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Air Conditioning',
                          icon: Icons.ac_unit_rounded,
                          selected: FFAppState().selectedCategory ==
                              'Air Conditioning',
                          onTap: () {
                            FFAppState().selectedCategory = 'Air Conditioning';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Locksmiths',
                          icon: Icons.vpn_key_rounded,
                          selected:
                              FFAppState().selectedCategory == 'Locksmiths',
                          onTap: () {
                            FFAppState().selectedCategory = 'Locksmiths';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Painters',
                          icon: Icons.format_paint_rounded,
                          selected: FFAppState().selectedCategory == 'Painters',
                          onTap: () {
                            FFAppState().selectedCategory = 'Painters';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Tree Services',
                          icon: Icons.park_rounded,
                          selected:
                              FFAppState().selectedCategory == 'Tree Services',
                          onTap: () {
                            FFAppState().selectedCategory = 'Tree Services';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Movers',
                          icon: Icons.local_shipping_rounded,
                          selected: FFAppState().selectedCategory == 'Movers',
                          onTap: () {
                            FFAppState().selectedCategory = 'Movers';
                            safeSetState(() {});
                          },
                        ),
                      ]
                          .map((w) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: w,
                              ))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SortChip(
                              label: 'Nearest',
                              icon: Icons.location_on_rounded,
                              selected: _sort == _HomeSort.nearest,
                              onTap: () => setState(() => _sort =
                                  _sort == _HomeSort.nearest
                                      ? _HomeSort.none
                                      : _HomeSort.nearest),
                            ),
                            const SizedBox(width: 8),
                            _SortChip(
                              label: 'Highest Rated',
                              icon: Icons.star_rounded,
                              selected: _sort == _HomeSort.highestRated,
                              onTap: () => setState(() => _sort =
                                  _sort == _HomeSort.highestRated
                                      ? _HomeSort.none
                                      : _HomeSort.highestRated),
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              label: 'Map View',
                              icon: Icons.map_rounded,
                              onTap: () => context.pushNamed(
                                ContractorsMapPageWidget.routeName,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Text(
                      'Top Verified Contractors',
                      style: GoogleFonts.ubuntu(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                  ),
                  StreamBuilder<List<UsersRecord>>(
                    stream: queryUsersRecord(
                      queryBuilder: (q) {
                        q = q.where('role', isEqualTo: 'service_provider');
                        if (FFAppState().selectedCategory.isNotEmpty) {
                          q = q.where('categories',
                              arrayContains: FFAppState().selectedCategory);
                        }
                        return q;
                      },
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: SpinKitFadingCube(
                              color: FlutterFlowTheme.of(context).primary,
                              size: 36,
                            ),
                          ),
                        );
                      }
                      final contractors =
                          snapshot.data!.where(_matchesSearch).toList();
                      final sorted = List<UsersRecord>.from(contractors);
                      if (_sort == _HomeSort.none) {
                        sorted.sort((a, b) {
                          final ta = a.createdTime;
                          final tb = b.createdTime;
                          if (ta == null && tb == null) return 0;
                          if (ta == null) return 1;
                          if (tb == null) return -1;
                          return tb.compareTo(ta);
                        });
                      }
                      if (_sort == _HomeSort.nearest && _userPosition != null) {
                        final lat = _userPosition!.latitude;
                        final lng = _userPosition!.longitude;
                        sorted.sort((a, b) {
                          final da = _distCache.putIfAbsent(
                            a.reference.id,
                            () => _distKm(lat, lng, a.latitude, a.longitude),
                          );
                          final db = _distCache.putIfAbsent(
                            b.reference.id,
                            () => _distKm(lat, lng, b.latitude, b.longitude),
                          );
                          return da.compareTo(db);
                        });
                      } else if (_sort == _HomeSort.highestRated) {
                        sorted
                            .sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
                      }
                      if (contractors.isEmpty) {
                        return _buildEmptyPlaceholder(context);
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          final contractor = sorted[i];
                          final isMe =
                              contractor.reference == currentUserReference;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child:
                                _buildContractorCard(context, contractor, isMe),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContractorCard(
      BuildContext context, UsersRecord contractor, bool isMe) {
    final isCurrentUserProvider =
        currentUserDocument?.role == 'service_provider';
    return GestureDetector(
      onTap: () => context.pushNamed(
        ContractorProfilePageWidget.routeName,
        queryParameters: {
          'contractorRef': serializeParam(
            contractor.reference,
            ParamType.DocumentReference,
          ),
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: contractor.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: contractor.photoUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).accent1,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).accent1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 32,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contractor.fullName.isNotEmpty
                                  ? contractor.fullName
                                  : contractor.displayName,
                              style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contractor.title.isNotEmpty
                            ? contractor.title
                            : 'Service Provider',
                        style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC107), size: 15),
                              const SizedBox(width: 3),
                              Text(
                                contractor.ratingAvg > 0
                                    ? '${contractor.ratingAvg.toStringAsFixed(1)} (${contractor.ratingCount})'
                                    : 'No reviews',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                            ],
                          ),
                          if (_formatDist(contractor).isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 13,
                                    color:
                                        FlutterFlowTheme.of(context).secondary),
                                const SizedBox(width: 2),
                                Text(
                                  _formatDist(contractor),
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isMe && !isCurrentUserProvider) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  await showDialog(
                    barrierColor: Colors.transparent,
                    barrierDismissible: false,
                    context: context,
                    builder: (dialogContext) => Dialog(
                      elevation: 0,
                      insetPadding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(dialogContext).unfocus();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        child: SizedBox(
                          height: 300,
                          width: double.infinity,
                          child:
                              StartchattingWidget(contractorRecord: contractor),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Chat Now',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const iconColor = Color(0xFFF4A026);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? theme.primary : theme.alternate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 1),
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCategory extends StatelessWidget {
  const _HomeCategory({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFFF4A026),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.alternate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFF4A026)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
