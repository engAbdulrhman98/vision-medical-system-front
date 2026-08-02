import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vision_medical_system_app/services/db_helper.dart';

class LoginScreen extends StatefulWidget {
  final String language;
  final Function(String) onLanguageChanged;

  const LoginScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _lang;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _checkingSession = true;
  String _backendUrl = '';

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'welcome_title': 'Vision Medical',
      'welcome_sub': 'Medical Equipment & Device Solutions',
      'login_title': 'Welcome Back',
      'login_sub': 'Sign in to manage inventory & service tickets',
      'email_label': 'Username or Email',
      'email_empty': 'Please enter username or email',
      'email_invalid': 'Please enter a valid format',
      'password_label': 'Password',
      'password_empty': 'Please enter your password',
      'forgot_pwd': 'Forgot Password?',
      'login_btn': 'Login',
      'no_account': "Don't have an account? ",
      'register_now': 'Register Here',
      'forgot_title': 'Reset Password',
      'forgot_body': 'Enter your email to receive a password reset link.',
      'forgot_success': 'Password reset link sent to your email.',
      'close': 'Close',
      'send': 'Send Link',
      'cancel': 'Cancel',
    },
    'ar': {
      'welcome_title': 'نظام فيجن ميدكال',
      'welcome_sub': 'حلول ومعدات الأجهزة الطبية المتكاملة',
      'login_title': 'مرحباً بك مجدداً',
      'login_sub': 'سجل الدخول لإدارة المخون وطلبات الصيانة',
      'email_label': 'اسم المستخدم أو البريد الإلكتروني',
      'email_empty': 'يرجى إدخال اسم المستخدم أو البريد الإلكتروني',
      'email_invalid': 'يرجى إدخال صيغة صحيحة',
      'password_label': 'كلمة المرور',
      'password_empty': 'يرجى إدخال كلمة المرور',
      'forgot_pwd': 'هل نسيت كلمة المرور؟',
      'login_btn': 'تسجيل الدخول',
      'no_account': 'ليس لديك حساب؟ ',
      'register_now': 'أنشئ حساباً جديداً',
      'forgot_title': 'إعادة تعيين كلمة المرور',
      'forgot_body': 'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور.',
      'forgot_success': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.',
      'close': 'إغلاق',
      'send': 'إرسال الرابط',
      'cancel': 'إلغاء',
    }
  };

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    _initializeBackendUrl();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final cached = await ChatDatabaseHelper.instance.getFromCache('active_session');
    if (cached != null) {
      try {
        final session = jsonDecode(cached);
        if (session is Map) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/home',
              arguments: session,
            );
            return;
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _checkingSession = false;
      });
    }
  }

  void _initializeBackendUrl() {
    _backendUrl = 'https://vision-medical-system-back-production.up.railway.app/api';
    ChatDatabaseHelper.instance.getFromCache('backend_url').then((savedUrl) {
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _backendUrl = savedUrl.trim();
          });
        }
      }
    });
  }

  void _showApiConfigDialog() {
    final configController = TextEditingController(text: _backendUrl);
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              _lang == 'ar' ? 'إعدادات الاتصال بالخادم' : 'Server Connection Settings',
              style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lang == 'ar'
                      ? 'رابط API الخاص بـ Backend Laravel:'
                      : 'Laravel Backend API URL:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: configController,
                  decoration: InputDecoration(
                    hintText: 'http://10.154.156.25:8000/api',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal[800]!),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_lang == 'ar' ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  final newUrl = configController.text.trim();
                  setState(() {
                    _backendUrl = newUrl;
                  });
                  ChatDatabaseHelper.instance.saveToCache('backend_url', newUrl);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_lang == 'ar' ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  String t(String key) {
    return _localized[_lang]?[key] ?? key;
  }

  void _toggleLanguage() {
    final newLang = _lang == 'en' ? 'ar' : 'en';
    setState(() {
      _lang = newLang;
    });
    widget.onLanguageChanged(newLang);
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final emailInput = _emailController.text.trim();
      final passInput = _passwordController.text;

      // Primary & fallback candidate URLs to attempt
      List<String> candidateUrls = [];
      if (_backendUrl.isNotEmpty) {
        candidateUrls.add(_backendUrl);
      }
      const localUrl = 'http://10.154.156.25:8000/api';
      const railwayUrl = 'https://vision-medical-system-back-production.up.railway.app/api';
      
      if (!candidateUrls.contains(localUrl)) candidateUrls.add(localUrl);
      if (!candidateUrls.contains(railwayUrl)) candidateUrls.add(railwayUrl);

      http.Response? finalResponse;
      String? workingUrl;

      for (final url in candidateUrls) {
        try {
          final res = await http.post(
            Uri.parse('$url/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': emailInput,
              'password': passInput,
            }),
          ).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200) {
            finalResponse = res;
            workingUrl = url;
            break;
          } else if (res.statusCode == 401 || res.statusCode == 422) {
            // Server responded with explicit invalid credentials error
            finalResponse = res;
            workingUrl = url;
            break;
          }
        } catch (_) {}
      }

      if (finalResponse != null && finalResponse.statusCode == 200) {
        final data = jsonDecode(finalResponse.body);
        final String token = data['access_token'] ?? '';
        final user = data['user'] ?? {};

        if (workingUrl != null) {
          _backendUrl = workingUrl;
          ChatDatabaseHelper.instance.saveToCache('backend_url', workingUrl);
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _lang == 'ar' ? 'تم تسجيل الدخول بنجاح!' : 'Login successful!',
              ),
              backgroundColor: Colors.teal[800],
            ),
          );

          final sessionArgs = {
            'email': emailInput,
            'token': token,
            'backendUrl': _backendUrl,
            'user': user,
          };
          ChatDatabaseHelper.instance.saveToCache('active_session', jsonEncode(sessionArgs)).then((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(
                '/home',
                arguments: sessionArgs,
              );
            }
          });
        }
        return;
      } else if (finalResponse != null && (finalResponse.statusCode == 401 || finalResponse.statusCode == 422)) {
        String errorMsg = _lang == 'ar' 
            ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.' 
            : 'Invalid email or password.';
        try {
          final data = jsonDecode(finalResponse.body);
          if (data['message'] != null) {
            errorMsg = data['message'];
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar(errorMsg);
        }
        return;
      }

      // Offline / Local Fallback match for known demo accounts
      final emailLower = emailInput.toLowerCase();
      Map? mockUser;
      if (emailLower == 'admin@vision-medical.com' || emailLower == 'admin' || emailLower == 'admin@vision.com' || emailLower == 'test@example.com') {
        mockUser = {'role': 'admin', 'name': 'م. أحمد علي (مدير النظام)', 'email': emailInput};
      } else if (emailLower == 'engineer@example.com' || emailLower == 'engineer') {
        mockUser = {'role': 'Service Engineer outdoor', 'name': 'م. أسامة مصطفى', 'email': emailInput};
      } else if (emailLower == 'accountant@example.com' || emailLower == 'accountant') {
        mockUser = {'role': 'accountant', 'name': 'أ. محمود جابر', 'email': emailInput};
      } else if (emailLower == 'inventory@example.com' || emailLower == 'seller' || emailLower == 'sales@vision.com') {
        mockUser = {'role': 'seller', 'name': 'أ. رانيا الباز', 'email': emailInput};
      } else if (emailLower == 'ceo@example.com' || emailLower == 'ceo') {
        mockUser = {'role': 'ceo', 'name': 'د. خالد عبد الرحمن (CEO)', 'email': emailInput};
      } else if (emailLower == 'operations@example.com' || emailLower == 'operations') {
        mockUser = {'role': 'operations manager', 'name': 'م. طارق المحمودي', 'email': emailInput};
      }

      if (mockUser != null && passInput.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _lang == 'ar'
                    ? 'تم تسجيل الدخول محلياً'
                    : 'Logged in locally',
              ),
              backgroundColor: Colors.teal[800],
            ),
          );
          
          final sessionArgs = {
            'email': emailInput,
            'token': 'offline_token',
            'backendUrl': _backendUrl,
            'user': mockUser,
          };
          ChatDatabaseHelper.instance.saveToCache('active_session', jsonEncode(sessionArgs)).then((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(
                '/home',
                arguments: sessionArgs,
              );
            }
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(
          _lang == 'ar'
              ? 'فشل الاتصال بالخادم. يرجى التأكد من كلمة المرور أو الاتصال بالشبكة.'
              : 'Connection failed. Please check your credentials or network.',
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';

    if (_isLoading || _checkingSession) {
      return Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.teal[50],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 110,
                    width: 110,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal[700]!, Colors.cyan[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t('welcome_title'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('welcome_sub'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Colors.teal[800],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[800]!),
                    backgroundColor: Colors.teal[100],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _checkingSession
                      ? (_lang == 'ar' ? 'جاري التحميل...' : 'Loading...')
                      : (_lang == 'ar' ? 'جاري تسجيل الدخول...' : 'Signing in...'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.teal[50], // Soft medical blue/teal background tint
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Language toggle and Settings bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.settings, color: Colors.teal[800]),
                                onPressed: _showApiConfigDialog,
                                tooltip: _lang == 'ar' ? 'إعدادات الاتصال' : 'Connection Settings',
                              ),
                              TextButton.icon(
                                onPressed: _toggleLanguage,
                                icon: Icon(Icons.language, color: Colors.teal[800]),
                                label: Text(
                                  _lang == 'en' ? 'العربية' : 'English',
                                  style: TextStyle(
                                    color: Colors.teal[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Header Logo & Branding
                          Center(
                            child: Column(
                              children: [
                                // Website logo image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.teal[700]!, Colors.cyan[600]!],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.remove_red_eye,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  t('welcome_title'),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[900],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t('welcome_sub'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Login Card with glassmorphism-like card look
                          Card(
                            elevation: 4,
                            shadowColor: Colors.teal.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      t('login_title'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t('login_sub'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Email Address Field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return t('email_empty');
                                        }
                                        // simple email or ID check
                                        if (value.contains('@') && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                                          return t('email_invalid');
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        labelText: t('email_label'),
                                        prefixIcon: Icon(Icons.email_outlined, color: Colors.teal[800]),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.teal[800]!, width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return t('password_empty');
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        labelText: t('password_label'),
                                        prefixIcon: Icon(Icons.lock_outline, color: Colors.teal[800]),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.teal[800],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.teal[800]!, width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Login Button
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _submitLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal[800],
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              t('login_btn'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
