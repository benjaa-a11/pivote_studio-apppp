import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_notifications.dart';
import '../../config/app_animations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  bool _isLoading = false;
  bool _changePasswordExpanded = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update User Info
      if (user.name != _nameController.text.trim() ||
          user.lastName != _lastNameController.text.trim()) {
        final updatedUser = user.copyWith(
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

        await AuthService.updateUser(updatedUser);
        await userProvider.refreshUser(); // Refresh local state
      }

      // 2. Update Password if requested
      if (_changePasswordExpanded && _newPasswordController.text.isNotEmpty) {
        // Note: Updating password typically requires re-authentication (entering current password).
        // For simplicity in this demo, we assume the session is fresh enough or we catch the error.
        // In a production app, you'd ask for re-auth credentials here.
        try {
          await userProvider.updatePassword(_newPasswordController.text);
          if (mounted) {
            AppNotifications.showSuccess(context, 'Contraseña actualizada');
            _newPasswordController.clear();
            setState(() => _changePasswordExpanded = false);
          }
        } catch (e) {
          if (e.toString().contains('requires-recent-login')) {
            if (mounted) {
              AppNotifications.showError(context,
                  'Por seguridad, inicia sesión nuevamente para cambiar tu contraseña');
            }
          } else {
            rethrow;
          }
        }
      }

      if (mounted) {
        AppNotifications.showSuccess(
            context, 'Perfil actualizado correctamente');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
            context, 'Error al guardar: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white54,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: theme.colorScheme.onSurface),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AppAnimations.smoothFadeIn(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileImage(context),
                      const SizedBox(height: 40),
                      _buildSectionHeader(theme, 'Información Personal'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre',
                        icon: Icons.person_outline,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Apellido',
                        icon: Icons.badge_outlined,
                        theme: theme,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(theme, 'Seguridad'),
                      const SizedBox(height: 16),
                      _buildPasswordSection(theme),
                      const SizedBox(height: 40),
                      _buildSaveButton(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final imagePath = userProvider.profileImagePath;
    final theme = Theme.of(context);
    final user = userProvider.user;

    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: imagePath != null
                  ? FileImage(File(imagePath))
                  : (user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!) as ImageProvider
                      : null), // Fallback to network or null
              child: (imagePath == null && user?.photoUrl == null)
                  ? Icon(Icons.person,
                      size: 60,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5))
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => userProvider.updateProfileImage(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor, width: 3),
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.ubuntu(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(color: theme.hintColor),
        ),
        validator: (value) {
          if (!isPassword && (value == null || value.isEmpty)) {
            return 'Este campo es requerido';
          }
          if (isPassword && _changePasswordExpanded && value!.length < 6) {
            return 'La contraseña debe tener al menos 6 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordSection(ThemeData theme) {
    return Column(
      children: [
        if (!_changePasswordExpanded)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _changePasswordExpanded = true),
              icon: const Icon(Icons.lock_reset),
              label: const Text('Cambiar Contraseña'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        if (_changePasswordExpanded) ...[
          // Note: In a real app we would ask for current password too
          _buildTextField(
            controller: _newPasswordController,
            label: 'Nueva Contraseña',
            icon: Icons.lock_outline,
            theme: theme,
            isPassword: true,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _changePasswordExpanded = false;
                _newPasswordController.clear();
              });
            },
            child: Text(
              'Cancelar cambio de contraseña',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          'GUARDAR CAMBIOS',
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
