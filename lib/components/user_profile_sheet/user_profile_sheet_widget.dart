import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileSheetWidget extends StatelessWidget {
  const UserProfileSheetWidget._({
    required this.userRef,
    required this.userName,
    required this.userPhoto,
  });

  final DocumentReference userRef;
  final String userName;
  final String userPhoto;

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
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
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

  static const _categoryIcons = <String, IconData>{
    'Contractors & Handymen': Icons.handyman_rounded,
    'Plumbers': Icons.plumbing_rounded,
    'Electricians': Icons.electrical_services_rounded,
    'Heating': Icons.local_fire_department_rounded,
    'Air Conditioning': Icons.ac_unit_rounded,
    'Locksmiths': Icons.vpn_key_rounded,
    'Painters': Icons.format_paint_rounded,
    'Tree Services': Icons.park_rounded,
    'Movers': Icons.local_shipping_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: StreamBuilder<UsersRecord>(
              stream: UsersRecord.getDocument(userRef),
              builder: (context, snapshot) {
                final user = snapshot.data;

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height - 20,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.primary, theme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (user?.photoUrl ?? userPhoto).isNotEmpty
                                      ? Image.network(
                                          user?.photoUrl ?? userPhoto,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color:
                                              Colors.white.withValues(alpha: 0.2),
                                          child: const Icon(
                                              Icons.person_rounded,
                                              color: Colors.white,
                                              size: 50),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      user?.fullName ?? userName,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.ubuntu(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (user == null || user.role != 'admin') ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Clipboard.setData(ClipboardData(
                                          text: user?.fullName ?? userName)),
                                      child: const Icon(Icons.copy_rounded,
                                          color: Colors.white60, size: 16),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (user != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: Text(
                                    user.role == 'admin'
                                        ? 'Support'
                                        : user.role == 'service_provider'
                                            ? 'Service Provider'
                                            : 'Client',
                                    style: GoogleFonts.ubuntu(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              if (user != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.email_rounded,
                                        color: Colors.white60, size: 15),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        user.email,
                                        style: GoogleFonts.ubuntu(
                                            color: Colors.white70, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Clipboard.setData(
                                          ClipboardData(text: user.email)),
                                      child: const Icon(Icons.copy_rounded,
                                          color: Colors.white54, size: 15),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (user == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: theme.primary),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user.role == 'service_provider') ...[
                                  _infoRow(
                                    theme: theme,
                                    icon: Icons.title_rounded,
                                    label: 'Professional Title',
                                    value: user.title.isNotEmpty
                                        ? user.title
                                        : 'No title',
                                  ),
                                  _infoRow(
                                    theme: theme,
                                    icon: Icons.description_rounded,
                                    label: 'About',
                                    value: user.shortDescription.isNotEmpty
                                        ? user.shortDescription
                                        : 'Not provided',
                                  ),
                                  const SizedBox(height: 4),
                                  _categoriesBlock(
                                    theme: theme,
                                    categories: user.categories,
                                  ),
                                  const SizedBox(height: 12),
                                ] else
                                  _infoRow(
                                    theme: theme,
                                    icon: Icons.description_rounded,
                                    label: 'About',
                                    value: user.shortDescription.isNotEmpty
                                        ? user.shortDescription
                                        : 'Not provided',
                                  ),
                                if (user.phoneNumber.isNotEmpty &&
                                    user.phoneNumber != 'Not provided')
                                  _infoRowWithCopy(
                                    theme: theme,
                                    icon: Icons.phone_rounded,
                                    label: 'Phone Number',
                                    value: user.phoneNumber,
                                  )
                                else
                                  _infoRow(
                                    theme: theme,
                                    icon: Icons.phone_rounded,
                                    label: 'Phone Number',
                                    value: 'Not provided',
                                  ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.alternate),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                            icon: Icon(Icons.close_rounded,
                                color: theme.secondaryText, size: 18),
                            label: Text('Close',
                                style: GoogleFonts.ubuntu(
                                    color: theme.secondaryText,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.primary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: theme.primaryText,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithCopy({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.primary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: theme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: Icon(Icons.copy_rounded, color: theme.secondaryText, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(FlutterFlowTheme theme, String label) {
    return Text(
      label,
      style: GoogleFonts.ubuntu(
        fontSize: 11,
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _categoriesBlock({
    required FlutterFlowTheme theme,
    required List<String> categories,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.category_rounded, color: theme.primary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(theme, 'Categories'),
                const SizedBox(height: 6),
                if (categories.isEmpty)
                  Text(
                    'No categories',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: theme.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map((cat) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_categoryIcons.containsKey(cat)) ...[
                                    Icon(
                                      _categoryIcons[cat],
                                      size: 14,
                                      color: const Color(0xFFF4A026),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    cat,
                                    style: GoogleFonts.ubuntu(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
