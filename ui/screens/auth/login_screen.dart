import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Palet Warna Premium SIRA
  final Color navyColor = const Color(0xFF0F172A);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFFF8FAFC);

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan login.';
      if (e.code == 'user-not-found')
        message = 'Email tidak terdaftar.';
      else if (e.code == 'wrong-password')
        message = 'Password salah.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Decor (Aksen Navy di bagian atas)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              // Tambahkan const di sini jika ingin performa lebih baik
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(80)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ==========================================
                  // 1. LOGO & NAMA APLIKASI (SIRA)
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: goldColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: goldColor,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SIRA',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistem Informasi Riwayat Administrasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: goldColor.withOpacity(0.8),
                      letterSpacing: 1.0,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ==========================================
                  // 2. KARTU LOGIN (ROUNDED 30PX)
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: navyColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Silakan masuk untuk mengelola administrasi.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 32),

                        // Input Email
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Input Password
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onTogglePassword: () {
                            setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Tombol Login
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyColor,
                              foregroundColor: goldColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? CircularProgressIndicator(color: goldColor)
                                : const Text(
                                    'MASUK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Footer Branding
                  Text(
                    'SIRA v2.0.0 Premium Build',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          style: TextStyle(fontWeight: FontWeight.bold, color: navyColor),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: navyColor, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: navyColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
