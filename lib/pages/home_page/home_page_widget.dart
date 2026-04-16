import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
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

  static const _kNotifKey = 'push_notifications';

  Future<void> _loadUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low));
      if (mounted) setState(() => _userPosition = pos);
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
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool(_kNotifKey) ?? true;
      });
    }
  }

  Future<void> _toggleNotifications() async {
    final next = !_notificationsEnabled;
    setState(() => _notificationsEnabled = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, next);
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
            top: true,
            child: SingleChildScrollView(
              controller: _model.columnController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello 👋',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.ubuntu(),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 14,
                                    letterSpacing: 0,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Find Services',
                              style: GoogleFonts.ubuntu(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color:
                                    FlutterFlowTheme.of(context).primaryText,
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
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _notificationsEnabled
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                            child: Icon(
                              _notificationsEnabled
                                  ? Icons.notifications_rounded
                                  : Icons.notifications_off_outlined,
                              color: _notificationsEnabled
                                  ? Colors.white
                                  : FlutterFlowTheme.of(context).secondaryText,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── SEARCH ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
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
                              decoration: InputDecoration(
                                hintText: 'Search services...',
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
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── HERO BANNER ───────────────────────────────────
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

                  // ── CATEGORIES ────────────────────────────────────
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
                          selected: FFAppState().selectedCategory.isEmpty,
                          onTap: () {
                            FFAppState().selectedCategory = '';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Contractors & Handymen',
                          selected:
                              FFAppState().selectedCategory == 'Contractors & Handymen',
                          onTap: () {
                            FFAppState().selectedCategory = 'Contractors & Handymen';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Plumbers',
                          selected:
                              FFAppState().selectedCategory == 'Plumbers',
                          onTap: () {
                            FFAppState().selectedCategory = 'Plumbers';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Electricians',
                          selected:
                              FFAppState().selectedCategory == 'Electricians',
                          onTap: () {
                            FFAppState().selectedCategory = 'Electricians';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Heating',
                          selected:
                              FFAppState().selectedCategory == 'Heating',
                          onTap: () {
                            FFAppState().selectedCategory = 'Heating';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Air Conditioning',
                          selected:
                              FFAppState().selectedCategory == 'Air Conditioning',
                          onTap: () {
                            FFAppState().selectedCategory = 'Air Conditioning';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Locksmiths',
                          selected:
                              FFAppState().selectedCategory == 'Locksmiths',
                          onTap: () {
                            FFAppState().selectedCategory = 'Locksmiths';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Painters',
                          selected:
                              FFAppState().selectedCategory == 'Painters',
                          onTap: () {
                            FFAppState().selectedCategory = 'Painters';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Tree Services',
                          selected:
                              FFAppState().selectedCategory == 'Tree Services',
                          onTap: () {
                            FFAppState().selectedCategory = 'Tree Services';
                            safeSetState(() {});
                          },
                        ),
                        _HomeCategory(
                          label: 'Movers',
                          selected:
                              FFAppState().selectedCategory == 'Movers',
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

                  // ── CONTRACTORS HEADER ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Top Verified Contractors',
                          style: GoogleFonts.ubuntu(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pushNamed(
                            ContractorsMapPageWidget.routeName,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.map_rounded,
                                    size: 15,
                                    color:
                                        FlutterFlowTheme.of(context).primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Map View',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── SORT CHIPS ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
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
                      ],
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
                        return q.orderBy('created_time', descending: true);
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
                      final contractors = snapshot.data!;
                      // Apply sort
                      final sorted = List<UsersRecord>.from(contractors);
                      if (_sort == _HomeSort.nearest && _userPosition != null) {
                        sorted.sort((a, b) {
                          final da = _distKm(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                              a.latitude,
                              a.longitude);
                          final db = _distKm(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                              b.latitude,
                              b.longitude);
                          return da.compareTo(db);
                        });
                      } else if (_sort == _HomeSort.highestRated) {
                        sorted.sort(
                            (a, b) => b.ratingAvg.compareTo(a.ratingAvg));
                      }
                      if (contractors.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText
                                      .withValues(alpha: 0.35),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No contractors found',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.ubuntu(),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Column(
                          children: sorted.map((contractor) {
                            final isMe =
                                contractor.reference == currentUserReference;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildContractorCard(
                                  context, contractor, isMe),
                            );
                          }).toList(),
                        ),
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
        child: Row(
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
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFC107), size: 15),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          contractor.ratingAvg > 0
                              ? '${contractor.ratingAvg.toStringAsFixed(1)} (${contractor.ratingCount})'
                              : 'No reviews',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_formatDist(contractor).isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_rounded,
                            size: 13,
                            color: FlutterFlowTheme.of(context).primary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            _formatDist(contractor),
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!isMe && !isCurrentUserProvider)
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
                          child: StartchattingWidget(
                              contractorRecord: contractor),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Chat Now',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sort Chip ─────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? theme.primary : theme.alternate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : theme.secondaryText),
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

// ─── Category Chip ─────────────────────────────────────────────────────────

class _HomeCategory extends StatelessWidget {
  const _HomeCategory({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
        child: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
      ),
    );
  }
}
