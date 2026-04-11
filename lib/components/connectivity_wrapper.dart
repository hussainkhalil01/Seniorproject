import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Wraps [child] and replaces it entirely with a "no connection" screen
/// whenever the device loses internet connectivity.  Automatically restores
/// [child] as soon as connectivity returns — no manual refresh needed.
class ConnectivityWrapper extends StatefulWidget {
  const ConnectivityWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isConnected = true;
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _sub = Connectivity().onConnectivityChanged.listen(_onChanged);
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    _onChanged(results);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final connected =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
    if (mounted && connected != _isConnected) {
      setState(() => _isConnected = connected);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _isConnected ? widget.child : const _NoConnectionScreen();
}

class _NoConnectionScreen extends StatelessWidget {
  const _NoConnectionScreen();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      color: theme.primaryBackground,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 90,
                color: theme.secondaryText,
              ),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection\nand try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
