import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'dart:ui';
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x66000000),
      ),
      alignment: const AlignmentDirectional(0.0, 0.0),
      child: Container(
        width: 360.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).accent1,
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 28.0,
                    ),
                  ),
                  Text(
                    'Start Chat',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          font: GoogleFonts.ubuntu(
                            fontWeight: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                  ),
                  Text(
                    'Do you want to start chatting with this contractor?',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.ubuntu(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ].divide(const SizedBox(height: 8.0)),
              ),
              Container(
                width: double.infinity,
                height: 1.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FFButtonWidget(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    text: 'Cancel',
                    options: FFButtonOptions(
                      width: 140.0,
                      height: 48.0,
                      padding: const EdgeInsets.all(8.0),
                      iconPadding:
                          const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primaryBackground,
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
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .titleSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .fontStyle,
                          ),
                      elevation: 0.0,
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  Container(
                    width: 151.0,
                    height: 45.81,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
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
                        if (_model.existingChats != null &&
                            (_model.existingChats)!.isNotEmpty) {
                          Navigator.pop(context);
                          context.pushNamed(
                            MessageWidget.routeName,
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
                            MessageWidget.routeName,
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
                      text: 'Start Chat',
                      options: FFButtonOptions(
                        width: 140.0,
                        height: 14.99,
                        padding: const EdgeInsets.all(8.0),
                        iconPadding:
                            const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.ubuntu(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).info,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ].divide(const SizedBox(width: 12.0)),
              ),
            ].divide(const SizedBox(height: 20.0)),
          ),
        ),
      ),
    );
  }
}
