import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/connectivity_wrapper.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chats_page_model.dart';
export 'chats_page_model.dart';

// ─────────────────────────────────────────────────────────
//  Quick Service Request categories
// ─────────────────────────────────────────────────────────
const _kServiceCategories = [
  'Contractors & Handymen',
  'Plumbers',
  'Electricians',
  'Heating',
  'Air Conditioning',
  'Locksmiths',
  'Painters',
  'Tree Services',
  'Movers',
];

// ── AI Assistant pinned tile ──────────────────────────────
class _AiAssistantTile extends StatelessWidget {
  const _AiAssistantTile();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => context.pushNamed(
        AiChatPageWidget.routeName,
        extra: <String, dynamic>{
          '__transition_info__': const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: Duration(milliseconds: 150),
          ),
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Assistant',
                        style: GoogleFonts.ubuntu(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'AI',
                          style: GoogleFonts.ubuntu(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find the best contractor for your needs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ubuntu(
                      color: theme.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatsPageWidget extends StatefulWidget {
  const ChatsPageWidget({super.key});

  static String routeName = 'ChatsPage';
  static String routePath = '/chatsPage';

  @override
  State<ChatsPageWidget> createState() => _ChatsPageWidgetState();
}

class _ChatsPageWidgetState extends State<ChatsPageWidget> {
  late ChatsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, String> _titleCache = {};
  final Map<String, Future<String>> _titleFetches = {};
  final Map<String, DateTime> _titleCacheTime = {};
  static const _kTitleCacheTtl = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatsPageModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await authManager.refreshUser();
      if (!mounted) return;
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

      try {
        await authManager.sendEmailVerification();
      } catch (e) {
        debugPrint('[ChatsPage] sendEmailVerification error: $e');
      }
      return;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isProvider = currentUserDocument?.role == 'service_provider';
    return Center(
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
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: theme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No conversations yet',
            style: GoogleFonts.ubuntu(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isProvider
                ? 'Messages from clients will appear here.'
                : 'Messages with service providers will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickServiceRequest(BuildContext ctx) {
    final theme = FlutterFlowTheme.of(ctx);
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String? selectedCategory;
    String locationLabel = 'Detecting...';
    bool loadingLocation = true;

    bool sheetMounted = true;

    Future<void> detectLocation(StateSetter setSheetState) async {
      setSheetState(() { loadingLocation = true; });
      try {
        final svc = await Geolocator.isLocationServiceEnabled();
        if (!svc) {
          if (sheetMounted) setSheetState(() { locationLabel = 'Location unavailable'; loadingLocation = false; });
          return;
        }
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          if (sheetMounted) setSheetState(() { locationLabel = 'Permission denied'; loadingLocation = false; });
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
        if (sheetMounted) {
          setSheetState(() {
            locationLabel = '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}';
            loadingLocation = false;
          });
        }
      } catch (_) {
        if (sheetMounted) setSheetState(() { locationLabel = 'Could not detect'; loadingLocation = false; });
      }
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          if (loadingLocation && locationLabel == 'Detecting...') {
            loadingLocation = false; // prevent re-entry
            WidgetsBinding.instance.addPostFrameCallback((_) {
              detectLocation(setSheetState);
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: theme.alternate,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note_rounded, color: theme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text('Quick Service Request',
                            style: GoogleFonts.ubuntu(
                                fontSize: 18, fontWeight: FontWeight.w700, color: theme.primaryText)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Describe what you need and we\'ll find the best contractors for you.',
                        style: GoogleFonts.ubuntu(fontSize: 13, color: theme.secondaryText, height: 1.4)),
                    const SizedBox(height: 20),

                    _sheetLabel(theme, 'What do you need?', required: true),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.ubuntu(fontSize: 14, color: theme.primaryText),
                      decoration: _sheetInputDecor(theme, 'e.g. AC not cooling, water leak in kitchen...'),
                    ),
                    const SizedBox(height: 16),

                    _sheetLabel(theme, 'Category'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.alternate),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          hint: Text('Auto-detect from description',
                              style: GoogleFonts.ubuntu(fontSize: 14, color: theme.secondaryText)),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.secondaryText),
                          dropdownColor: theme.secondaryBackground,
                          items: _kServiceCategories.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: GoogleFonts.ubuntu(fontSize: 14, color: theme.primaryText)),
                          )).toList(),
                          onChanged: (v) => setSheetState(() => selectedCategory = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sheetLabel(theme, 'Budget (Optional)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: budgetCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.ubuntu(fontSize: 14, color: theme.primaryText),
                                decoration: _sheetInputDecor(theme, 'e.g. 500 BHD'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sheetLabel(theme, 'Location'),
                              const SizedBox(height: 6),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: theme.primaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.alternate),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      loadingLocation ? Icons.my_location_rounded : Icons.location_on_rounded,
                                      size: 16,
                                      color: loadingLocation ? theme.secondaryText : theme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        locationLabel,
                                        style: GoogleFonts.ubuntu(
                                          fontSize: 12,
                                          color: loadingLocation ? theme.secondaryText : theme.primaryText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final desc = descCtrl.text.trim();
                          if (desc.isEmpty) return;
                          final parts = <String>[desc];
                          if (selectedCategory != null) parts.add(selectedCategory!);
                          if (budgetCtrl.text.trim().isNotEmpty) parts.add('budget ${budgetCtrl.text.trim()}');
                          parts.add('nearest');
                          final composedQuery = parts.join(', ');
                          Navigator.pop(sheetCtx);
                          context.pushNamed(
                            AiChatPageWidget.routeName,
                            queryParameters: {'initialQuery': composedQuery},
                            extra: <String, dynamic>{
                              '__transition_info__': const TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.fade,
                                duration: Duration(milliseconds: 150),
                              ),
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.smart_toy_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Find Contractors',
                                style: GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => sheetMounted = false);
  }

  Widget _sheetLabel(FlutterFlowTheme theme, String text, {bool required = false}) {
    return Row(
      children: [
        Text(text, style: GoogleFonts.ubuntu(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryText)),
        if (required)
          Text(' *', style: GoogleFonts.ubuntu(fontSize: 13, fontWeight: FontWeight.w600, color: theme.error)),
      ],
    );
  }

  InputDecoration _sheetInputDecor(FlutterFlowTheme theme, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.ubuntu(fontSize: 14, color: theme.secondaryText),
      filled: true,
      fillColor: theme.primaryBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.alternate),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.alternate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
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
          body: ConnectivityWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Gradient header ──────────────────────────
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
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Row(
                        children: [
                          StreamBuilder<UsersRecord>(
                            stream: UsersRecord.getDocument(currentUserReference!),
                            builder: (context, snap) {
                              final photo = snap.data?.photoUrl ?? '';
                              return Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: photo.isNotEmpty
                                      ? Image.network(photo,
                                          width: 36, height: 36, fit: BoxFit.cover)
                                      : const Icon(Icons.person_rounded,
                                          color: Colors.white70, size: 20),
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Chats',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.ubuntu(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (currentUserDocument?.role != 'service_provider' &&
                              currentUserDocument?.role != 'admin' &&
                              currentUserDocument?.role != 'support')
                            Material(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showQuickServiceRequest(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.edit_outlined,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Search bar ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.ubuntu(
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 20,
                        ),
                      ),
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                  ),
                ),
                // ── Chat list ────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<ChatsRecord>>(
                    stream: queryChatsRecord(
                      queryBuilder: (q) =>
                          q.orderBy('last_message_time', descending: true).limit(100),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: SpinKitFadingCube(
                            color: FlutterFlowTheme.of(context).primary,
                            size: 40,
                          ),
                        );
                      }
                      final chats = snapshot.data!
                          .where((c) =>
                              (currentUserReference == c.userA ||
                              currentUserReference == c.userB) &&
                              !c.deletedBy.contains(currentUserUid) &&
                              (_searchQuery.isEmpty ||
                                  (currentUserReference == c.userA
                                          ? c.userBName
                                          : c.userAName)
                                      .toLowerCase()
                                      .contains(_searchQuery)))
                          .toList();

                      if (chats.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _AiAssistantTile(),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: FlutterFlowTheme.of(context)
                                  .alternate
                                  .withValues(alpha: 0.5),
                            ),
                             Expanded(
                              child: _buildEmptyPlaceholder(context),
                             ),
                           ],
                         );
                      }

                      final now = DateTime.now();
                      return ListView.builder(
                        controller: _model.columnController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: chats.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const _AiAssistantTile();
                          }
                          if (index == 1) {
                            return Divider(
                              height: 1,
                              thickness: 1,
                              color: FlutterFlowTheme.of(context)
                                  .alternate
                                  .withValues(alpha: 0.5),
                            );
                          }
                          final chat = chats[index - 2];
                          final isUserA =
                              currentUserReference == chat.userA;
                          final otherName =
                              isUserA ? chat.userBName : chat.userAName;
                          final otherRef =
                              isUserA ? chat.userB : chat.userA;
                          final otherRefId = otherRef?.id ?? '';
                          final isUnread =
                              chat.lastMessageSentBy != currentUserReference &&
                              !chat.lastMessageSeenBy
                                  .contains(currentUserReference);
                          final msgTime = chat.lastMessageTime;
                          String timeStr;
                          if (msgTime == null) {
                            timeStr = '';
                          } else {
                            final today = DateTime(now.year, now.month, now.day);
                            final msgDate = DateTime(msgTime.year, msgTime.month, msgTime.day);
                            final daysDiff = today.difference(msgDate).inDays;
                            if (daysDiff == 0) {
                              timeStr = dateTimeFormat("jm", msgTime,
                                  locale: FFLocalizations.of(context)
                                          .languageShortCode ??
                                      FFLocalizations.of(context).languageCode);
                            } else if (daysDiff == 1) {
                              timeStr = 'Yesterday';
                            } else if (daysDiff < 7) {
                              timeStr = '${daysDiff}d ago';
                            } else if (daysDiff < 30) {
                              timeStr = '${(daysDiff / 7).floor()}w ago';
                            } else {
                              timeStr = dateTimeFormat("MMMd", msgTime,
                                  locale: FFLocalizations.of(context)
                                          .languageShortCode ??
                                      FFLocalizations.of(context).languageCode);
                            }
                          }

                          return InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () => context.pushNamed(
                                MessagePageWidget.routeName,
                                queryParameters: {
                                  'chatRef': serializeParam(
                                    chat.reference,
                                    ParamType.DocumentReference,
                                  ),
                                }.withoutNulls,
                                extra: <String, dynamic>{
                                  '__transition_info__': const TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 150),
                                  ),
                                },
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context).alternate,
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: (() {
                                          final photo = isUserA ? chat.userBPhoto : chat.userAPhoto;
                                          return photo.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: photo,
                                                  width: 54,
                                                  height: 54,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => Container(
                                                    color: FlutterFlowTheme.of(context).accent1,
                                                    child: Icon(Icons.person_rounded,
                                                        color: FlutterFlowTheme.of(context).primary,
                                                        size: 26),
                                                  ),
                                                )
                                              : Container(
                                                  color: FlutterFlowTheme.of(context).accent1,
                                                  child: Icon(Icons.person_rounded,
                                                      color: FlutterFlowTheme.of(context).primary,
                                                      size: 26),
                                                );
                                        })(),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  otherName,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.ubuntu(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                timeStr,
                                                style: GoogleFonts.ubuntu(
                                                  fontSize: 12,
                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                ),
                                              ),
                                            ],
                                          ),
                                          FutureBuilder<String>(
                                            future: (_titleCache.containsKey(otherRefId) &&
                                                    _titleCacheTime[otherRefId] != null &&
                                                    DateTime.now().difference(_titleCacheTime[otherRefId]!) < _kTitleCacheTtl)
                                                ? Future.value(_titleCache[otherRefId]!)
                                                : (otherRef != null
                                                    ? _titleFetches.putIfAbsent(
                                                        otherRefId,
                                                        () => UsersRecord.getDocumentOnce(otherRef)
                                                            .then((u) {
                                                              _titleCache[otherRefId] = u.title;
                                                              _titleCacheTime[otherRefId] = DateTime.now();
                                                              _titleFetches.remove(otherRefId);
                                                              return u.title;
                                                            }),
                                                      )
                                                    : Future.value('')),
                                            builder: (context, snap) {
                                              final title = snap.data ?? '';
                                              if (title.isEmpty) return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.ubuntu(
                                                    fontWeight: FontWeight.w500,
                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  chat.lastMessage,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.ubuntu(
                                                    fontWeight: isUnread
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                    color: isUnread
                                                        ? FlutterFlowTheme.of(context).primaryText
                                                        : FlutterFlowTheme.of(context).secondaryText,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(context).primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      '1',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
