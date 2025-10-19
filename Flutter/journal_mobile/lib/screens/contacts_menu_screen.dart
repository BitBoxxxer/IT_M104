import 'package:flutter/material.dart';
import '../screens/contact/FAQ.dart';

class ContactMenuScreen extends StatefulWidget {
  const ContactMenuScreen({super.key});

  @override
  State<ContactMenuScreen> createState() => _ContactMenuScreenState();
}

class _ContactMenuScreenState extends State<ContactMenuScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Меню контактов')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                icon: Icon(Icons.help_outline),
                label: Text('FAQ'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FAQ(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            
          ],
        ),
      ),
    );
  }

}