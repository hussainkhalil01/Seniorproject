import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/amanbuild/profile_pages/profile_section_card.dart';
import '/amanbuild/profile_pages/profile_field_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'edit_profile_page_model.dart';
export 'edit_profile_page_model.dart';

class EditProfilePageWidget extends StatefulWidget {
  const EditProfilePageWidget({super.key});

  static String routeName = 'editProfilePage';
  static String routePath = '/editProfilePage';

  @override
  State<EditProfilePageWidget> createState() => _EditProfilePageWidgetState();
}

class _EditProfilePageWidgetState extends State<EditProfilePageWidget> {
  late EditProfilePageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _phoneMask = MaskTextInputFormatter(mask: '#### ####');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditProfilePageModel());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Init controllers with current values once auth data is available
    _model.nameController ??= TextEditingController(
        text: valueOrDefault(currentUserDocument?.fullName, ''));
    _model.nameFocusNode ??= FocusNode();

    final storedDesc =
        valueOrDefault(currentUserDocument?.shortDescription, '');
    _model.aboutController ??= TextEditingController(
        text: storedDesc == 'No description yet' ? '' : storedDesc);
    _model.aboutFocusNode ??= FocusNode();

    final storedPhone = currentPhoneNumber;
    String phoneInit = '';
    if (storedPhone != 'Not provided' && storedPhone.isNotEmpty) {
      final digits = storedPhone.replaceAll(RegExp(r'\D'), '');
      final userDigits = (digits.startsWith('973') && digits.length == 11)
          ? digits.substring(3)
          : digits;
      if (userDigits.length == 8) {
        phoneInit = '${userDigits.substring(0, 4)} ${userDigits.substring(4)}';
      }
    }
    _model.phoneController ??= TextEditingController(text: phoneInit);
    _model.phoneFocusNode ??= FocusNode();

    final storedTitle = valueOrDefault(currentUserDocument?.title, '');
    _model.titleController ??= TextEditingController(
        text: storedTitle == 'No title' ? '' : storedTitle);
    _model.titleFocusNode ??= FocusNode();

    // Capture initial snapshots and attach change listeners (once only)
    if (_model.initialName == null) {
      _model.initialName = _model.nameController!.text;
      _model.initialAbout = _model.aboutController!.text;
      _model.initialPhone = _model.phoneController!.text;
      _model.initialTitle = _model.titleController!.text;
      _model.initialCategories =
          currentUserDocument?.categories.toList() ?? [];
      _model.nameController!.addListener(_onChanged);
      _model.aboutController!.addListener(_onChanged);
      _model.phoneController!.addListener(_onChanged);
      _model.titleController!.addListener(_onChanged);
    }
  }

  void _onChanged() {
    if (mounted) safeSetState(() {});
  }

  @override
  void dispose() {
    _model.nameController?.removeListener(_onChanged);
    _model.aboutController?.removeListener(_onChanged);
    _model.phoneController?.removeListener(_onChanged);
    _model.titleController?.removeListener(_onChanged);
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    // Normalize full name: collapse spaces + title-case each word
    final rawName = _model.nameController!.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    _model.nameController!.text = rawName.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');

    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      safeSetState(() {});
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final theme = FlutterFlowTheme.of(context);
    safeSetState(() => _model.isSaving = true);
    try {
      final isProvider =
          valueOrDefault(currentUserDocument?.role, '') == 'service_provider';

      // Determine phone value: empty field → "Not provided"
      final userDigits = _model.phoneController!.text
          .replaceAll(RegExp(r'\D'), '');
      final phoneValue = userDigits.isEmpty
          ? 'Not provided'
          : '+973 ${userDigits.substring(0, 4)} ${userDigits.substring(4)}';

      final Map<String, dynamic> data = {
        'full_name': _model.nameController!.text.trim(),
        'display_name': _model.nameController!.text.trim(),
        'short_description': _model.aboutController!.text.trim().isEmpty
            ? 'No description yet'
            : _model.aboutController!.text.trim(),
        'phone_number': phoneValue,
        if (isProvider)
          'title': _model.titleController!.text.trim().isEmpty
              ? 'No title'
              : _model.titleController!.text.trim(),
        if (isProvider && _model.categoriesValues != null)
          ...mapToFirestore({'categories': _model.categoriesValues}),
      };

      await currentUserReference!.update(data);
      await authManager.refreshUser();

      // Reset snapshots so the save button becomes disabled again
      _model.initialName = _model.nameController!.text;
      _model.initialAbout = _model.aboutController!.text;
      _model.initialPhone = _model.phoneController!.text;
      _model.initialTitle = _model.titleController!.text;
      final savedCategories =
          _model.categoriesValues?.toList() ?? _model.initialCategories ?? [];
      _model.initialCategories = savedCategories;
      _model.categoriesController?.value = savedCategories;
      _model.categoriesValues = null;

      if (mounted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(
              'Profile updated successfully',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: theme.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        context.pop();
      }
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (mounted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(
              'Something went wrong. Please try again',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: theme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
      }
    } finally {
      safeSetState(() => _model.isSaving = false);
    }
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    Widget? prefixWidget,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      enabled: !_model.isSaving,
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: maxLength != null
          ? MaxLengthEnforcement.enforced
          : MaxLengthEnforcement.none,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: formatters,
      validator: validator,
      style: GoogleFonts.ubuntu(
          fontSize: 15,
          color: FlutterFlowTheme.of(context).primaryText),
      decoration: profileFieldDecoration(
        context: context,
        label: label,
        icon: icon,
        prefixWidget: prefixWidget,
      ),
      cursorColor: FlutterFlowTheme.of(context).primary,
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
        canPop: !_model.isSaving,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: AuthUserStreamWidget(
          builder: (context) => Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              children: [
                // ── GRADIENT HEADER ───────────────────────────
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
                          // Back button
                          Opacity(
                            opacity: _model.isSaving ? 0.4 : 1.0,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _model.isSaving ? null : () => context.pop(),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.arrow_back_rounded,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                          ),
                          // Title
                          Expanded(
                            child: Text(
                              'Edit Profile',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.ubuntu(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                          // Save button / spinner
                          _model.isSaving
                              ? const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    ),
                                  ),
                                )
                              : Opacity(
                                  opacity: _model.hasChanges ? 1.0 : 0.4,
                                  child: Material(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap:
                                          _model.hasChanges ? _save : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Text('Save',
                                            style: GoogleFonts.ubuntu(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  ),
                // ── SCROLLABLE FIELDS ─────────────────────────
                Expanded(
                  child: AbsorbPointer(
                  absorbing: _model.isSaving,
                  child: Opacity(
                  opacity: _model.isSaving ? 0.5 : 1.0,
                  child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // ── PERSONAL INFORMATION CARD ──────────────────
                ProfileSectionCard(
                  title: 'Profile Information',
                  icon: Icons.person_rounded,
                  children: [
                    _buildField(
                      context: context,
                      controller: _model.nameController!,
                      focusNode: _model.nameFocusNode!,
                      label: 'Full Name',
                      icon: Icons.badge_rounded,
                      maxLength: 30,
                      textCapitalization: TextCapitalization.words,
                      formatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z ]')),
                      ],
                      validator: (_) {
                        final val = _model.nameController!.text.trim();
                        if (val.isEmpty) return 'Please enter your full name';
                        if (val.length < 3) return 'Full name is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      context: context,
                      controller: _model.aboutController!,
                      focusNode: _model.aboutFocusNode!,
                      label: 'About',
                      icon: Icons.description_rounded,
                      maxLines: 4,
                      maxLength: 120,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      context: context,
                      controller: _model.phoneController!,
                      focusNode: _model.phoneFocusNode!,
                      label: 'Phone Number',
                      icon: Icons.phone_rounded,
                      prefixWidget: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_rounded,
                                color:
                                    FlutterFlowTheme.of(context).secondary,
                                size: 22),
                            const SizedBox(width: 6),
                            const Text('🇧🇭',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text('+973',
                                style: GoogleFonts.ubuntu(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: FlutterFlowTheme.of(context)
                                        .secondary)),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      formatters: [_phoneMask],
                      validator: (_) {
                        final digits = _model.phoneController!.text
                            .replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) return null;
                        if (digits.length < 8) {
                          return 'Phone number must be exactly 8 digits';
                        }
                        if (!['1', '3', '6'].contains(digits[0])) {
                          return 'Phone number must start with 3, 6 or 1 only';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                // ── PROFESSIONAL INFORMATION CARD (providers) ──
                if (valueOrDefault(currentUserDocument?.role, '') ==
                    'service_provider') ...[
                  const SizedBox(height: 24),
                  ProfileSectionCard(
                    title: 'Professional Information',
                    icon: Icons.work_rounded,
                    children: [
                    _buildField(
                      context: context,
                      controller: _model.titleController!,
                      focusNode: _model.titleFocusNode!,
                      label: 'Professional Title',
                      icon: Icons.title_rounded,
                      maxLength: 40,
                    ),
                    const SizedBox(height: 12),
                    Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      border: Border.all(
                          color: FlutterFlowTheme.of(context).accent4,
                          width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category_rounded,
                                color: FlutterFlowTheme.of(context).secondary,
                                size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Categories',
                              style: GoogleFonts.ubuntu(
                                fontSize: 14,
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FlutterFlowChoiceChips(
                          options: const [
                            ChipData('Contractors & Handymen',
                                Icons.handyman_rounded),
                            ChipData('Plumbers', Icons.plumbing_rounded),
                            ChipData('Electricians',
                                Icons.electrical_services_rounded),
                            ChipData('Heating',
                                Icons.local_fire_department_rounded),
                            ChipData(
                                'Air Conditioning', Icons.ac_unit_rounded),
                            ChipData('Locksmiths', Icons.vpn_key_rounded),
                            ChipData(
                                'Painters', Icons.format_paint_rounded),
                            ChipData('Tree Services', Icons.park_rounded),
                            ChipData(
                                'Movers', Icons.local_shipping_rounded),
                          ],
                          onChanged: _model.isSaving
                              ? null
                              : (val) => safeSetState(
                                  () => _model.categoriesValues = val),
                          selectedChipStyle: ChipStyle(
                            backgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            textStyle: GoogleFonts.ubuntu(
                                color: Colors.white, fontSize: 13),
                            iconColor: const Color(0xFFF4A026),
                            iconSize: 18,
                            elevation: 2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          unselectedChipStyle: ChipStyle(
                            backgroundColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            textStyle: GoogleFonts.ubuntu(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                                fontSize: 13),
                            iconColor: const Color(0xFFF4A026),
                            iconSize: 18,
                            elevation: 0,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          chipSpacing: 8,
                          rowSpacing: 8,
                          multiselect: true,
                          initialized: _model.categoriesController != null,
                          alignment: WrapAlignment.start,
                          controller: _model.categoriesController ??=
                              FormFieldController<List<String>>(
                            currentUserDocument?.categories.toList() ?? [],
                          ),
                          wrapped: true,
                          disabledColor:
                              FlutterFlowTheme.of(context).accent4,
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ),
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

