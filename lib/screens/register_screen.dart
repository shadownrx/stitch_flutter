import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Step 2 Controllers
  final TextEditingController _instNameController = TextEditingController();
  final TextEditingController _instAddressController = TextEditingController();
  final TextEditingController _instJoinCodeController = TextEditingController();

  bool _isCreatingInstitution = true; // Toggle between Create and Join
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _emerald = Color(0xFF0E9E6E);
  static const Color _emeraldDark = Color(0xFF077A53);
  static const Color _emeraldSoft = Color(0xFFE8F7F2);
  static const Color _ink = Color(0xFF0F1C2E);
  static const Color _inkMid = Color(0xFF3D5068);
  static const Color _slate = Color(0xFF8A9AB0);
  static const Color _line = Color(0xFFE4EAF0);
  static const Color _surface = Color(0xFFF7F9FC);
  static const Color _white = Color(0xFFFFFFFF);

  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _instNameController.dispose();
    _instAddressController.dispose();
    _instJoinCodeController.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        _showError('Por favor completa todos los campos');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Las contraseñas no coinciden');
        return;
      }
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _prevStep,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _inkMid,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      _buildStepIndicator(),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildStepOne(), _buildStepTwo()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(2, (index) {
        return Container(
          width: 24,
          height: 4,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: _currentStep == index ? _emerald : _line,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildStepOne() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildHeader(
                  'Crea tu\ncuenta.',
                  'Únete a la mejor plataforma educativa',
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 40),
            _buildAccountFields()
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              'Continuar',
              _isLoading ? null : _nextStep,
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
            const SizedBox(height: 28),
            _buildLoginRow().animate().fadeIn(duration: 400.ms, delay: 400.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildHeader(
                  'Tu Institución.',
                  'Vincúlate a una escuela para comenzar',
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 30),
            _buildInstitutionTabs(),
            const SizedBox(height: 24),
            _buildInstitutionFields(),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              'Finalizar Registro',
              _isLoading ? null : _handleRegister,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionTabs() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              'Crear Nueva',
              _isCreatingInstitution,
              () => setState(() => _isCreatingInstitution = true),
            ),
          ),
          Expanded(
            child: _buildTab(
              'Unirse a una',
              !_isCreatingInstitution,
              () => setState(() => _isCreatingInstitution = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _ink.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _emerald : _slate,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _emerald,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _emerald.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'REGISTRO',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 38,
            height: 1.1,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: _slate,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Nombre Completo'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _nameController,
          hint: 'Ej. Juan Pérez',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Correo Institucional'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _emailController,
          hint: 'nombre@colegio.edu',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Contraseña'),
        const SizedBox(height: 8),
        _buildPasswordField(_passwordController, 'Crea una contraseña'),
        const SizedBox(height: 20),
        _buildFieldLabel('Confirmar Contraseña'),
        const SizedBox(height: 8),
        _buildPasswordField(_confirmPasswordController, 'Repite tu contraseña'),
      ],
    );
  }

  Widget _buildInstitutionFields() {
    if (_isCreatingInstitution) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Nombre de la Escuela'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _instNameController,
            hint: 'Ej. Colegio San Juan',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Dirección (Opcional)'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _instAddressController,
            hint: 'Ciudad, Calle...',
            icon: Icons.location_on_outlined,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('ID de la Institución'),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _instJoinCodeController,
            hint: 'Pega el código aquí',
            icon: Icons.qr_code_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'Pide el ID al administrador de tu institución para unirte.',
            style: GoogleFonts.dmSans(fontSize: 12, color: _slate, height: 1.5),
          ),
        ],
      );
    }
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) => Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _emerald.withOpacity(0.08 + _shimmerCtrl.value * 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_emeraldSoft.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _inkMid,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: _fieldDecoration(),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: _slate, fontSize: 15),
          prefixIcon: Icon(icon, color: _slate, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint) {
    return Container(
      decoration: _fieldDecoration(),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        style: GoogleFonts.dmSans(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: _slate, fontSize: 15),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: _slate,
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _slate,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _line, width: 1.5),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? null
              : const LinearGradient(
                  colors: [_emerald, _emeraldDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: onTap == null ? _line : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: _emerald.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // Basic validations for Step 2
    if (_isCreatingInstitution) {
      if (_instNameController.text.isEmpty) {
        _showError('Por favor ingresa el nombre de la institución');
        return;
      }
    } else {
      if (_instJoinCodeController.text.isEmpty) {
        _showError('Por favor ingresa el ID de la institución');
        return;
      }
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = DatabaseService();

    try {
      // 1. Firebase Auth Signup
      final user = await authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // 2. Create Teacher Profile
        await dbService.createTeacher(
          user.uid,
          _nameController.text.trim(),
          _emailController.text.trim(),
        );

        // 3. Institution Logic
        if (_isCreatingInstitution) {
          await dbService.createInstitution(
            user.uid,
            _instNameController.text.trim(),
            _instAddressController.text.trim().isEmpty
                ? null
                : _instAddressController.text.trim(),
          );
        } else {
          final success = await dbService.joinInstitution(
            user.uid,
            _instJoinCodeController.text.trim(),
          );
          if (!success) {
            _showError(
              'Cuenta creada, pero no se pudo unir a la institución. Puedes hacerlo después desde el Dashboard.',
            );
          }
        }

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro completado con éxito.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Error de autenticación');
    } catch (e) {
      _showError('Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: const Color(0xFFD94040),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoginRow() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Ya tienes cuenta? ',
            style: GoogleFonts.dmSans(fontSize: 14, color: _slate),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Inicia sesión',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
