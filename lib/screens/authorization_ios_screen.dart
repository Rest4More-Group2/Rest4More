import 'package:flutter/material.dart';

class AuthorizationIosScreen extends StatelessWidget {
  const AuthorizationIosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Time Authorization')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'iOS app blocking setup is not implemented yet.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}