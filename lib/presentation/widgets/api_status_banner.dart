import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Bandeau d'état réseau : erreur (avec « Réessayer ») ou données hors-ligne.
class ApiStatusBanner extends StatelessWidget {
  final String? error;
  final bool offline;
  final VoidCallback onRetry;

  const ApiStatusBanner({
    super.key,
    required this.error,
    required this.offline,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null && !offline) return const SizedBox.shrink();
    final isError = error != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorSoft : AppColors.infoSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            size: 18,
            color: isError ? AppColors.errorDark : AppColors.infoDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isError
                  ? error!
                  : 'Données hors-ligne : dernière version enregistrée.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isError ? AppColors.errorDark : AppColors.infoDark,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
