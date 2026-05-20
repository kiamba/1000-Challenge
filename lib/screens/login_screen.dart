import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _dbService = DatabaseService();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(); 
  
  bool _isLoginMode = true; 
  bool _isLoading = false;
  bool _obscurePassword = true; 
  String _infoMessage = "";
  Color _messageColor = Colors.red;

  void _submitAuth() async {
    setState(() {
      _isLoading = true;
      _infoMessage = "";
      _messageColor = Colors.red;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLoginMode && phone.isEmpty)) {
      setState(() {
        _infoMessage = "Please complete all fields required for this action.";
        _isLoading = false;
      });
      return;
    }

    if (!_isLoginMode) {
      final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$'); 
      if (!phone.startsWith('+') || !phoneRegex.hasMatch(phone)) {
        setState(() {
          _infoMessage = "⚠️ Invalid Format! Phone number must begin with a '+' followed immediately by your country code (e.g., +254712345678).";
          _messageColor = Colors.orange.shade900;
          _isLoading = false;
        });
        return;
      }
    }

    try {
      if (_isLoginMode) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        if (credential.user != null) {
          await _dbService.createUserProfile(credential.user!.uid, email, phone);
        }
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _infoMessage = e.message ?? "Authentication failed.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _infoMessage = "⚠️ Type your email address above first, then click Forgot Password again.";
        _messageColor = Colors.orange.shade900;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      setState(() {
        _infoMessage = "📩 Reset link dispatched successfully! Check your email inbox and spam folders.";
        _messageColor = Colors.green.shade800;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _infoMessage = e.message ?? "Failed to issue password reset request.";
        _messageColor = Colors.red;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 📐 RESPONSIVE ENGINE CALCULATION
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double dynamicHorizontalMargin = deviceWidth > 600 ? deviceWidth * 0.15 : 24.0;

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dynamicHorizontalMargin),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLoginMode ? Icons.lock_person : Icons.person_add,
                      size: deviceWidth > 360 ? 64 : 48, // Shrinks gracefully on small displays
                      color: Colors.blue.shade800,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLoginMode ? "1000 Challenge Gateway" : "Create Admin Account",
                      style: TextStyle(
                        fontSize: deviceWidth > 360 ? 22 : 18, 
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_isLoginMode) ...[
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          hintText: "e.g., +254 712 345678",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.vpn_key),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    
                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handlePasswordReset,
                          child: Text(
                            "Forgot Password?", 
                            style: TextStyle(
                              color: Colors.blue.shade800, 
                              fontWeight: FontWeight.w600, 
                              fontSize: 13
                            ),
                          ),
                        ),
                      ),
                    
                    if (_infoMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _infoMessage, 
                        style: TextStyle(color: _messageColor, fontSize: 13, fontWeight: FontWeight.bold), 
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isLoginMode ? "Sign In to Dashboard" : "Register Account", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () => setState(() {
                        _isLoginMode = !_isLoginMode;
                        _infoMessage = "";
                      }),
                      child: Text(
                        _isLoginMode ? "Don't have an account? Register here" : "Already have an account? Sign In",
                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}