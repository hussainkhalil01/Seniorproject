import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileSheetWidget extends StatelessWidget {
  const UserProfileSheetWidget._({
    super.key,
    required this.userRef,
    required this.userName,
    required this.userPhoto,
  });

  final DocumentReference userRef;
  final String userName;
  final String userPhoto;

  /// Slides a profile card down from the top of the screen.
  static Future<void> show(
    BuildContext context, {
    required DocumentReference userRef,
    required String userName,
    required String userPhoto,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => UserProfileSheetWidget._(
        userRef: userRef,
        userName: userName,
        userPhoto: userPhoto,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            color: Colors.transparent,
            child: StreamBuilder<UsersRecord>(
              stream: UsersRecord.getDocument(userRef),
              builder: (context, snapshot) {
                final user = snapshot.data;

                return Container(
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: theme.alternate,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: theme.primary, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: userPhoto.isNotEmpty
                              ? Image.network(userPhoto,
                                  width: 90, height: 90, fit: BoxFit.cover)
                              : Container(
                                  color: theme.accent1,
                                  child: Icon(Icons.person_rounded,
                                      color: theme.primary, size: 44),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // name
                      Text(
                        userName,
                        style: theme.headlineSmall.override(
                          font:
                              GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                        ),
                      ),

                      if (user != null) ...[
                        // title
                        if (user.title.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.title,
                            style: theme.bodyMedium.override(
                              font: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.w500),
                              color: theme.primary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],

                        // role badge
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role == 'service_provider'
                                ? 'Service Provider'
                                : 'Client',
                            style: theme.bodySmall.override(
                              font: GoogleFonts.ubuntu(
                                  fontWeight: FontWeight.w600),
                              color: theme.primary,
                              letterSpacing: 0,
                            ),
                          ),
                        ),

                        // bio
                        if (user.shortDescription.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            user.shortDescription,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.override(
                              font: GoogleFonts.ubuntu(),
                              color: theme.secondaryText,
                              letterSpacing: 0,
                              lineHeight: 1.5,
                            ),
                          ),
                        ],
                      ] else ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: theme.primary),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // close button
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.alternate),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(Icons.close_rounded,
                                color: theme.secondaryText, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
