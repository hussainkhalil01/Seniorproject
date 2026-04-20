import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/amanbuild/profile_pages/profile_page/profile_page_widget.dart'
    show ProfilePageWidget;
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ProfilePageModel extends FlutterFlowModel<ProfilePageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Column widget.
  ScrollController? columnController;
  bool isDataUploading_profileImage = false;

  // State field(s) for ProfileTitleField widget.
  FocusNode? profileTitleFieldFocusNode;
  TextEditingController? profileTitleFieldTextController;
  String? Function(BuildContext, String?)?
      profileTitleFieldTextControllerValidator;
  // State field(s) for ProfileShortDescriptionField widget.
  FocusNode? profileShortDescriptionFieldFocusNode;
  TextEditingController? profileShortDescriptionFieldTextController;
  String? Function(BuildContext, String?)?
      profileShortDescriptionFieldTextControllerValidator;
  // State field(s) for ProfileCategories widget.
  FormFieldController<List<String>>? profileCategoriesValueController;
  List<String>? get profileCategoriesValues =>
      profileCategoriesValueController?.value;
  set profileCategoriesValues(List<String>? val) =>
      profileCategoriesValueController?.value = val;
  // State field(s) for ProfilePhoneNumberField widget.
  FocusNode? profilePhoneNumberFieldFocusNode;
  TextEditingController? profilePhoneNumberFieldTextController;
  late MaskTextInputFormatter profilePhoneNumberFieldMask;
  String? Function(BuildContext, String?)?
      profilePhoneNumberFieldTextControllerValidator;

  @override
  void initState(BuildContext context) {
    columnController = ScrollController();
  }

  @override
  void dispose() {
    columnController?.dispose();
    profileTitleFieldFocusNode?.dispose();
    profileTitleFieldTextController?.dispose();

    profileShortDescriptionFieldFocusNode?.dispose();
    profileShortDescriptionFieldTextController?.dispose();

    profileCategoriesValueController?.dispose();

    profilePhoneNumberFieldFocusNode?.dispose();
    profilePhoneNumberFieldTextController?.dispose();
  }
}
