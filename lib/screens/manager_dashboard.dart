import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vision_medical_system_app/services/db_helper.dart';

class ManagerDashboard extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;
  final Map user;

  const ManagerDashboard({
    super.key,
    required this.language,
    required this.token,
    required this.backendUrl,
    required this.user,
  });

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  List<dynamic> _areas = [];
  List<dynamic> _logs = [];

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'products': 'Products',
      'categories': 'Categories',
      'brands': 'Brands',
      'areas': 'Areas & Cities',
      'followup': 'Employee Follow-up',
      'add_product': 'Add Product',
      'add_category': 'Add Category',
      'add_brand': 'Add Brand',
      'add_area': 'Add Area',
      'name_ar': 'Name (Arabic)',
      'name_en': 'Name (English)',
      'desc_ar': 'Description (Arabic)',
      'desc_en': 'Description (English)',
      'price': 'Price',
      'stock': 'In Stock',
      'submit': 'Save',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'delete': 'Delete',
      'sku': 'SKU Code',
      'search': 'Search medical items...',
      'log_action': 'Action Logged',
      'log_user': 'User',
      'log_time': 'Date/Time',
    },
    'ar': {
      'products': 'المنتجات الطبية',
      'categories': 'الأقسام',
      'brands': 'الماركات التجارية',
      'areas': 'المناطق والمدن',
      'followup': 'متابعة الموظفين',
      'add_product': 'إضافة منتج طبي',
      'add_category': 'إضافة قسم جديد',
      'add_brand': 'إضافة ماركة جديدة',
      'add_area': 'إضافة منطقة/مدينة',
      'name_ar': 'الاسم (بالعربية)',
      'name_en': 'الاسم (بالإنجليزية)',
      'desc_ar': 'الوصف (بالعربية)',
      'desc_en': 'الوصف (بالإنجليزية)',
      'price': 'السعر (ج.م)',
      'stock': 'متوفر في المخزن',
      'submit': 'حفظ البيانات',
      'cancel': 'إلغاء',
      'edit': 'تعديل',
      'delete': 'حذف',
      'sku': 'رمز SKU الموحد',
      'search': 'البحث عن أجهزة ومستلزمات...',
      'log_action': 'الإجراء المتخذ',
      'log_user': 'الموظف المسؤول',
      'log_time': 'التاريخ والوقت',
    }
  };

  String t(String key) {
    return _localized[widget.language]?[key] ?? key;
  }

  final TextEditingController _searchQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadManagerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchQueryController.dispose();
    super.dispose();
  }

  Future<void> _loadManagerData() async {
    if (widget.token.isEmpty) {
      _loadMockData();
      return;
    }
    setState(() => _isLoading = true);
    bool showedOfflineToast = false;

    void showOfflineToast() {
      if (!showedOfflineToast && mounted) {
        showedOfflineToast = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.language == 'ar'
                  ? 'وضع عدم الاتصال: يتم عرض البيانات المخزنة مؤقتاً'
                  : 'Offline mode: displaying cached data',
            ),
            backgroundColor: Colors.amber[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Accept': 'application/json',
    };

    // 1. Get products
    try {
      final pRes = await http.get(Uri.parse('${widget.backendUrl}/products'), headers: headers).timeout(const Duration(seconds: 4));
      if (pRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('manager_products', pRes.body);
        final decoded = jsonDecode(pRes.body);
        _products = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('manager_products');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _products = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _products = [
          {'id': 1, 'name': {'ar': 'جهاز رنين مغناطيسي Optima', 'en': 'Optima MR450 MRI Scanner'}, 'price': 2500000.0, 'in_stock': true, 'sku': 'MRI-450', 'category_id': 1, 'brand_id': 1},
          {'id': 2, 'name': {'ar': 'جهاز سونار Vivid E90', 'en': 'Vivid E90 Ultrasound'}, 'price': 750000.0, 'in_stock': true, 'sku': 'ULS-E90', 'category_id': 2, 'brand_id': 1},
          {'id': 3, 'name': {'ar': 'جهاز تنفس صناعي Engström', 'en': 'Engström Carestation Ventilator'}, 'price': 320000.0, 'in_stock': false, 'sku': 'VEN-ENG', 'category_id': 3, 'brand_id': 2},
          {'id': 4, 'name': {'ar': 'جهاز رسم قلب محمول ECG', 'en': 'Defibtech Lifeline ECG'}, 'price': 45000.0, 'in_stock': true, 'sku': 'ECG-DFB', 'category_id': 4, 'brand_id': 3}
        ];
      }
    }

    // 2. Get categories
    try {
      final catRes = await http.get(Uri.parse('${widget.backendUrl}/categories'), headers: headers).timeout(const Duration(seconds: 4));
      if (catRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('manager_categories', catRes.body);
        final decoded = jsonDecode(catRes.body);
        _categories = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('manager_categories');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _categories = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _categories = [
          {'id': 1, 'name': {'ar': 'أجهزة الأشعة والرنين', 'en': 'Radiology & Imaging'}, 'products_count': 5},
          {'id': 2, 'name': {'ar': 'أجهزة الموجات فوق الصوتية', 'en': 'Ultrasound Systems'}, 'products_count': 3},
          {'id': 3, 'name': {'ar': 'أجهزة الرعاية الحرجة والعمليات', 'en': 'Critical Care & OR'}, 'products_count': 8},
          {'id': 4, 'name': {'ar': 'أجهزة الطوارئ والتشخيص', 'en': 'Emergency & Diagnostics'}, 'products_count': 12}
        ];
      }
    }

    // 3. Get brands
    try {
      final brandRes = await http.get(Uri.parse('${widget.backendUrl}/brands'), headers: headers).timeout(const Duration(seconds: 4));
      if (brandRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('manager_brands', brandRes.body);
        final decoded = jsonDecode(brandRes.body);
        _brands = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('manager_brands');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _brands = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _brands = [
          {'id': 1, 'name': {'ar': 'جنرال إلكتريك للرعاية الطبية', 'en': 'GE Healthcare'}, 'products_count': 12},
          {'id': 2, 'name': {'ar': 'فيليبس الطبية', 'en': 'Philips Healthcare'}, 'products_count': 8},
          {'id': 3, 'name': {'ar': 'سيمنز للمعدات الطبية', 'en': 'Siemens Healthineers'}, 'products_count': 10}
        ];
      }
    }

    // 4. Get areas
    try {
      final areaRes = await http.get(Uri.parse('${widget.backendUrl}/areas'), headers: headers).timeout(const Duration(seconds: 4));
      if (areaRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('manager_areas', areaRes.body);
        final decoded = jsonDecode(areaRes.body);
        _areas = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('manager_areas');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _areas = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _areas = [];
      }
    }

    // 5. Get activity logs
    try {
      final logsRes = await http.get(Uri.parse('${widget.backendUrl}/activity-logs'), headers: headers).timeout(const Duration(seconds: 4));
      if (logsRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('manager_logs', logsRes.body);
        final decoded = jsonDecode(logsRes.body);
        _logs = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('manager_logs');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _logs = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _logs = [];
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _products = [
      {'id': 1, 'name': {'ar': 'جهاز رنين مغناطيسي Optima', 'en': 'Optima MR450 MRI Scanner'}, 'price': 2500000.0, 'in_stock': true, 'sku': 'MRI-450', 'category_id': 1, 'brand_id': 1},
      {'id': 2, 'name': {'ar': 'جهاز سونار Vivid E90', 'en': 'Vivid E90 Ultrasound'}, 'price': 750000.0, 'in_stock': true, 'sku': 'ULS-E90', 'category_id': 2, 'brand_id': 1},
      {'id': 3, 'name': {'ar': 'جهاز تنفس صناعي Engström', 'en': 'Engström Carestation Ventilator'}, 'price': 320000.0, 'in_stock': false, 'sku': 'VEN-ENG', 'category_id': 3, 'brand_id': 2},
      {'id': 4, 'name': {'ar': 'جهاز رسم قلب محمول ECG', 'en': 'Defibtech Lifeline ECG'}, 'price': 45000.0, 'in_stock': true, 'sku': 'ECG-DFB', 'category_id': 4, 'brand_id': 3}
    ];

    _categories = [
      {'id': 1, 'name': {'ar': 'أجهزة الأشعة والرنين', 'en': 'Radiology & Imaging'}, 'products_count': 5},
      {'id': 2, 'name': {'ar': 'أجهزة الموجات فوق الصوتية', 'en': 'Ultrasound Systems'}, 'products_count': 3},
      {'id': 3, 'name': {'ar': 'أجهزة الرعاية الحرجة والعمليات', 'en': 'Critical Care & OR'}, 'products_count': 8},
      {'id': 4, 'name': {'ar': 'أجهزة الطوارئ والتشخيص', 'en': 'Emergency & Diagnostics'}, 'products_count': 12}
    ];

    _brands = [
      {'id': 1, 'name': {'ar': 'جنرال إلكتريك للرعاية الطبية', 'en': 'GE Healthcare'}, 'products_count': 12},
      {'id': 2, 'name': {'ar': 'فيليبس الطبية', 'en': 'Philips Healthcare'}, 'products_count': 8},
      {'id': 3, 'name': {'ar': 'سيمنز للمعدات الطبية', 'en': 'Siemens Healthineers'}, 'products_count': 10}
    ];

    _areas = [
      {'id': 1, 'name': {'ar': 'القاهرة الكبرى', 'en': 'Greater Cairo'}, 'slug': 'cairo'},
      {'id': 2, 'name': {'ar': 'الإسكندرية والساحل الشمالي', 'en': 'Alexandria'}, 'slug': 'alex'},
      {'id': 3, 'name': {'ar': 'منطقة الدلتا وقناة السويس', 'en': 'Delta & Suez Canal'}, 'slug': 'delta'}
    ];

    _logs = [
      {'id': 1, 'action': 'Logged in to system', 'user': 'Hassan Seller', 'created_at': '2026-07-14T11:20:00Z'},
      {'id': 2, 'action': 'Created new client quotation Q-1029', 'user': 'Sara Accountant', 'created_at': '2026-07-14T09:45:00Z'},
      {'id': 3, 'action': 'Modified product quantity in inventory', 'user': 'Ahmed Manager', 'created_at': '2026-07-13T15:30:00Z'},
      {'id': 4, 'action': 'Dispatched technician for MRI calibration', 'user': 'Super Admin', 'created_at': '2026-07-13T10:00:00Z'}
    ];
  }

  // Add & Edit Dialogs
  void _showProductDialog([Map? product]) {
    final isEdit = product != null;
    final nameArController = TextEditingController(text: isEdit ? (product['name']?['ar'] ?? '') : '');
    final nameEnController = TextEditingController(text: isEdit ? (product['name']?['en'] ?? '') : '');
    final priceController = TextEditingController(text: isEdit ? (product['price']?.toString() ?? '') : '');
    final skuController = TextEditingController(text: isEdit ? (product['sku'] ?? '') : '');
    bool inStock = isEdit ? (product['in_stock'] ?? true) : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? t('edit') : t('add_product')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameArController,
                      decoration: InputDecoration(labelText: t('name_ar')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameEnController,
                      decoration: InputDecoration(labelText: t('name_en')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t('price')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: skuController,
                      decoration: InputDecoration(labelText: t('sku')),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: Text(t('stock')),
                      value: inStock,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => inStock = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newProduct = {
                      'id': isEdit ? product['id'] : _products.length + 1,
                      'name': {'ar': nameArController.text, 'en': nameEnController.text},
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'sku': skuController.text,
                      'in_stock': inStock,
                    };
                    setState(() {
                      if (isEdit) {
                        final idx = _products.indexWhere((p) => p['id'] == product['id']);
                        if (idx != -1) _products[idx] = newProduct;
                      } else {
                        _products.add(newProduct);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(t('submit')),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryDialog([Map? category]) {
    final isEdit = category != null;
    final nameArController = TextEditingController(text: isEdit ? (category['name']?['ar'] ?? '') : '');
    final nameEnController = TextEditingController(text: isEdit ? (category['name']?['en'] ?? '') : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? t('edit') : t('add_category')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameArController,
                decoration: InputDecoration(labelText: t('name_ar')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameEnController,
                decoration: InputDecoration(labelText: t('name_en')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final newCat = {
                  'id': isEdit ? category['id'] : _categories.length + 1,
                  'name': {'ar': nameArController.text, 'en': nameEnController.text},
                  'products_count': isEdit ? category['products_count'] : 0,
                };
                setState(() {
                  if (isEdit) {
                    final idx = _categories.indexWhere((c) => c['id'] == category['id']);
                    if (idx != -1) _categories[idx] = newCat;
                  } else {
                    _categories.add(newCat);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(t('submit')),
            )
          ],
        );
      },
    );
  }

  void _showBrandDialog([Map? brand]) {
    final isEdit = brand != null;
    final nameArController = TextEditingController(text: isEdit ? (brand['name']?['ar'] ?? '') : '');
    final nameEnController = TextEditingController(text: isEdit ? (brand['name']?['en'] ?? '') : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? t('edit') : t('add_brand')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameArController,
                decoration: InputDecoration(labelText: t('name_ar')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameEnController,
                decoration: InputDecoration(labelText: t('name_en')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final newBrand = {
                  'id': isEdit ? brand['id'] : _brands.length + 1,
                  'name': {'ar': nameArController.text, 'en': nameEnController.text},
                  'products_count': isEdit ? brand['products_count'] : 0,
                };
                setState(() {
                  if (isEdit) {
                    final idx = _brands.indexWhere((b) => b['id'] == brand['id']);
                    if (idx != -1) _brands[idx] = newBrand;
                  } else {
                    _brands.add(newBrand);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(t('submit')),
            )
          ],
        );
      },
    );
  }

  void _showAreaDialog([Map? area]) {
    final isEdit = area != null;
    final nameArController = TextEditingController(text: isEdit ? (area['name']?['ar'] ?? '') : '');
    final nameEnController = TextEditingController(text: isEdit ? (area['name']?['en'] ?? '') : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? t('edit') : t('add_area')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameArController,
                decoration: InputDecoration(labelText: t('name_ar')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameEnController,
                decoration: InputDecoration(labelText: t('name_en')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final newArea = {
                  'id': isEdit ? area['id'] : _areas.length + 1,
                  'name': {'ar': nameArController.text, 'en': nameEnController.text},
                  'slug': nameEnController.text.toLowerCase().replaceAll(' ', '-'),
                };
                setState(() {
                  if (isEdit) {
                    final idx = _areas.indexWhere((a) => a['id'] == area['id']);
                    if (idx != -1) _areas[idx] = newArea;
                  } else {
                    _areas.add(newArea);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(t('submit')),
            )
          ],
        );
      },
    );
  }

  void _deleteItem(String type, int id) {
    setState(() {
      if (type == 'product') _products.removeWhere((p) => p['id'] == id);
      if (type == 'category') _categories.removeWhere((c) => c['id'] == id);
      if (type == 'brand') _brands.removeWhere((b) => b['id'] == id);
      if (type == 'area') _areas.removeWhere((a) => a['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = widget.language == 'ar';
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: Text(
            isRTL ? 'إدارة المستودع والمخزون' : 'Inventory & Warehouse Manager',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded, size: 18),
              ),
              onPressed: _loadManagerData,
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white.withValues(alpha: 0.1),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: [
                  Tab(text: t('products'), icon: const Icon(Icons.medical_services_rounded, size: 18)),
                  Tab(text: t('categories'), icon: const Icon(Icons.folder_copy_rounded, size: 18)),
                  Tab(text: t('brands'), icon: const Icon(Icons.verified_rounded, size: 18)),
                  Tab(text: t('areas'), icon: const Icon(Icons.map_rounded, size: 18)),
                  Tab(text: t('followup'), icon: const Icon(Icons.track_changes_rounded, size: 18)),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4338CA)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsTab(),
                  _buildCategoriesTab(),
                  _buildBrandsTab(),
                  _buildAreasTab(),
                  _buildFollowupTab(),
                ],
              ),
      ),
    );
  }

  // 1. Products View
  Widget _buildProductsTab() {
    final query = _searchQueryController.text.toLowerCase().trim();
    final filteredProducts = _products.where((p) {
      final nameAr = p['name']?['ar']?.toString().toLowerCase() ?? '';
      final nameEn = p['name']?['en']?.toString().toLowerCase() ?? '';
      final sku = p['sku']?.toString().toLowerCase() ?? '';
      return nameAr.contains(query) || nameEn.contains(query) || sku.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4338CA),
        foregroundColor: Colors.white,
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(t('add_product'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchQueryController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: t('search'),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4338CA)),
                suffixIcon: _searchQueryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchQueryController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          widget.language == 'ar'
                              ? 'لم يتم العثور على أجهزة طبية مطابقة'
                              : 'No matching medical equipment found',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      final name = widget.language == 'ar' 
                          ? (p['name']?['ar'] ?? p['name']?['en'] ?? '') 
                          : (p['name']?['en'] ?? p['name']?['ar'] ?? '');

                      final bool isInStock = p['in_stock'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF4338CA).withValues(alpha: 0.15),
                                      const Color(0xFF4338CA).withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.biotech_rounded, color: Color(0xFF4338CA), size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'SKU: ${p['sku'] ?? 'N/A'}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isInStock ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isInStock ? t('stock') : (widget.language == 'ar' ? 'غير متوفر' : 'Out of stock'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isInStock ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${p['price']?.toString() ?? '0'} EGP',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF4338CA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                onSelected: (val) {
                                  if (val == 'edit') _showProductDialog(p);
                                  if (val == 'delete') _deleteItem('product', p['id']);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(t('edit')),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(t('delete'), style: const TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 2. Categories View
  Widget _buildCategoriesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final c = _categories[index];
          final name = widget.language == 'ar' 
              ? (c['name']?['ar'] ?? c['name']?['en'] ?? '') 
              : (c['name']?['en'] ?? c['name']?['ar'] ?? '');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.folder_open, color: Colors.indigo[700]),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                widget.language == 'ar' 
                    ? 'يحتوي على ${c['products_count'] ?? 0} منتج طيبي' 
                    : 'Contains ${c['products_count'] ?? 0} medical equipment',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _showCategoryDialog(c);
                  if (val == 'delete') _deleteItem('category', c['id']);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(t('edit'))),
                  PopupMenuItem(value: 'delete', child: Text(t('delete'), style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. Brands View
  Widget _buildBrandsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        onPressed: () => _showBrandDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          final b = _brands[index];
          final name = widget.language == 'ar' 
              ? (b['name']?['ar'] ?? b['name']?['en'] ?? '') 
              : (b['name']?['en'] ?? b['name']?['ar'] ?? '');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.business, color: Colors.indigo[700]),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                widget.language == 'ar'
                    ? 'إجمالي الأجهزة: ${b['products_count'] ?? 0}'
                    : 'Total devices registered: ${b['products_count'] ?? 0}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _showBrandDialog(b);
                  if (val == 'delete') _deleteItem('brand', b['id']);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(t('edit'))),
                  PopupMenuItem(value: 'delete', child: Text(t('delete'), style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. Areas View
  Widget _buildAreasTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        onPressed: () => _showAreaDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _areas.length,
        itemBuilder: (context, index) {
          final a = _areas[index];
          final name = widget.language == 'ar' 
              ? (a['name']?['ar'] ?? a['name']?['en'] ?? '') 
              : (a['name']?['en'] ?? a['name']?['ar'] ?? '');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.location_on_outlined, color: Colors.indigo[700]),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Slug ID: ${a['slug'] ?? ''}'),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _showAreaDialog(a);
                  if (val == 'delete') _deleteItem('area', a['id']);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(t('edit'))),
                  PopupMenuItem(value: 'delete', child: Text(t('delete'), style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 5. Follow-up View
  Widget _buildFollowupTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final timeStr = log['created_at']?.split('T')[0] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${t('log_user')}: ${log['user']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${t('log_action')}: ${log['action']}',
                  style: const TextStyle(fontSize: 14),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
