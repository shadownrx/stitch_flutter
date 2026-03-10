import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _emerald     = Color(0xFF0E9E6E);
  static const Color _emeraldDark = Color(0xFF077A53);
  static const Color _emeraldSoft = Color(0xFFE8F7F2);
  static const Color _ink         = Color(0xFF0F1C2E);
  static const Color _inkMid      = Color(0xFF3D5068);
  static const Color _slate       = Color(0xFF8A9AB0);
  static const Color _line        = Color(0xFFE4EAF0);
  static const Color _surface     = Color(0xFFF7F9FC);
  static const Color _white       = Color(0xFFFFFFFF);

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
    _emailController.dispose();
    _passwordController.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52),
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 40),
                    _buildGoogleButton()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 150.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    _buildDivider()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 250.ms),
                    const SizedBox(height: 24),
                    _buildFormFields()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 320.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 32),
                    _buildLoginButton()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 420.ms),
                    const SizedBox(height: 28),
                    _buildRegisterRow()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 500.ms),
                    const SizedBox(height: 52),
                    _buildFooter()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 600.ms),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Top emerald glow
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
          // Bottom left soft blob
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _emeraldSoft.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Dot grid texture
          CustomPaint(
            painter: _DotGridPainter(dotColor: _line),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wordmark badge
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
              const Icon(Icons.auto_stories_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'ESCOLARIS',
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
          'Bienvenido\nde vuelta.',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 38,
            height: 1.1,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Gestiona tus clases con eficiencia',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: _slate,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Google Button — ORIGINAL LOGIC PRESERVED ─────────────────────────────

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final user = await authService.signInWithGoogle();
              setState(() => _isLoading = false);
              if (user != null) {
                // AuthWrapper handles navigation
              } else {
                // User canceled or error
              }
            },
      icon: const Icon(Icons.g_mobiledata, size: 32, color: Color(0xFF4285F4)),
      label: Text(
        'Continuar con Google',
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        backgroundColor: _white,
        side: BorderSide(color: _line, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
    );
  }

  // ── Divider ──────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o accede con correo',
            style: GoogleFonts.dmSans(fontSize: 13, color: _slate),
          ),
        ),
        Expanded(child: Divider(color: _line, thickness: 1)),
      ],
    );
  }

  // ── Form Fields ──────────────────────────────────────────────────────────

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        _buildFieldLabel('Correo Institucional'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _emailController,
          hint: 'nombre@colegio.edu',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Password header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('Contraseña'),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '¿Olvidaste la contraseña?',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _emerald,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Password field
        Container(
          decoration: _fieldDecoration(),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.dmSans(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.dmSans(color: _slate, fontSize: 15),
              prefixIcon:
                  Icon(Icons.lock_outline_rounded, color: _slate, size: 20),
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _slate,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Remember me
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _rememberMe ? _emerald : _white,
                  border: Border.all(
                    color: _rememberMe ? _emerald : _line,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _rememberMe
                      ? [
                          BoxShadow(
                            color: _emerald.withOpacity(0.25),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
                child: _rememberMe
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                'Mantener sesión iniciada',
                style: GoogleFonts.dmSans(fontSize: 14, color: _inkMid),
              ),
            ],
          ),
        ),
      ],
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  // ── Login Button — ORIGINAL LOGIC PRESERVED ──────────────────────────────

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final user = await authService.signInWithEmailAndPassword(
                _emailController.text.trim(),
                _passwordController.text,
              );
              setState(() => _isLoading = false);
              if (user != null) {
                // The AuthWrapper will handle navigation
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error al iniciar sesión',
                      style: GoogleFonts.dmSans(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFFD94040),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
                  colors: [_emerald, _emeraldDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _isLoading ? _line : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
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
                      'Iniciar Sesión',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Register Row ─────────────────────────────────────────────────────────

  Widget _buildRegisterRow() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Nuevo en la plataforma? ',
            style: GoogleFonts.dmSans(fontSize: 14, color: _slate),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Regístrate ahora',
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

  // ── Footer ───────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBadge(
                  Icons.verified_user_outlined, 'SEGURIDAD\nEDUCATIVA'),
              Container(width: 1, height: 36, color: _line),
              _buildBadge(
                  Icons.support_agent_outlined, 'SOPORTE\nTÉCNICO 24/7'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '© 2024 Educator Solutions. Todos los derechos reservados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 11, color: _slate),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _emerald, size: 22),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _inkMid,
            height: 1.5,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Dot grid background painter ───────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  const _DotGridPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 28.0;
    const radius = 1.2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.dotColor != dotColor;
}