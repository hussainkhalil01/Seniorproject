import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'startchatting_model.dart';
export 'startchatting_model.dart';

class StartchattingWidget extends StatefulWidget {
  const StartchattingWidget({
    super.key,
    required this.contractorRecord,
  });

  final UsersRecord contractorRecord;

  @override
  State<StartchattingWidget> createState() => _StartchattingWidgetState();
}

class _StartchattingWidgetState extends State<StartchattingWidget> {
  late StartchattingModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StartchattingModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: const AlignmentDirectional(0.0, 0.0),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 530.0),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 3.0,
                  color: Color(0x33000000),
                  offset: Offset(0.0, 1.0),
                ),
              ],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primaryBackground,
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        24.0, 16.0, 24.0, 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          size: 44.0,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Start Chat',
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                                font: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontStyle,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 12.0, 0.0, 12.0),
                          child: Text(
                            'Do you want to start chatting with this contractor?',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                        Divider(
                          thickness: 0.5,
                          color: FlutterFlowTheme.of(context).accent4,
                        ),
                      ].divide(const SizedBox(height: 1.0)),
                    ),
                  ),
                  Align(
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 12.0, 0.0),
                          child: FFButtonWidget(
                            onPressed: () async {
                              _model.existingChats =
                                  await queryChatsRecordOnce(
                                queryBuilder: (chatsRecord) =>
                                    chatsRecord.where(
                                  'chat_key',
                                  isEqualTo:
                                      '${currentUserUid}_${widget.contractorRecord.uid}',
                                ),
                                limit: 1,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              if (_model.existingChats != null &&
                                  (_model.existingChats)!.isNotEmpty) {
                                Navigator.pop(context);
                                context.pushNamed(
                                  MessagePageWidget.routeName,
                                  queryParameters: {
                                    'chatRef': serializeParam(
                                      _model.existingChats
                                          ?.elementAtOrNull(0)
                                          ?.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                );
                              } else {
                                var chatsRecordReference =
                                    ChatsRecord.collection.doc();
                                await chatsRecordReference
                                    .set(createChatsRecordData(
                                  userA: currentUserReference,
                                  userB: widget.contractorRecord.reference,
                                  lastMessageTime: getCurrentTimestamp,
                                  lastMessageSentBy: currentUserReference,
                                  image: false,
                                  chatKey:
                                      '${currentUserUid}_${widget.contractorRecord.uid}',
                                  userAName: valueOrDefault(
                                      currentUserDocument?.fullName, ''),
                                  userBName: widget.contractorRecord.fullName,
                                  userAPhoto: currentUserPhoto,
                                  userBPhoto: widget.contractorRecord.photoUrl,
                                ));
                                if (!context.mounted) {
                                  return;
                                }
                                _model.newchat =
                                    ChatsRecord.getDocumentFromData(
                                        createChatsRecordData(
                                          userA: currentUserReference,
                                          userB:
                                              widget.contractorRecord.reference,
                                          lastMessageTime: getCurrentTimestamp,
                                          lastMessageSentBy:
                                              currentUserReference,
                                          image: false,
                                          chatKey:
                                              '${currentUserUid}_${widget.contractorRecord.uid}',
                                          userAName: valueOrDefault(
                                              currentUserDocument?.fullName, ''),
                                          userBName:
                                              widget.contractorRecord.fullName,
                                          userAPhoto: currentUserPhoto,
                                          userBPhoto:
                                              widget.contractorRecord.photoUrl,
                                        ),
                                        chatsRecordReference);
                                Navigator.pop(context);
                                context.pushNamed(
                                  MessagePageWidget.routeName,
                                  queryParameters: {
                                    'chatRef': serializeParam(
                                      _model.newchat?.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                );
                              }

                              safeSetState(() {});
                            },
                            text: 'Yes, Start Chat',
                            options: FFButtonOptions(
                              height: 40.0,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  10.0, 0.0, 10.0, 0.0),
                              iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    font: GoogleFonts.ubuntu(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(8.0),
                              hoverColor:
                                  FlutterFlowTheme.of(context).secondary,
                              hoverElevation: 4.0,
                            ),
                          ),
                        ),
                        FFButtonWidget(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          text: 'Cancel',
                          options: FFButtonOptions(
                            height: 40.0,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10.0, 0.0, 10.0, 0.0),
                            iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  font: GoogleFonts.ubuntu(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                            elevation: 0.0,
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(8.0),
                            hoverColor:
                                FlutterFlowTheme.of(context).secondary,
                            hoverElevation: 4.0,
                          ),
                        ),
                      ].divide(const SizedBox(width: 10.0)),
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
