import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/photo_service.dart';
import '../../../core/services/photo_upload_service.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/photo_source_sheet.dart';
import '../../../core/utils/name_utils.dart';

/// Écran de modification du profil citoyen
class EditProfileView extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialAddress;

  const EditProfileView({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    this.initialAddress = '',
  });

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isLoading = false;

  /// Valeurs au chargement : le bouton Enregistrer ne s'active que si
  /// quelque chose a changé.
  late final Map<TextEditingController, String> _initial;
  bool _photoChanged = false;

  bool get _isDirty =>
      _photoChanged ||
      _initial.entries.any((e) => e.key.text.trim() != e.value.trim());

  @override
  void initState() {
    super.initState();
    // Prénom et nom séparés, lus directement sur le compte : l'app ne
    // devine plus lequel des deux mots est le prénom.
    final user = FindsApiClient.currentUser.value;
    var prenom = (user?['prenom'] as String? ?? '').trim();
    var nom = (user?['nom'] as String? ?? '').trim();
    if (prenom.isEmpty && nom.isEmpty) {
      final parts = widget.initialName.trim().split(RegExp(r'\s+'));
      prenom = parts.first;
      nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    _firstNameController = TextEditingController(text: prenom);
    _lastNameController = TextEditingController(text: nom);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _addressController = TextEditingController(
      text: widget.initialAddress.isNotEmpty
          ? widget.initialAddress
          : FindsApiClient.userAddress,
    );
    _initial = {
      _lastNameController: _lastNameController.text,
      _firstNameController: _firstNameController.text,
      _phoneController: _phoneController.text,
      _addressController: _addressController.text,
    };
    for (final c in _initial.keys) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  /// Demande confirmation avant de quitter avec des changements non
  /// enregistrés.
  Future<bool> _confirmDiscard() async {
    if (!_isDirty || _isLoading) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quitter sans enregistrer ?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Vos modifications seront perdues.',
          style: TextStyle(color: AppColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  void dispose() {
    for (final c in _initial.keys) {
      c.removeListener(_onFieldChanged);
    }
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await PhotoService.pick(source: source);
      if (photo == null || !mounted) return;

      await FindsApiClient.setAvatar(photo.bytes, name: photo.name);
      if (!mounted) return;
      setState(() => _photoChanged = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Photo de profil sélectionnée !'),
        ),
      );
    } on PhotoTooLargeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(e.toString())),
      );
    } catch (e) {
      debugPrint('[EditProfileView] Erreur sélection photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Impossible d\'ouvrir le sélecteur de photo.'),
        ),
      );
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prenom = formatFirstName(_firstNameController.text);
    final nom = formatLastName(_lastNameController.text);
    final telephone = _phoneController.text.trim();
    final adresse = _addressController.text.trim();

    final input = <String, dynamic>{
      'prenom': prenom,
      'nom': nom,
      'telephone': telephone,
      if (adresse.isNotEmpty) 'ville': adresse,
    };

    final avatarBytes = FindsApiClient.userAvatarBytes.value;
    if (avatarBytes != null) {
      final url = await PhotoUploadService.uploadImageBytes(
        avatarBytes,
        filename: FindsApiClient.userAvatar.value ?? 'avatar.jpg',
      );
      if (url != null) input['avatarUrl'] = url;
    }

    final res = await FindsApiClient.mutate(
      GraphQLQueries.updateUserMutation,
      variables: {'input': input},
    );
    final ok = res.data?['updateUser']?['success'] == true;

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            FindsApiClient.errorMessage(
              res.exception,
              fallback:
                  res.data?['updateUser']?['message'] as String? ??
                  'Mise à jour impossible.',
            ),
          ),
        ),
      );
      return;
    }

    await FindsApiClient.updateCurrentUser({
      ...input,
      'adresse': adresse,
      'ville': adresse,
    });
    if (!mounted) return;
    _photoChanged = false;
    for (final c in _initial.keys) {
      _initial[c] = c.text;
    }
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: AppSizes.iconSm,
            ),
            SizedBox(width: AppSizes.spaceXsm),
            Text(
              'Profil mis à jour avec succès !',
              style: TextStyle(fontSize: AppSizes.fontSm),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty || _isLoading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && context.mounted) {
          _photoChanged = false;
          for (final c in _initial.keys) {
            c.text = _initial[c]!;
          }
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.spaceMd,
                    AppSizes.spaceMd,
                    AppSizes.spaceMd,
                    AppSizes.spaceXl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: AppSizes.spaceL),
                        _buildSection(
                          title: 'Identité',
                          subtitle:
                              'Tel qu\'indiqué sur vos pièces d\'identité',
                          icon: Icons.badge_rounded,
                          children: [
                            _buildField(
                              label: 'Nom de famille',
                              hint: 'Votre nom',
                              controller: _lastNameController,
                              icon: Icons.badge_outlined,
                              upperCase: true,
                              required: true,
                            ),
                            _buildField(
                              label: 'Prénom',
                              hint: 'Votre prénom',
                              controller: _firstNameController,
                              icon: Icons.person_outline_rounded,
                              capitalization: TextCapitalization.words,
                              required: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        _buildSection(
                          title: 'Coordonnées',
                          subtitle:
                              'Pour être contacté quand un document est retrouvé',
                          icon: Icons.contact_mail_rounded,
                          children: [
                            _buildField(
                              label: 'Adresse e-mail',
                              hint: 'Votre adresse e-mail',
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              readOnly: true,
                              helper:
                                  'L\'adresse e-mail sert à vous connecter et ne peut pas être modifiée ici.',
                            ),
                            _buildField(
                              label: 'Numéro de téléphone',
                              hint: 'Votre numéro de téléphone',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildField(
                              label: 'Ville / quartier',
                              hint: 'Votre ville et votre quartier',
                              controller: _addressController,
                              icon: Icons.location_on_outlined,
                              keyboardType: TextInputType.streetAddress,
                              capitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        _buildPrivacyNote(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSaveBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceMd,
        vertical: AppSizes.spaceSm - 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          AppBackButton(onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: AppSizes.spaceSm),
          const Expanded(
            child: Text(
              'Modifier mon profil',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── En-tête : photo + aperçu du nom ───────────────────────────────────────

  Future<void> _changePhoto() async {
    final source = await showPhotoSourceSheet(
      context,
      title: 'Changer la photo de profil',
    );
    if (source != null) await _pickPhoto(source);
  }

  Widget _buildProfileHeader() {
    final prenom = formatFirstName(_firstNameController.text);
    final nom = formatLastName(_lastNameController.text);
    final fullName = [prenom, nom].where((s) => s.isNotEmpty).join(' ');
    final initial = (prenom.isNotEmpty ? prenom : nom).isNotEmpty
        ? (prenom.isNotEmpty ? prenom : nom)[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'Changer la photo de profil',
            child: InkWell(
              onTap: _changePhoto,
              customBorder: const CircleBorder(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ValueListenableBuilder<Uint8List?>(
                      valueListenable: FindsApiClient.userAvatarBytes,
                      builder: (context, bytes, _) => CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary,
                        backgroundImage: bytes != null
                            ? MemoryImage(bytes)
                            : null,
                        child: bytes == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fullName.isEmpty ? 'Votre nom' : fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: fullName.isEmpty
                  ? AppColors.textMuted
                  : AppColors.textStrong,
            ),
          ),
          if (_emailController.text.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _emailController.text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSubtle,
              ),
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: _changePhoto,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.photo_camera_outlined, size: 16),
                    ),
                  ),
                  TextSpan(text: 'Changer la photo'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections et champs ────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool upperCase = false,
    bool readOnly = false,
    bool required = false,
    String? helper,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      borderSide: BorderSide(color: c, width: w),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            textCapitalization: upperCase
                ? TextCapitalization.characters
                : capitalization,
            inputFormatters: upperCase
                ? const [UpperCaseTextFormatter()]
                : null,
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w500,
              color: readOnly ? AppColors.textSubtle : AppColors.textStrong,
            ),
            validator: required
                ? (v) => v == null || v.trim().isEmpty
                      ? 'Ce champ est obligatoire'
                      : null
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: AppSizes.fontSm + 0.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: readOnly ? AppColors.inputFill : Colors.white,
              prefixIcon: Icon(
                icon,
                color: readOnly ? AppColors.textMuted : AppColors.primary,
                size: AppSizes.iconMd,
              ),
              suffixIcon: readOnly
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    )
                  : null,
              helperText: helper,
              helperMaxLines: 2,
              helperStyle: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSubtle,
              ),
              contentPadding: AppSizes.paddingInput,
              border: border(AppColors.border),
              enabledBorder: border(
                readOnly ? Colors.transparent : AppColors.border,
              ),
              focusedBorder: border(
                readOnly ? Colors.transparent : AppColors.primary,
                1.6,
              ),
              errorBorder: border(AppColors.error),
              focusedErrorBorder: border(AppColors.error, 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vos informations restent privées. Elles ne sont partagées '
              'qu\'avec la personne concernée, une fois une correspondance '
              'confirmée.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre d'enregistrement fixe en bas ────────────────────────────────────

  Widget _buildSaveBar() {
    final enabled = _isDirty && !_isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.spaceMd,
        10,
        AppSizes.spaceMd,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeightDefault,
        child: ElevatedButton(
          onPressed: enabled ? _saveProfile : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.chipBackground,
            disabledForegroundColor: AppColors.textSubtle,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isDirty
                      ? 'Enregistrer les modifications'
                      : 'Aucune modification',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
