import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  final String language;
  final Function(String) onLanguageChanged;

  const RegisterScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _lang;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  String _selectedRole = 'Admin'; // Default role

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'title': 'Create Account',
      'subtitle': 'Join Vision Medical today',
      'name': 'Full Name',
      'name_empty': 'Please enter your full name',
      'email': 'Email Address',
      'email_empty': 'Please enter your email',
      'email_invalid': 'Please enter a valid email address',
      'phone': 'Phone Number',
      'phone_empty': 'Please enter your phone number',
      'password': 'Password',
      'password_empty': 'Please enter your password',
      'password_short': 'Password must be at least 6 characters',
      'role': 'User Role',
      'role_patient': 'Hospital Admin',
      'role_doctor': 'Biomedical Engineer',
      'role_optom': 'Sales Rep',
      'agree_terms': 'I agree to the Terms & Conditions',
      'agree_error': 'You must agree to the terms to proceed',
      'register': 'Sign Up',
      'have_account': 'Already have an account? ',
      'login_now': 'Login Here',
      'success_msg': 'Registration successful!',
    },
    'ar': {
      'title': 'إنشاء حساب جديد',
      'subtitle': 'انضم إلى نظام فيجن ميدكال اليوم',
      'name': 'الاسم الكامل',
      'name_empty': 'يرجى إدخال الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'email_empty': 'يرجى إدخال البريد الإلكتروني',
      'email_invalid': 'يرجى إدخال بريد إلكتروني صحيح',
      'phone': 'رقم الهاتف',
      'phone_empty': 'يرجى إدخال رقم الهاتف',
      'password': 'كلمة المرور',
      'password_empty': 'يرجى إدخال كلمة المرور',
      'password_short': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل',
      'role': 'نوع الحساب',
      'role_patient': 'إدارة المستشفى',
      'role_doctor': 'مهندس أجهزة طبية',
      'role_optom': 'مندوب مبيعات',
      'agree_terms': 'أوافق على الشروط والأحكام الخاصة بالخدمة',
      'agree_error': 'يجب الموافقة على الشروط والأحكام للمتابعة',
      'register': 'تسجيل حساب جديد',
      'have_account': 'هل لديك حساب بالفعل؟ ',
      'login_now': 'تسجيل الدخول',
      'success_msg': 'تم إنشاء الحساب بنجاح!',
    }
  };

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('agree_error')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('success_msg')),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home with user's email
      Navigator.of(context).pushReplacementNamed(
        '/home',
        arguments: _emailController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.teal[800]),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton.icon(
              onPressed: _toggleLanguage,
              icon: Icon(Icons.language, color: Colors.teal[800]),
              label: Text(
                _lang == 'en' ? 'العربية' : 'English',
                style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Section
                  Text(
                    t('title'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('subtitle'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Name Field
                  _buildTextField(
                    controller: _nameController,
                    label: t('name'),
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t('name_empty');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: t('email'),
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t('email_empty');
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(value)) {
                        return t('email_invalid');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  _buildTextField(
                    controller: _phoneController,
                    label: t('phone'),
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t('phone_empty');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: t('password'),
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t('password_empty');
                      }
                      if (value.length < 6) {
                        return t('password_short');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Role selector section
                  Text(
                    t('role'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleOption('Admin', t('role_patient')),
                      const SizedBox(width: 8),
                      _buildRoleOption('Engineer', t('role_doctor')),
                      const SizedBox(width: 8),
                      _buildRoleOption('SalesRep', t('role_optom')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Terms & Conditions Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        activeColor: Colors.teal[800],
                        onChanged: (val) {
                          setState(() {
                            _agreeToTerms = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          t('agree_terms'),
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      t('register'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t('have_account'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          t('login_now'),
                          style: TextStyle(
                            color: Colors.teal[800],
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String role, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal[50] : Colors.grey[50],
            border: Border.all(
              color: isSelected ? Colors.teal[800]! : Colors.grey[300]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.teal[800] : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal[800]),
        suffixIcon: suffixIcon,
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
    );
  }
}
