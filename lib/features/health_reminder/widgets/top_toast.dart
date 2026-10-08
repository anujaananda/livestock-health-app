import 'package:flutter/material.dart';

class TopToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _TopToastWidget(message: message, isError: isError),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _TopToastWidget extends StatelessWidget {
  final String message;
  final bool isError;

  const _TopToastWidget({Key? key, required this.message, this.isError = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFDECEC) : const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError
                  ? const Color(0xFFF5B7B1)
                  : const Color(0xFFB7DDBF),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF1E7D42),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF1E5936),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
