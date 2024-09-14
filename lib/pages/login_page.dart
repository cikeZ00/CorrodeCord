import 'dart:async';

import 'package:flutter/material.dart';
import '../app.dart';
import '../utils/rust_service.dart';
import 'events_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  StreamSubscription<Map<String, String>>? _eventSubscription;
  StreamSubscription<Object>? _errorSubscription;

  void _login() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid token')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    rustService.start(token);

    _eventSubscription?.cancel();
    _eventSubscription = rustService.events.listen((event) {
      if (event['type'] == 'AUTH_FAIL') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication Failed')),
        );
        setState(() {
          _isLoading = false;
        });
        rustService.stop();
      } else if (event['type'] == 'READY') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EventsPage(readyEvent: event['data']!),
          ),
        );
      }
    });

    _errorSubscription?.cancel();
    _errorSubscription = rustService.errors.listen((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _errorSubscription?.cancel();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discord')),
      drawer: const AppDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Enter your token',
                ),
              ),
              const SizedBox(height: 16.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}