import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/custom_text_field.dart';
import 'reset_password_view.dart';

/// Page 4 & 5 : Mot de passe oublié & Confirmation d'envoi
class ForgotPasswordView extends StatefulWidget {
  final VoidCallback? onBackToLogin;

  const ForgotPasswordView({super.key, this.onBackToLogin});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendLink() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulation de l'envoi de l'e-mail de réinitialisation
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isEmailSent = true;
    });
  }

  void _showAssistanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'Assistance citoyenne',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notre équipe est disponible 24/7 pour vous aider à récupérer l\'accès à votre compte Finds.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.phone_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  '+228 92 88 30 56 / 79 64 36 36',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _isEmailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  // --- Écran 1 : Formulaire de demande d'e-mail (Page 4) ---
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Header : Flèche retour + Titre
          Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 14),
              const Text(
                'Mot de passe oublié',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 2. Illustration centrale avec cadenas de réinitialisation
          Stack(
            alignment: Alignment.center,
            children: [
              // Halo lumineux vert doux
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),

              // Carré arrondi mint
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              // Petit bouclier vert en bas à droite
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 3. Titre principal
          const Text(
            'Réinitialiser votre mot de\npasse',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 10),

          // 4. Sous-titre
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Entrez votre e-mail pour recevoir un lien de réinitialisation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Message d'erreur éventuel
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. Champ Email
          CustomTextField(
            label: 'Adresse e-mail',
            isRequiredText: 'Requis',
            hintText: 'exemple@gmail.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir votre adresse e-mail';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Veuillez saisir une adresse e-mail valide';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // 6. Bouton principal "Envoyer le lien →"
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSendLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(AppSizes.buttonHeightDefault),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: AppSizes.iconMd + 2,
                    height: AppSizes.iconMd + 2,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Envoyer le lien',
                        style: TextStyle(
                          fontSize: AppSizes.fontDefault,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: AppSizes.spaceXsm),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: AppSizes.iconSm,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          // 7. Boîte "Une difficulté ? Assistance citoyenne"
          InkWell(
            onTap: _showAssistanceDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Une difficulté ?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Notre assistance citoyenne vous accompagne 24/7.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // 8. Lien "← Retour à la connexion"
          InkWell(
            onTap: widget.onBackToLogin ?? () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Retour à la connexion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Écran 2 : Confirmation d'envoi d'e-mail (Page 5) ---
  Widget _buildSuccessView() {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            AppBackButton(
              onPressed: () {
                setState(() => _isEmailSent = false);
              },
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Icône de succès avec enveloppe & check
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 50,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'E-mail envoyé !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text:
                      'Un lien sécurisé de réinitialisation a été envoyé à l\'adresse :\n',
                ),
                TextSpan(
                  text: email.isNotEmpty ? email : 'votre adresse e-mail',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const TextSpan(
                  text: '.\nVérifiez votre boîte de réception (et vos spams).',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 36),

        // Bouton pour tester directement la page 6 (Nouveau mot de passe)
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResetPasswordView(userEmail: email),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Saisir le nouveau mot de passe',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Bouton "Retour à la connexion"
        OutlinedButton(
          onPressed: widget.onBackToLogin ?? () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border, width: 1.2),
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(54),
          ),
          child: const Text(
            'Retour à la connexion',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
