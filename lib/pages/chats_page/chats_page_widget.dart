import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/connectivity_wrapper.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
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
      onTap: () => context.pushNamed(AiChatPageWidget.routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gradient bot avatar
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
                        style: theme.bodyLarge.override(
                          font: GoogleFonts.ubuntu(
                              fontWeight: FontWeight.w600),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
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
                    style: theme.bodySmall.override(
                      font: GoogleFonts.ubuntu(),
                      color: theme.secondaryText,
                      fontSize: 13,
                      letterSpacing: 0,
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatsPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await authManager.refreshUser();
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
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<bool> _confirmDeleteChat(
      BuildContext ctx, String otherName, DocumentReference chatRef) async {
    final theme = FlutterFlowTheme.of(ctx);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Chat',
            style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w700, color: theme.primaryText)),
        content: Text(
          'Delete your conversation with $otherName?\n\nThis will remove it from your chat list. The other person can still see the conversation.',
          style: GoogleFonts.ubuntu(
              fontSize: 14, color: theme.secondaryText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel',
                style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600, color: theme.secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(
              backgroundColor: theme.error.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete',
                style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600, color: theme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await chatRef.update({
        'deleted_by': FieldValue.arrayUnion([currentUserUid]),
      });
      return true;
    }
    return false;
  }

  void _showQuickServiceRequest(BuildContext ctx) {
    final theme = FlutterFlowTheme.of(ctx);
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String? selectedCategory;
    String locationLabel = 'Detecting...';
    bool loadingLocation = true;

    // Get location
    Future<void> detectLocation(StateSetter setSheetState) async {
      try {
        final svc = await Geolocator.isLocationServiceEnabled();
        if (!svc) {
          if (ctx.mounted) setSheetState(() { locationLabel = 'Location unavailable'; loadingLocation = false; });
          return;
        }
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          if (ctx.mounted) setSheetState(() { locationLabel = 'Permission denied'; loadingLocation = false; });
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
        if (ctx.mounted) {
          setSheetState(() {
            locationLabel = '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}';
            loadingLocation = false;
          });
        }
      } catch (_) {
        if (ctx.mounted) setSheetState(() { locationLabel = 'Could not detect'; loadingLocation = false; });
      }
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          // Trigger location detect once
          if (loadingLocation && locationLabel == 'Detecting...') {
            detectLocation(setSheetState);
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
                    // Drag handle
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
                    // Title
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
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

                    // ── What do you need? ──
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

                    // ── Category ──
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

                    // ── Budget + Location row ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sheetLabel(theme, 'Budget (optional)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: budgetCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.ubuntu(fontSize: 14, color: theme.primaryText),
                                decoration: _sheetInputDecor(theme, 'e.g. 500 SAR'),
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

                    // ── Submit ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final desc = descCtrl.text.trim();
                          if (desc.isEmpty) return;
                          // Build query string
                          final parts = <String>[desc];
                          if (selectedCategory != null) parts.add(selectedCategory!);
                          if (budgetCtrl.text.trim().isNotEmpty) parts.add('budget ${budgetCtrl.text.trim()}');
                          parts.add('nearest');
                          final composedQuery = parts.join(', ');
                          Navigator.pop(sheetCtx);
                          context.pushNamed(
                            AiChatPageWidget.routeName,
                            queryParameters: {'initialQuery': composedQuery},
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
    );
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
            child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      // Current user avatar
                      StreamBuilder<UsersRecord>(
                        stream: UsersRecord.getDocument(currentUserReference!),
                        builder: (context, snap) {
                          final photo = snap.data?.photoUrl ?? '';
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: photo.isNotEmpty
                                  ? Image.network(photo,
                                      width: 40, height: 40, fit: BoxFit.cover)
                                  : Icon(Icons.person_rounded,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 20),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Messages',
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                font: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.bold),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showQuickServiceRequest(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Search bar ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 14, right: 8),
                          child: Icon(Icons.search_rounded,
                              color: Color(0xFF9AA5B4), size: 20),
                        ),
                        Text(
                          'Search...',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                font: GoogleFonts.ubuntu(),
                                color: const Color(0xFF9AA5B4),
                                letterSpacing: 0,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Chat list ────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<ChatsRecord>>(
                    stream: queryChatsRecord(
                      queryBuilder: (q) =>
                          q.orderBy('last_message_time', descending: true),
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
                              !c.deletedBy.contains(currentUserUid))
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
                                  .withOpacity(.5),
                            ),
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded,
                                        size: 60,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText
                                            .withOpacity(0.35)),
                                    const SizedBox(height: 14),
                                    Text('No conversations yet',
                                        style: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.ubuntu(),
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              letterSpacing: 0,
                                            )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        controller: _model.columnController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: chats.length + 2, // +2 for AI tile + divider
                        itemBuilder: (context, index) {
                          // First item: AI Assistant tile
                          if (index == 0) {
                            return const _AiAssistantTile();
                          }
                          // Second item: divider
                          if (index == 1) {
                            return Divider(
                              height: 1,
                              thickness: 1,
                              color: FlutterFlowTheme.of(context)
                                  .alternate
                                  .withOpacity(.5),
                            );
                          }
                          final chat = chats[index - 2];
                          final isUserA =
                              currentUserReference == chat.userA;
                          final otherRef =
                              isUserA ? chat.userB : chat.userA;
                          final otherName =
                              isUserA ? chat.userBName : chat.userAName;
                          final otherPhoto =
                              isUserA ? chat.userBPhoto : chat.userAPhoto;
                          final isUnread =
                              chat.lastMessageSentBy != currentUserReference &&
                              !chat.lastMessageSeenBy
                                  .contains(currentUserReference);
                          final msgTime = chat.lastMessageTime;
                          final now = DateTime.now();
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

                          return Dismissible(
                            key: ValueKey(chat.reference.path),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDeleteChat(
                                context, otherName, chat.reference),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).error,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delete_rounded,
                                      color: Colors.white, size: 24),
                                  const SizedBox(height: 2),
                                  Text('Delete',
                                      style: GoogleFonts.ubuntu(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ),
                            child: StreamBuilder<UsersRecord>(
                            stream: otherRef != null
                                ? UsersRecord.getDocument(otherRef)
                                : const Stream.empty(),
                            builder: (context, userSnap) {
                              final otherTitle =
                                  userSnap.data?.title ?? '';

                              return InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () => context.pushNamed(
                                  MessageWidget.routeName,
                                  queryParameters: {
                                    'chatRef': serializeParam(
                                      chat.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: otherPhoto.isNotEmpty
                                              ? Image.network(otherPhoto,
                                                  width: 54,
                                                  height: 54,
                                                  fit: BoxFit.cover)
                                              : Container(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    size: 26,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Text content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Name + time row
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    otherName,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyLarge
                                                            .override(
                                                              font: GoogleFonts
                                                                  .ubuntu(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing: 0,
                                                            ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  timeStr,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodySmall
                                                      .override(
                                                        font:
                                                            GoogleFonts.ubuntu(),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryText,
                                                        fontSize: 12,
                                                        letterSpacing: 0,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            // Title (profession)
                                            if (otherTitle.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                otherTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.ubuntu(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      fontSize: 12,
                                                      letterSpacing: 0,
                                                    ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            // Last message + unread badge
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    chat.lastMessage,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .override(
                                                              font: GoogleFonts
                                                                  .ubuntu(
                                                                      fontWeight:
                                                                          isUnread
                                                                              ? FontWeight.w500
                                                                              : FontWeight.normal),
                                                              color: isUnread
                                                                  ? FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText
                                                                  : FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                              fontSize: 13,
                                                              letterSpacing: 0,
                                                            ),
                                                  ),
                                                ),
                                                if (isUnread)
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        '1',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
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
      ),
    );
  }
}
