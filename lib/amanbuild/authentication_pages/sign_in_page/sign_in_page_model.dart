import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'sign_in_page_widget.dart' show SignInPageWidget;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    if (!functions.emailRegex.hasMatch(val)) {
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
  static const _kLockedUntil = 'sign_in_locked_until';
  static const _kFailedAttempts = 'sign_in_failed_attempts';

  static int _failedAttempts = 0;
  static DateTime? _lockedUntil;

  static String get lockoutDurationText {
    final m = _lockoutDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_lockoutDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_kLockedUntil, _lockedUntil!.millisecondsSinceEpoch);
        prefs.remove(_kFailedAttempts);
      });
    } else {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_kFailedAttempts, _failedAttempts);
      });
    }
  }

  void resetAttempts() {
    _failedAttempts = 0;
    _lockedUntil = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_kLockedUntil);
      prefs.remove(_kFailedAttempts);
    });
  }

  // Called once on cold start to restore lockout state from persistent storage.
  static Future<void> loadLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLockedUntil);
    if (ms != null) {
      final saved = DateTime.fromMillisecondsSinceEpoch(ms);
      if (DateTime.now().isBefore(saved)) {
        _lockedUntil = saved;
      } else {
        _lockedUntil = null;
        prefs.remove(_kLockedUntil);
        prefs.remove(_kFailedAttempts);
      }
    }
    final attempts = prefs.getInt(_kFailedAttempts);
    if (attempts != null) _failedAttempts = attempts;
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
