import 'package:flutter/material.dart';
import '../services/meals_service.dart';

/// Utility class for handling errors in the UI
class ErrorHandler {
  /// Show an error message as a SnackBar
  /// 
  /// Automatically detects MealsServiceException and shows user-friendly message
  static void showError(BuildContext context, dynamic error) {
    String errorMessage;
    
    if (error is MealsServiceException) {
      errorMessage = error.userFriendlyMessage;
    } else {
      errorMessage = error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(errorMessage),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show an error dialog with more details
  static void showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) {
    String errorMessage;
    
    if (error is MealsServiceException) {
      errorMessage = error.userFriendlyMessage;
    } else {
      errorMessage = error.toString();
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text(
                title ?? 'Error',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onRetry();
                },
                child: const Text('Retry'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B7A5A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Get user-friendly error message from any error
  static String getErrorMessage(dynamic error) {
    if (error is MealsServiceException) {
      return error.userFriendlyMessage;
    }
    return error.toString();
  }
}
