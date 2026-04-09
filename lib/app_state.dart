import 'package:flutter/material.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  bool _confirmEmail = false;
  bool get confirmEmail => _confirmEmail;
  set confirmEmail(bool value) {
    _confirmEmail = value;
  }

  bool _emailVerifyCooldownActive = true;
  bool get emailVerifyCooldownActive => _emailVerifyCooldownActive;
  set emailVerifyCooldownActive(bool value) {
    _emailVerifyCooldownActive = value;
  }

  int _emailVerifyCooldownSeconds = 60;
  int get emailVerifyCooldownSeconds => _emailVerifyCooldownSeconds;
  set emailVerifyCooldownSeconds(int value) {
    _emailVerifyCooldownSeconds = value;
  }

  bool _forgotPasswordCooldownActive = false;
  bool get forgotPasswordCooldownActive => _forgotPasswordCooldownActive;
  set forgotPasswordCooldownActive(bool value) {
    _forgotPasswordCooldownActive = value;
  }

  int _forgotPasswordCooldownSeconds = 60;
  int get forgotPasswordCooldownSeconds => _forgotPasswordCooldownSeconds;
  set forgotPasswordCooldownSeconds(int value) {
    _forgotPasswordCooldownSeconds = value;
  }

  bool _forgotPasswordSent = false;
  bool get forgotPasswordSent => _forgotPasswordSent;
  set forgotPasswordSent(bool value) {
    _forgotPasswordSent = value;
  }

  String _selectedCategory = '';
  String get selectedCategory => _selectedCategory;
  set selectedCategory(String value) {
    _selectedCategory = value;
  }

  String _roleContractor = 'Contractor';
  String get roleContractor => _roleContractor;
  set roleContractor(String value) {
    _roleContractor = value;
  }

  bool _messageReaction = false;
  bool get messageReaction => _messageReaction;
  set messageReaction(bool value) {
    _messageReaction = value;
  }

  String _messageFocusText = '';
  String get messageFocusText => _messageFocusText;
  set messageFocusText(String value) {
    _messageFocusText = value;
  }

  bool _messageFocusColor = false;
  bool get messageFocusColor => _messageFocusColor;
  set messageFocusColor(bool value) {
    _messageFocusColor = value;
  }
}
