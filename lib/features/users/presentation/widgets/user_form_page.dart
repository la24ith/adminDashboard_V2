import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class UserFormPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Function(Map<String, dynamic>) onSave;

  const UserFormPage({super.key, this.user, required this.onSave});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // صفحة 1: معلومات الحساب
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  String _role = 'patient';
  bool _accountValid = false;

  // صفحة 2: القياسات الصحية
  late TextEditingController _idealWeightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _heightController;
  bool _healthValid = false;

  // صفحة 3: الاشتراك
  late TextEditingController _planTypeController;
  late TextEditingController _priceController;
  late TextEditingController _maxDevicesController;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _allowMultiDevice;
  bool _subscriptionValid = false;

  int _currentStep = 0;
  bool _isSaving = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user?['name'] ?? '');
    _emailController = TextEditingController(text: widget.user?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.user?['phone'] ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _idealWeightController = TextEditingController(
        text: widget.user?['ideal_weight']?.toString() ?? '');
    _targetWeightController = TextEditingController(
        text: widget.user?['target_weight']?.toString() ?? '');
    _currentWeightController = TextEditingController(
        text: widget.user?['current_weight']?.toString() ?? '');
    _heightController =
        TextEditingController(text: widget.user?['height']?.toString() ?? '');

    _planTypeController =
        TextEditingController(text: widget.user?['plan_type'] ?? 'monthly');
    _priceController = TextEditingController(
        text: widget.user?['price']?.toString() ?? '199.99');
    _maxDevicesController = TextEditingController(
        text: widget.user?['max_devices']?.toString() ?? '1');

    _startDate = widget.user?['subscription_start'] != null
        ? DateTime.parse(widget.user!['subscription_start'])
        : DateTime.now();
    _endDate = widget.user?['subscription_end'] != null
        ? DateTime.parse(widget.user!['subscription_end'])
        : DateTime.now().add(const Duration(days: 30));
    _allowMultiDevice = widget.user?['multi_device_enabled'] ?? false;
    _role = widget.user?['role'] ?? 'patient';

    _validateAccount();
    _validateHealth();
    _validateSubscription();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _validateAccount() {
    setState(() {
      _accountValid = _nameController.text.isNotEmpty &&
          _emailController.text.contains('@') &&
          (widget.user != null ||
              (_passwordController.text.isNotEmpty &&
                  _passwordController.text == _confirmPasswordController.text));
    });
  }

  void _validateHealth() {
    // ✅ تحقق فعلي من البيانات الصحية (اختيارية)
    setState(() {
      _healthValid = true; // جميع القياسات اختيارية
    });
  }

  void _validateSubscription() {
    setState(() {
      _subscriptionValid = _endDate.isAfter(_startDate);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _idealWeightController.dispose();
    _targetWeightController.dispose();
    _currentWeightController.dispose();
    _heightController.dispose();
    _planTypeController.dispose();
    _priceController.dispose();
    _maxDevicesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.user == null ? 'إضافة مستخدم جديد' : 'تعديل المستخدم',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(),
            if (_errorMessage != null) _buildErrorMessage(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    _buildAccountPage(),
                    _buildHealthPage(),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(0, 'معلومات الحساب', Icons.person_outline),
          Expanded(child: _buildConnector(0)),
          _buildStepIndicator(1, 'القياسات الصحية', Icons.fitness_center),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted =
        (step == 0 && _accountValid) || (step == 1 && _healthValid);

    return GestureDetector(
      onTap: isCompleted
          ? () {
              setState(() {
                _currentStep = step;
                _animationController.reset();
                _animationController.forward();
              });
            }
          : null,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCompleted
                  ? LinearGradient(
                      colors: [AppColors.success, AppColors.accent],
                    )
                  : null,
              color: isActive
                  ? AppColors.accent
                  : (isCompleted ? null : AppColors.surface),
              border: Border.all(
                color: isActive
                    ? AppColors.accent
                    : (isCompleted ? AppColors.success : AppColors.border),
                width: 2,
              ),
            ),
            child: isCompleted && !isActive
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : Icon(
                    icon,
                    color: isActive
                        ? Colors.white
                        : (isCompleted
                            ? AppColors.success
                            : AppColors.textSecondary),
                    size: 24,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? AppColors.accent
                  : (isCompleted ? AppColors.success : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int step) {
    final isCompleted =
        (step == 0 && _accountValid) || (step == 1 && _healthValid);

    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [AppColors.success, AppColors.accent],
              )
            : null,
        color: isCompleted ? null : AppColors.border,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 12),
              const Text(
                'خطأ',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                onPressed: () => setState(() => _errorMessage = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('معلومات الحساب', 'البيانات الأساسية للمستخدم',
              Icons.person_outline),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            icon: Icons.person_outline,
            validator: (v) => v == null || v.isEmpty ? 'الاسم مطلوب' : null,
            onChanged: (v) => _validateAccount(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || !v.contains('@')
                ? 'بريد إلكتروني صحيح مطلوب'
                : null,
            onChanged: (v) => _validateAccount(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الهاتف (اختياري)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'الدور',
            icon: Icons.badge,
            value: _role,
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('مدير')),
              DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
              DropdownMenuItem(value: 'patient', child: Text('مريض')),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
          if (widget.user == null) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'كلمة المرور',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) =>
                  v == null || v.isEmpty ? 'كلمة المرور مطلوبة' : null,
              onChanged: (v) => _validateAccount(),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'تأكيد كلمة المرور',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                if (v != _passwordController.text)
                  return 'كلمة المرور غير متطابقة';
                return null;
              },
              onChanged: (v) => _validateAccount(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('القياسات الصحية',
              'البيانات الصحية والجسدية للمستخدم', Icons.fitness_center),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _idealWeightController,
            label: 'الوزن المثالي (كغ)',
            icon: Icons.monitor_weight,
            keyboardType: TextInputType.number,
            suffixText: 'كغ',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _targetWeightController,
            label: 'الوزن المستهدف (كغ)',
            icon: Icons.flag,
            keyboardType: TextInputType.number,
            suffixText: 'كغ',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _currentWeightController,
            label: 'الوزن الحالي (كغ)',
            icon: Icons.fitness_center,
            keyboardType: TextInputType.number,
            suffixText: 'كغ',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _heightController,
            label: 'الطول (سم)',
            icon: Icons.height,
            keyboardType: TextInputType.number,
            suffixText: 'سم',
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool obscureText = false,
    String? hint,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.accent),
          suffixText: suffixText,
          suffixStyle: TextStyle(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.accent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppColors.accent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          child: Text('${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 8),
                    Text('السابق'),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextOrSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_currentStep < 1 ? 'التالي' : 'حفظ',
                      style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _nextOrSave() {
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
      _save();
    }
  }

  // ✅ الدالة الوحيدة _save() داخل الكلاس
  Future<void> _save() async {
    if (_isSaving) return;

    // ✅ التحقق من وجود form key
    if (_formKey.currentState == null) {
      setState(() {
        _errorMessage = 'النموذج لم يكتمل تحميله بعد. يرجى المحاولة مرة أخرى.';
      });
      return;
    }

    // ✅ التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'يرجى تعبئة جميع الحقول المطلوبة بشكل صحيح';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // ✅ بناء البيانات باستخدام double.tryParse لتجنب الأخطاء
    final userData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _role,

      if (_phoneController.text.trim().isNotEmpty)
        'phone': _phoneController.text.trim(),

      if (_idealWeightController.text.trim().isNotEmpty)
        'ideal_weight': double.tryParse(_idealWeightController.text.trim()),

      if (_targetWeightController.text.trim().isNotEmpty)
        'target_weight': double.tryParse(_targetWeightController.text.trim()),

      if (_currentWeightController.text.trim().isNotEmpty)
        'current_weight': double.tryParse(_currentWeightController.text.trim()),

      if (_heightController.text.trim().isNotEmpty)
        'height': double.tryParse(_heightController.text.trim()),

      // بيانات الاشتراك
      'subscription_start': _startDate.toIso8601String(),
      'subscription_end': _endDate.toIso8601String(),
      'multi_device_enabled': _allowMultiDevice,
      'plan_type': _planTypeController.text.trim().isNotEmpty
          ? _planTypeController.text.trim()
          : 'monthly',
      'price': double.tryParse(_priceController.text.trim()) ?? 199.99,
      'max_devices': int.tryParse(_maxDevicesController.text.trim()) ?? 1,
    };

    if (widget.user == null) {
      if (_passwordController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'كلمة المرور مطلوبة';
          _isSaving = false;
        });
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'كلمة المرور وتأكيدها غير متطابقتين';
          _isSaving = false;
        });
        return;
      }

      userData['password'] = _passwordController.text;
      userData['password_confirmation'] = _confirmPasswordController.text;
    }

    try {
      await widget.onSave(userData);
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }
}
