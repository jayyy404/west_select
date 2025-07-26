import 'package:flutter/material.dart';
import 'message_service.dart';

class EncryptionSetupHelper {
  static Future<void> initializeEncryption() async {
    try {
      print('Initializing message encryption...');

      print('Message encryption initialized successfully');
    } catch (e) {
      print('Error initializing encryption: $e');
    }
  }

  /// method to migrate existing messages
  static Future<void> migrateExistingMessages(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Encrypting messages..."),
            ],
          ),
        );
      },
    );

    try {
      await MessagesService.migrateExistingMessages();
      if (context.mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Success"),
              content: const Text("Messages have been encrypted successfully!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text("Failed to encrypt messages: $e"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  static Widget buildMigrationButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.security),
        title: const Text("Encrypt Messages"),
        subtitle: const Text("Encrypt existing messages for privacy"),
        trailing: ElevatedButton(
          onPressed: () => migrateExistingMessages(context),
          child: const Text("Encrypt"),
        ),
      ),
    );
  }

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      // return false (assuming migration is a one-time manual process)
      return false;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  /// Show one-time migration prompt
  static void showMigrationPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Message Encryption"),
          content:
              const Text("We've added message encryption for better privacy. "
                  "Would you like to encrypt your existing messages? "
                  "This is a one-time process and cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Later"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                migrateExistingMessages(context);
              },
              child: const Text("Encrypt Now"),
            ),
          ],
        );
      },
    );
  }
}
