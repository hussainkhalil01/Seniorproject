import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chats_page_model.dart';
export 'chats_page_model.dart';

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
      if (currentUserEmailVerified) {
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
                      Container(
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
                              currentUserReference == c.userA ||
                              currentUserReference == c.userB)
                          .toList();

                      if (chats.isEmpty) {
                        return Center(
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
                        );
                      }

                      return ListView.builder(
                        controller: _model.columnController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
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

                          return StreamBuilder<UsersRecord>(
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
