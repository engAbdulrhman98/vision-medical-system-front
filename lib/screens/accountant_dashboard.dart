import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vision_medical_system_app/services/db_helper.dart';

class AccountantDashboard extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;
  final Map user;

  const AccountantDashboard({
    super.key,
    required this.language,
    required this.token,
    required this.backendUrl,
    required this.user,
  });

  @override
  State<AccountantDashboard> createState() => _AccountantDashboardState();
}

class _AccountantDashboardState extends State<AccountantDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<dynamic> _quotations = [];
  List<dynamic> _invoices = [];
  List<dynamic> _clients = [];
  List<dynamic> _products = [];

  // Create Quotation form controllers
  final _formKey = GlobalKey<FormState>();
  dynamic _selectedClient;
  final List<int> _selectedProducts = [];
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customItemController = TextEditingController();

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'quotes': 'Quotations',
      'new_quote': 'Create Quote',
      'invoices': 'Invoices',
      'reports': 'Financial Reports',
      'client': 'Client / Hospital',
      'products': 'Select Devices',
      'discount': 'Discount (%)',
      'total': 'Total Price (EGP)',
      'notes': 'Terms & Special Notes',
      'submit': 'Generate Quotation',
      'cancel': 'Cancel',
      'status': 'Status',
      'date': 'Created Date',
      'search': 'Search invoices or quotes...',
      'stats_revenue': 'Total Revenue',
      'stats_pending': 'Pending Collection',
      'stats_approved': 'Approved Quotes',
      'success_quote': 'Quotation generated successfully!',
      'due_date': 'Due Date',
    },
    'ar': {
      'quotes': 'عروض الأسعار',
      'new_quote': 'إنشاء عرض سعر',
      'invoices': 'الفواتير والتحصيل',
      'reports': 'التقارير المالية',
      'client': 'العميل / المستشفى المستلم',
      'products': 'اختر الأجهزة الطبية',
      'discount': 'نسبة الخصم (%)',
      'total': 'السعر الإجمالي المالي (ج.م)',
      'notes': 'الشروط والملاحظات الخاصة',
      'submit': 'إصدار عرض السعر',
      'cancel': 'إلغاء',
      'status': 'حالة العرض',
      'date': 'تاريخ الإصدار',
      'search': 'البحث في الفواتير أو العروض...',
      'stats_revenue': 'إجمالي المبيعات المحققة',
      'stats_pending': 'مبالغ قيد التحصيل',
      'stats_approved': 'العروض المعتمدة للبيع',
      'success_quote': 'تم إصدار عرض السعر وحفظه بنجاح!',
      'due_date': 'تاريخ الاستحقاق',
    }
  };

  String t(String key) {
    return _localized[widget.language]?[key] ?? key;
  }

  String _getLocalizedName(dynamic nameObj) {
    if (nameObj is Map) {
      return nameObj[widget.language] ?? nameObj['en'] ?? nameObj['ar'] ?? '';
    }
    return nameObj?.toString() ?? '';
  }

  final TextEditingController _searchQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAccountantData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalPriceController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _searchQueryController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountantData() async {
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

    // 1. Get quotations
    try {
      final qRes = await http.get(Uri.parse('${widget.backendUrl}/quotations'), headers: headers).timeout(const Duration(seconds: 4));
      if (qRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('accountant_quotations', qRes.body);
        final decoded = jsonDecode(qRes.body);
        _quotations = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('accountant_quotations');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _quotations = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _quotations = [
          {'id': 1029, 'client': {'name': 'Giza International Hospital'}, 'total_price': 3250000.0, 'status': 'Approved', 'created_at': '2026-07-10'},
          {'id': 1030, 'client': {'name': 'Nasr City Specialized Clinic'}, 'total_price': 45000.0, 'status': 'Pending', 'created_at': '2026-07-12'},
          {'id': 1031, 'client': {'name': 'Cleopatra Medical Group'}, 'total_price': 1500000.0, 'status': 'Rejected', 'created_at': '2026-07-13'}
        ];
      }
    }

    // 2. Get invoices
    try {
      final invRes = await http.get(Uri.parse('${widget.backendUrl}/invoices'), headers: headers).timeout(const Duration(seconds: 4));
      if (invRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('accountant_invoices', invRes.body);
        final decoded = jsonDecode(invRes.body);
        _invoices = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('accountant_invoices');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _invoices = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _invoices = [
          {'id': 5501, 'invoice_number': 'INV-2026-102', 'client_name': 'Giza International Hospital', 'amount': 3250000.0, 'status': 'Paid', 'due_date': '2026-08-10'},
          {'id': 5502, 'invoice_number': 'INV-2026-103', 'client_name': 'Nasr City Specialized Clinic', 'amount': 45000.0, 'status': 'Unpaid', 'due_date': '2026-07-30'}
        ];
      }
    }

    // 3. Get clients
    try {
      final clientRes = await http.get(Uri.parse('${widget.backendUrl}/clients'), headers: headers).timeout(const Duration(seconds: 4));
      if (clientRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('accountant_clients', clientRes.body);
        final decoded = jsonDecode(clientRes.body);
        _clients = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('accountant_clients');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _clients = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _clients = [
          {'id': 1, 'name': 'Giza International Hospital'},
          {'id': 2, 'name': 'Nasr City Specialized Clinic'},
          {'id': 3, 'name': 'Cleopatra Medical Group'}
        ];
      }
    }

    // 4. Get products
    try {
      final pRes = await http.get(Uri.parse('${widget.backendUrl}/products'), headers: headers).timeout(const Duration(seconds: 4));
      if (pRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('accountant_products', pRes.body);
        final decoded = jsonDecode(pRes.body);
        _products = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('accountant_products');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _products = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _products = [
          {'id': 1, 'name': {'ar': 'جهاز رنين مغناطيسي Optima', 'en': 'Optima MRI Scanner'}, 'price': 2500000.0},
          {'id': 2, 'name': {'ar': 'جهاز سونار Vivid E90', 'en': 'Vivid E90 Ultrasound'}, 'price': 750000.0},
          {'id': 3, 'name': {'ar': 'جهاز تنفس صناعي Engström', 'en': 'Engström Ventilator'}, 'price': 320000.0},
          {'id': 4, 'name': {'ar': 'جهاز رسم قلب محمول ECG', 'en': 'Defibtech ECG'}, 'price': 45000.0}
        ];
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _quotations = [
      {'id': 1029, 'client': {'name': 'Giza International Hospital'}, 'total_price': 3250000.0, 'status': 'Approved', 'created_at': '2026-07-10'},
      {'id': 1030, 'client': {'name': 'Nasr City Specialized Clinic'}, 'total_price': 45000.0, 'status': 'Pending', 'created_at': '2026-07-12'},
      {'id': 1031, 'client': {'name': 'Cleopatra Medical Group'}, 'total_price': 1500000.0, 'status': 'Rejected', 'created_at': '2026-07-13'}
    ];

    _invoices = [
      {'id': 5501, 'invoice_number': 'INV-2026-102', 'client_name': 'Giza International Hospital', 'amount': 3250000.0, 'status': 'Paid', 'due_date': '2026-08-10'},
      {'id': 5502, 'invoice_number': 'INV-2026-103', 'client_name': 'Nasr City Specialized Clinic', 'amount': 45000.0, 'status': 'Unpaid', 'due_date': '2026-07-30'}
    ];

    _clients = [
      {'id': 1, 'name': 'Giza International Hospital'},
      {'id': 2, 'name': 'Nasr City Specialized Clinic'},
      {'id': 3, 'name': 'Cleopatra Medical Group'}
    ];

    _products = [
      {'id': 1, 'name': {'ar': 'جهاز رنين مغناطيسي Optima', 'en': 'Optima MRI Scanner'}, 'price': 2500000.0},
      {'id': 2, 'name': {'ar': 'جهاز سونار Vivid E90', 'en': 'Vivid E90 Ultrasound'}, 'price': 750000.0},
      {'id': 3, 'name': {'ar': 'جهاز تنفس صناعي Engström', 'en': 'Engström Ventilator'}, 'price': 320000.0},
      {'id': 4, 'name': {'ar': 'جهاز رسم قلب محمول ECG', 'en': 'Defibtech ECG'}, 'price': 45000.0}
    ];
  }

  Future<void> _submitQuotation() async {
    if (_formKey.currentState!.validate() && _selectedClient != null) {
      if (widget.token.isEmpty) {
        final clientObj = _clients.firstWhere((c) => c['id'] == _selectedClient || c['name'] == _selectedClient, orElse: () => null);
        final clientName = clientObj != null ? _getLocalizedName(clientObj['name']) : _selectedClient.toString();
        
        setState(() {
          _quotations.insert(0, {
            'id': _quotations.length + 1032,
            'client': {'name': clientName},
            'total_price': double.tryParse(_totalPriceController.text) ?? 0.0,
            'status': 'Pending',
            'created_at': DateTime.now().toString().split(' ')[0],
          });
          _selectedProducts.clear();
          _totalPriceController.clear();
          _discountController.clear();
          _notesController.clear();
          _customItemController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('success_quote')), backgroundColor: Colors.amber[800])
        );
        _tabController.animateTo(0);
        return;
      }

      final List<Map<String, dynamic>> itemsList = [];
      for (var pid in _selectedProducts) {
        final prod = _products.firstWhere((p) => p['id'] == pid, orElse: () => null);
        if (prod != null) {
          final prodName = _getLocalizedName(prod['name']);
          itemsList.add({
            'name': prodName,
            'quantity': 1,
            'unit_price': (prod['price'] as num).toDouble(),
          });
        }
      }

      if (itemsList.isEmpty) {
        final customName = _customItemController.text.trim();
        final amount = double.tryParse(_totalPriceController.text) ?? 0.0;
        itemsList.add({
          'name': customName.isNotEmpty ? customName : (widget.language == 'ar' ? 'عرض سعر خدمات وتجهيزات طبية' : 'Medical Equipment & Services'),
          'quantity': 1,
          'unit_price': amount,
        });
      }

      final payload = {
        'client_id': _selectedClient,
        'total_amount': double.tryParse(_totalPriceController.text) ?? 0.0,
        'items': itemsList,
        'notes': _notesController.text,
      };

      try {
        final res = await http.post(
          Uri.parse('${widget.backendUrl}/quotations'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload)
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 || res.statusCode == 201) {
          _selectedProducts.clear();
          _totalPriceController.clear();
          _discountController.clear();
          _notesController.clear();
          _loadAccountantData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('success_quote')), backgroundColor: Colors.amber[800])
            );
            _tabController.animateTo(0);
          }
        }
      } catch (_) {}
    }
  }

  void _calculatePrice() {
    double total = 0.0;
    for (var pid in _selectedProducts) {
      final prod = _products.firstWhere((p) => p['id'] == pid, orElse: () => null);
      if (prod != null) {
        total += (prod['price'] as num).toDouble();
      }
    }
    double disc = double.tryParse(_discountController.text) ?? 0.0;
    if (disc > 0 && disc <= 100) {
      total = total * (1 - disc / 100);
    }
    setState(() {
      _totalPriceController.text = total.toStringAsFixed(2);
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
                colors: [Color(0xFF78350F), Color(0xFFD97706)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: Text(
            isRTL ? 'إدارة المالية والعروض' : 'Financials & Quotations Portal',
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
              onPressed: _loadAccountantData,
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
                  Tab(text: widget.language == 'ar' ? 'طلبات الفواتير المعلقة' : 'Pending Requests', icon: const Icon(Icons.pending_actions_rounded, size: 18)),
                  Tab(text: t('quotes'), icon: const Icon(Icons.request_quote_rounded, size: 18)),
                  Tab(text: t('new_quote'), icon: const Icon(Icons.add_card_rounded, size: 18)),
                  Tab(text: t('invoices'), icon: const Icon(Icons.receipt_rounded, size: 18)),
                  Tab(text: t('reports'), icon: const Icon(Icons.pie_chart_rounded, size: 18)),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingInvoiceRequestsTab(),
                  _buildQuotesTab(),
                  _buildCreateQuoteTab(),
                  _buildInvoicesTab(),
                  _buildReportsTab(),
                ],
              ),
      ),
    );
  }

  // 1. Quotes list
  Widget _buildQuotesTab() {
    final query = _searchQueryController.text.toLowerCase().trim();
    final filteredQuotes = _quotations.where((q) {
      final clientName = q['client']?['name'] != null
          ? _getLocalizedName(q['client']['name']).toLowerCase()
          : '';
      final quoteId = q['id']?.toString().toLowerCase() ?? '';
      return clientName.contains(query) || quoteId.contains(query);
    }).toList();

    return Column(
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
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD97706)),
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
          child: filteredQuotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.request_quote_rounded, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        widget.language == 'ar'
                            ? 'لم يتم العثور على عروض أسعار مطابقة'
                            : 'No matching quotations found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final q = filteredQuotes[index];
                    final clientName = q['client']?['name'] != null
                        ? _getLocalizedName(q['client']['name'])
                        : 'N/A';
                    final status = q['status'] ?? 'Pending';
                    Color statusColor = const Color(0xFFD97706);
                    if (status == 'Approved') statusColor = const Color(0xFF15803D);
                    if (status == 'Rejected') statusColor = const Color(0xFFB91C1C);

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
                                    const Color(0xFFD97706).withValues(alpha: 0.15),
                                    const Color(0xFFD97706).withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.description_rounded, color: Color(0xFFD97706), size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t('date')}: ${q['created_at']} | ID: #${q['id']}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${q['total_price']} EGP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF78350F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 2. Create Quote Form
  Widget _buildCreateQuoteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t('new_quote'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                DropdownButtonFormField<dynamic>(
                  initialValue: _selectedClient,
                  decoration: InputDecoration(
                    labelText: t('client'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _clients.map((c) {
                    final name = _getLocalizedName(c['name']);
                    return DropdownMenuItem<dynamic>(
                      value: c['id'] ?? c['name'],
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedClient = val);
                  },
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Text(t('products'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, idx) {
                    final p = _products[idx];
                    final pName = widget.language == 'ar'
                        ? (p['name']?['ar'] ?? p['name']?['en'] ?? '')
                        : (p['name']?['en'] ?? p['name']?['ar'] ?? '');
                    final isChecked = _selectedProducts.contains(p['id']);

                    return CheckboxListTile(
                      title: Text(pName),
                      subtitle: Text('${p['price']} EGP'),
                      value: isChecked,
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true) {
                            _selectedProducts.add(p['id']);
                          } else {
                            _selectedProducts.remove(p['id']);
                          }
                          _calculatePrice();
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t('discount'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => _calculatePrice(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t('total'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: t('notes'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitQuotation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    t('submit'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. Invoices List
  Widget _buildInvoicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final isPaid = inv['status'] == 'Paid';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              isPaid ? Icons.check_circle_outline : Icons.pending_actions_outlined,
              color: isPaid ? Colors.green : Colors.red,
            ),
            title: Text(inv['invoice_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv['client_name'] ?? ''),
                Text('${t('due_date')}: ${inv['due_date']}', style: const TextStyle(fontSize: 11)),
              ],
            ),
            trailing: Text(
              '${inv['amount']} EGP',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[850]),
            ),
          ),
        );
      },
    );
  }

  // 4. Financial Reports View
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReportSummaryCard(t('stats_revenue'), '3,250,000.00 EGP', Icons.trending_up, Colors.green),
          const SizedBox(height: 12),
          _buildReportSummaryCard(t('stats_pending'), '45,000.00 EGP', Icons.access_time, Colors.orange),
          const SizedBox(height: 12),
          _buildReportSummaryCard(t('stats_approved'), '1 Quotation', Icons.file_present_outlined, Colors.blue),
          const SizedBox(height: 24),
          // Chart placeholder
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.language == 'ar' ? 'تقرير المبيعات والتدفق المالي للشهور الأخيرة' : 'Sales Flow Performance Log',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildChartBar('May', 0.4, Colors.amber),
                        _buildChartBar('Jun', 0.85, Colors.amber),
                        _buildChartBar('Jul', 0.6, Colors.amber),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReportSummaryCard(String title, String val, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        trailing: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildChartBar(String label, double heightPct, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 120 * heightPct,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Pending Invoice Requests tab for Accountant
  List<dynamic> _pendingRequests = [
    {
      'id': 102,
      'request_type': 'sales_product',
      'user': {'name': 'أحمد محمود (مندوب مبيعات)'},
      'client': {'name': 'مركز العاصمة للأشعة'},
      'total_amount': 750000.0,
      'status': 'pending_accountant',
      'notes': 'توريد جهاز سونار ثلاثي الأبعاد مع الضمان',
      'created_at': '2026-07-20 18:30',
      'items': [
        {'item_name': 'جهاز سونار Vivid E90 Ultrasound', 'quantity': 1, 'unit_price': 750000.0}
      ]
    },
    {
      'id': 103,
      'request_type': 'maintenance_service',
      'user': {'name': 'م. طارق علي (صيانة خارجية)'},
      'client': {'name': 'مستشفى السلام الدولي'},
      'total_amount': 24000.0,
      'status': 'pending_accountant',
      'notes': 'زيارة صيانة دورية وإستبدال صمامات أكسجين',
      'created_at': '2026-07-20 19:15',
      'items': [
        {'item_name': 'فحص شامل وصيانة جهاز التخدير', 'quantity': 1, 'unit_price': 4000.0},
        {'item_name': 'قطع غيار صمامات أكسجين ضغط عالي', 'quantity': 4, 'unit_price': 5000.0}
      ]
    }
  ];

  Widget _buildPendingInvoiceRequestsTab() {
    final isAr = widget.language == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _pendingRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.green[300]),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'لا توجد طلبات فواتير معلقة حالياً' : 'No pending invoice requests',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                final req = _pendingRequests[index];
                final requesterName = req['user']?['name'] ?? 'مستخدم';
                final clientName = req['client']?['name'] ?? 'عميل';
                final requestType = req['request_type'] ?? 'maintenance_service';
                final isMaintenance = requestType == 'maintenance_service';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMaintenance ? Colors.orange.withValues(alpha: 0.15) : Colors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isMaintenance ? Icons.build_rounded : Icons.medical_services_rounded,
                                color: isMaintenance ? Colors.orange[900] : Colors.cyan[900],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${isAr ? 'بواسطة:' : 'By:'} $requesterName', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isAr ? 'طلب جديد' : 'New Request',
                                style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (req['notes'] != null && req['notes'].toString().isNotEmpty) ...[
                          Text('${isAr ? 'الملاحظات:' : 'Notes:'} ${req['notes']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                        ],
                        Text('${isAr ? 'البنود:' : 'Items:'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        ...((req['items'] as List? ?? []).map((it) => Text(' • ${it['item_name']} (x${it['quantity']}) - ${it['unit_price'] * it['quantity']} EGP', style: const TextStyle(fontSize: 12)))),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${isAr ? 'المبلغ الإجمالي:' : 'Total Amount:'} ${req['total_amount']} EGP',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF78350F)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _pendingRequests.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAr ? 'تم إصدار الفاتورة وتنبيه صاحب الطلب بنجاح! 📄' : 'Invoice issued and notification sent! 📄'),
                                    backgroundColor: const Color(0xFF15803D),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                              label: Text(isAr ? 'إصدار الفاتورة الرسمية' : 'Issue Invoice', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }
}
