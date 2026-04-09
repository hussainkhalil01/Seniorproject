import 'package:flutter/material.dart';
import '/custom_code/actions/index.dart' as actions;

class SeedContractorsPage extends StatefulWidget {
  const SeedContractorsPage({super.key});

  static String routeName = 'SeedContractors';
  static String routePath = '/seedContractors';

  @override
  State<SeedContractorsPage> createState() => _SeedContractorsPageState();
}

class _SeedContractorsPageState extends State<SeedContractorsPage> {
  bool _running = false;
  String _result = '';

  Future<void> _run() async {
    setState(() {
      _running = true;
      _result = 'Creating accounts... this takes a minute.';
    });

    final result = await actions.seedContractors();

    setState(() {
      _running = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Contractors')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will create 20 sample contractor accounts.\n'
              'Password for all: Testtest1@\n'
              'They will appear on the home page.\n\n'
              'WARNING: You will be signed out after running this.\n'
              'Sign back in with your own account when done.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _running ? null : _run,
              child: _running
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create 20 Contractor Accounts'),
            ),
            const SizedBox(height: 24),
            if (_result.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _result,
                    style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
