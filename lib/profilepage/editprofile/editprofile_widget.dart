import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'editprofile_model.dart';
export 'editprofile_model.dart';

class EditprofileWidget extends StatefulWidget {
  const EditprofileWidget({super.key});

  static String routeName = 'editprofile';
  static String routePath = '/editprofile';

  @override
  State<EditprofileWidget> createState() => _EditprofileWidgetState();
}

class _EditprofileWidgetState extends State<EditprofileWidget> {
  late EditprofileModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _phoneMask = MaskTextInputFormatter(mask: '+973 #### ####');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditprofileModel());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Init controllers with current values once auth data is available
    _model.nameController ??= TextEditingController(
        text: valueOrDefault(currentUserDocument?.fullName, ''));
    _model.nameFocusNode ??= FocusNode();

    _model.aboutController ??= TextEditingController(
        text: valueOrDefault(currentUserDocument?.shortDescription, ''));
    _model.aboutFocusNode ??= FocusNode();

    _model.phoneController ??=
        TextEditingController(text: currentPhoneNumber);
    _model.phoneFocusNode ??= FocusNode();

    _model.titleController ??= TextEditingController(
        text: valueOrDefault(currentUserDocument?.title, ''));
    _model.titleFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    safeSetState(() => _model.isSaving = true);
    try {
      final isProvider =
          valueOrDefault(currentUserDocument?.role, '') == 'service_provider';

      final Map<String, dynamic> data = {
        'display_name': _model.nameController!.text.trim(),
        'short_description': _model.aboutController!.text.trim(),
        'phone_number': _model.phoneController!.text.trim(),
        if (isProvider) 'title': _model.titleController!.text.trim(),
        if (isProvider && _model.categoriesValues != null)
          ...mapToFirestore({'categories': _model.categoriesValues}),
      };

      await currentUserReference!.update(data);
      await authManager.refreshUser();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content:
                Text('Profile updated!', style: GoogleFonts.ubuntu()),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ));
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Error: $e',
                style: GoogleFonts.ubuntu(
                    color: FlutterFlowTheme.of(context).error)),
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
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: maxLength != null
          ? MaxLengthEnforcement.enforced
          : MaxLengthEnforcement.none,
      buildCounter: maxLength != null
          ? (context,
                  {required currentLength,
                  required isFocused,
                  maxLength}) =>
              Align(
                alignment: Alignment.centerRight,
                child: Text('$currentLength / $maxLength',
                    style: GoogleFonts.ubuntu(
                        fontSize: 11,
                        color:
                            FlutterFlowTheme.of(context).secondaryText)),
              )
          : null,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: GoogleFonts.ubuntu(
          fontSize: 15,
          color: FlutterFlowTheme.of(context).primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.ubuntu(
            color: FlutterFlowTheme.of(context).secondaryText,
            fontSize: 14),
        prefixIcon:
            Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 20),
        filled: true,
        fillColor: FlutterFlowTheme.of(context).primaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).accent4, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
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
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: FlutterFlowTheme.of(context).primaryText),
            onPressed: () => context.pop(),
          ),
          title: Text('Edit Profile',
              style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FlutterFlowTheme.of(context).primaryText)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _model.isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : TextButton(
                      onPressed: _save,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            FlutterFlowTheme.of(context).primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Save',
                          style: GoogleFonts.ubuntu(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                height: 1,
                color: FlutterFlowTheme.of(context).accent4),
          ),
        ),
        body: AuthUserStreamWidget(
          builder: (context) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ PERSONAL INFO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _section(context, 'Personal Info', Icons.person_rounded),
                const SizedBox(height: 12),
                _buildField(
                  context: context,
                  controller: _model.nameController!,
                  focusNode: _model.nameFocusNode!,
                  label: 'Full Name',
                  icon: Icons.badge_rounded,
                  maxLength: 50,
                ),
                const SizedBox(height: 12),
                _buildField(
                  context: context,
                  controller: _model.aboutController!,
                  focusNode: _model.aboutFocusNode!,
                  label: 'About You',
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
                  keyboardType: TextInputType.phone,
                  formatters: [_phoneMask],
                ),
                // â”€â”€ SERVICE PROVIDER EXTRAS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (valueOrDefault(currentUserDocument?.role, '') ==
                    'service_provider') ...[
                  const SizedBox(height: 28),
                  _section(
                      context, 'Professional Info', Icons.work_rounded),
                  const SizedBox(height: 12),
                  _buildField(
                    context: context,
                    controller: _model.titleController!,
                    focusNode: _model.titleFocusNode!,
                    label: 'Professional Title',
                    icon: Icons.title_rounded,
                    maxLength: 40,
                  ),
                  const SizedBox(height: 16),
                  Text('Service Categories',
                      style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FlutterFlowTheme.of(context).secondaryText)),
                  const SizedBox(height: 10),
                  FlutterFlowChoiceChips(
                    options: const [
                      ChipData('Contractor And Handymen',
                          Icons.handyman_rounded),
                      ChipData('Plumber', Icons.plumbing_rounded),
                      ChipData('Electrician',
                          Icons.electrical_services_rounded),
                      ChipData(
                          'Heating', Icons.local_fire_department_rounded),
                      ChipData('Air Conditioning', Icons.ac_unit_rounded),
                      ChipData('Locksmith', Icons.vpn_key_rounded),
                      ChipData('Painter', Icons.format_paint_rounded),
                      ChipData('Tree Services', Icons.park_rounded),
                      ChipData('Mover', Icons.local_shipping_rounded),
                    ],
                    onChanged: (val) =>
                        safeSetState(() => _model.categoriesValues = val),
                    selectedChipStyle: ChipStyle(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      textStyle: GoogleFonts.ubuntu(
                          color: Colors.white, fontSize: 13),
                      iconColor: Colors.white,
                      iconSize: 18,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    unselectedChipStyle: ChipStyle(
                      backgroundColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      textStyle: GoogleFonts.ubuntu(
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 13),
                      iconColor: FlutterFlowTheme.of(context).accent3,
                      iconSize: 18,
                      elevation: 0,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    chipSpacing: 8,
                    rowSpacing: 8,
                    multiselect: true,
                    initialized: _model.categoriesValues != null,
                    alignment: WrapAlignment.start,
                    controller: _model.categoriesController ??=
                        FormFieldController<List<String>>(
                      currentUserDocument?.categories.toList() ?? [],
                    ),
                    wrapped: true,
                  ),
                ],
                const SizedBox(height: 28),
                // â”€â”€ ACCOUNT ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _section(
                    context, 'Account', Icons.manage_accounts_rounded),
                const SizedBox(height: 12),
                _actionTile(
                  context: context,
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () => context.pushNamed(EditpasswordWidget.routeName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FlutterFlowTheme.of(context).primaryText)),
      const SizedBox(width: 8),
      Expanded(
        child: Divider(
            color: FlutterFlowTheme.of(context).accent4, thickness: 1),
      ),
    ]);
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: FlutterFlowTheme.of(context).accent4, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: FlutterFlowTheme.of(context).primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.ubuntu(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: FlutterFlowTheme.of(context).primaryText)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: FlutterFlowTheme.of(context).secondaryText, size: 20),
          ],
        ),
      ),
    );
  }
}
