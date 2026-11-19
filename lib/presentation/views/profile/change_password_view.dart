import 'package:flutter/material.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';

/// Changement de mot de passe (API : changePassword)
class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final res = await FindsApiClient.mutate(
      GraphQLQueries.changePasswordMutation,
      variables: {
        'input': {
          'currentPassword': _currentController.text,
          'newPassword': _newController.text,
        },
      },
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final data = res.data?['changePassword'];
    final ok = data?['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.primary : AppColors.error,
        content: Text(
          ok
              ? (data?['message'] as String? ?? 'Mot de passe modifié.')
              : FindsApiClient.errorMessage(
                  res.exception,
                  fallback:
                      data?['message'] as String? ??
                      'Impossible de modifier le mot de passe.',
                ),
        ),
      ),
    );
    if (ok) Navigator.of(context).pop();
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        TextFormField(
          controller: controller,
          obscureText: _obscure,
          validator: validator,
          style: const TextStyle(fontSize: AppSizes.fontMd),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Icons.lock_rounded,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textSubtle,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.chipBadge),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.chipBadge),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceMd),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceSm - 2,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: const Row(
                children: [
                  AppBackButton(),
                  SizedBox(width: AppSizes.spaceSm - 2),
                  Text(
                    'Changer le mot de passe',
                    style: TextStyle(
                      fontSize: AppSizes.fontL,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceL,
                  vertical: AppSizes.spaceMd,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field(
                        label: 'Mot de passe actuel',
                        controller: _currentController,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Champ requis' : null,
                      ),
                      _field(
                        label: 'Nouveau mot de passe',
                        controller: _newController,
                        validator: (v) => (v == null || v.length < 8)
                            ? '8 caractères minimum'
                            : null,
                      ),
                      _field(
                        label: 'Confirmer le nouveau mot de passe',
                        controller: _confirmController,
                        validator: (v) => v != _newController.text
                            ? 'Les mots de passe ne correspondent pas'
                            : null,
                      ),
                      const SizedBox(height: AppSizes.spaceSm),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
