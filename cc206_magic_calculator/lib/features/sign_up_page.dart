import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/image.png'),
            const Text('Sign Up'),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
