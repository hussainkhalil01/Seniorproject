import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_in_page_widget.dart' show SignInPageWidget;
import 'package:flutter/material.dart';

class SignInPageModel extends FlutterFlowModel<SignInPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Column widget.
  ScrollController? columnController;
  // State field(s) for SignInEmailField widget.
  FocusNode? signInEmailFieldFocusNode;
  TextEditingController? signInEmailFieldTextController;
  String? Function(BuildContext, String?)?
      signInEmailFieldTextControllerValidator;
  String? _signInEmailFieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter your email address';
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(val)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // State field(s) for SignInPasswordField widget.
  FocusNode? signInPasswordFieldFocusNode;
  TextEditingController? signInPasswordFieldTextController;
  late bool signInPasswordFieldVisibility;
  String? Function(BuildContext, String?)?
      signInPasswordFieldTextControllerValidator;
  String? _signInPasswordFieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter your password';
    }

    return null;
  }

  // Stores action output result for [Custom Action - signInWithCustomError] action in SignInButton widget.
  String? signInResult;

  // Whether sign-in is in progress.
  bool isLoading = false;

  // ── Lockout state (static so it survives navigation) ──────
  static const int _maxAttempts = 3;
  static const Duration _lockoutDuration = Duration(minutes: 2);

  static int _failedAttempts = 0;
  static DateTime? _lockedUntil;

  int get failedAttempts => _failedAttempts;
  bool get isLockedOut =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  Duration get lockoutRemaining {
    if (_lockedUntil == null) return Duration.zero;
    final remaining = _lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get lockoutCountdown {
    final r = lockoutRemaining;
    final m = r.inMinutes.toString().padLeft(2, '0');
    final s = (r.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= _maxAttempts) {
      _lockedUntil = DateTime.now().add(_lockoutDuration);
      _failedAttempts = 0;
    }
  }

  void resetAttempts() {
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  @override
  void initState(BuildContext context) {
    columnController = ScrollController();
    signInEmailFieldTextControllerValidator =
        _signInEmailFieldTextControllerValidator;
    signInPasswordFieldVisibility = false;
    signInPasswordFieldTextControllerValidator =
        _signInPasswordFieldTextControllerValidator;
  }

  @override
  void dispose() {
    columnController?.dispose();
    signInEmailFieldFocusNode?.dispose();
    signInEmailFieldTextController?.dispose();

    signInPasswordFieldFocusNode?.dispose();
    signInPasswordFieldTextController?.dispose();
  }
}
