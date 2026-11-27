import 'package:flutter/material.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/logo_findmydoc.dart';
import '../home/main_screen.dart';
import '../onboarding/onboarding_view.dart';
import 'forgot_password_view.dart';
import 'register_view.dart';

/// Écran de Connexion (Login) de l'application Finds
class LoginView extends StatefulWidget {
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;
  final VoidCallback? onLoginSuccess;

  const LoginView({
    super.key,
    this.onRegisterTap,
    this.onForgotPasswordTap,
    this.onLoginSuccess,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Réinitialise les erreurs
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final result = await FindsApiClient.mutate(
        GraphQLQueries.loginMutation,
        variables: {
          'input': {'email': email, 'password': password},
        },
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result.hasException) {
        final ex = result.exception;
        String message = 'Identifiants incorrects.';
        if (ex?.graphqlErrors.isNotEmpty ?? false) {
          message = ex!.graphqlErrors.first.message;
        } else if (ex?.linkException != null) {
          message = 'Serveur API inaccessible. Vérifiez votre connexion.';
        }
        setState(() {
          _errorMessage = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final data = result.data?['login'];
      final token = (data?['accessToken'] ?? data?['token']) as String?;
      final refreshToken = data?['refreshToken'] as String?;
      final user = data?['user'] as Map<String, dynamic>?;

      if (token != null) {
        await FindsApiClient.signIn(
          accessToken: token,
          refreshToken: refreshToken ?? '',
          user: user ?? {},
        );
        if (!mounted) return;

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
      } else {
        const errorMsg = 'Mot de passe incorrect.';
        setState(() {
          _errorMessage = errorMsg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[LoginView] Échec de connexion : $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Mot de passe incorrect.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceXl,
            vertical: AppSizes.spaceMd,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header : Flèche retour + Pilule Logo Finds centrée
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bouton retour moderne circulaire (fidèle à Figma)
                    AppBackButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const OnboardingView(),
                            ),
                          );
                        }
                      },
                    ),

                    // Pilule centrale Logo Finds
                    const Flexible(child: Center(child: LogoFinds.pill())),

                    // Espaceur symétrique pour conserver le logo au centre
                    const SizedBox(width: AppSizes.buttonHeightSm),
                  ],
                ),

                const SizedBox(height: AppSizes.spaceXxl - 4),

                // 2. Titre avec point vert distinctif
                Row(
                  children: [
                    const Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: AppSizes.fontXxl + 2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceXxsm),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.spaceXsm),

                // 3. Sous-titre
                const Text(
                  'Heureux de vous revoir ! Accédez à votre espace sécurisé.',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: AppSizes.spaceXxl - 4),

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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Champ Adresse e-mail
                CustomTextField(
                  label: 'Adresse e-mail',
                  hintText: 'exemple@gmail.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir votre adresse e-mail';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Veuillez saisir une adresse e-mail valide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 5. En-tête Mot de passe avec lien "Mot de passe oublié ?"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mot de passe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap:
                          widget.onForgotPasswordTap ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordView(),
                              ),
                            );
                          },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Champ Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit comporter au moins 6 caractères';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: '••••••••••••',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.6,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1.2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 6. Pillule d'information de sécurité
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connexion sécurisée et numéros de document masqués.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.spaceXl),

                // 7. Bouton principal "Se connecter →"
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(
                      AppSizes.buttonHeightDefault,
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: AppSizes.iconMd + 2,
                          height: AppSizes.iconMd + 2,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Se connecter',
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

                const SizedBox(height: 28),

                // 8. Pied de page : "Pas encore de compte ? Créer un compte"
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap:
                            widget.onRegisterTap ??
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterView(),
                                ),
                              );
                            },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Text(
                            'Créer un compte',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
