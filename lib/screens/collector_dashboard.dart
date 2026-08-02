import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vision_medical_system_app/services/db_helper.dart';

class CollectorDashboard extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;
  final Map user;

  const CollectorDashboard({
    super.key,
    required this.language,
    required this.token,
    required this.backendUrl,
    required this.user,
  });

  @override
  State<CollectorDashboard> createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<dynamic> _invoices = [];
  List<dynamic> _clients = [];
  List<dynamic> _invoiceRequests = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  // Colors
  static const Color _primary = Color(0xFF92400E);
  static const Color _secondary = Color(0xFFB45309);
  static const Color _accent = Color(0xFFF59E0B);

  final Map<String, Map<String, String>> _loc = {
    'en': {
      'title': 'Collection Dashboard',
      'invoices': 'Invoices',
      'clients': 'Clients',
      'requests': 'Invoice Requests',
      'overview': 'Overview',
      'total_collected': 'Total Collected',
      'pending': 'Pending',
      'overdue': 'Overdue',
      'total_invoices': 'Total Invoices',
      'search': 'Search by client or invoice no...',
      'all': 'All',
      'paid': 'Paid',
      'unpaid': 'Unpaid',
      'partial': 'Partial',
      'confirm_payment': 'Confirm Payment',
      'payment_confirmed': 'Payment confirmed successfully!',
      'invoice_no': 'Invoice #',
      'amount': 'Amount',
      'due_date': 'Due Date',
      'status': 'Status',
      'client': 'Client',
      'phone': 'Phone',
      'area': 'Area',
      'no_invoices': 'No invoices found',
      'no_clients': 'No clients found',
      'no_requests': 'No requests found',
      'filter': 'Filter',
      'today_collections': "Today's Collections",
      'this_month': 'This Month',
      'collection_rate': 'Collection Rate',
      'mark_collected': 'Mark as Collected',
      'mark_partial': 'Mark Partial',
      'notes': 'Collection Notes',
      'collected_amount': 'Collected Amount (EGP)',
      'submit': 'Submit',
      'cancel': 'Cancel',
      'egp': 'EGP',
      'view_details': 'View Details',
      'follow_up': 'Follow Up',
      'address': 'Address',
      'contact_person': 'Contact Person',
      'loading': 'Loading data...',
      'refresh': 'Refresh',
    },
    'ar': {
      'title': 'لوحة التحصيل',
      'invoices': 'الفواتير',
      'clients': 'العملاء',
      'requests': 'طلبات الفواتير',
      'overview': 'نظرة عامة',
      'total_collected': 'إجمالي المحصّل',
      'pending': 'قيد التحصيل',
      'overdue': 'متأخر السداد',
      'total_invoices': 'إجمالي الفواتير',
      'search': 'ابحث بالعميل أو رقم الفاتورة...',
      'all': 'الكل',
      'paid': 'مدفوعة',
      'unpaid': 'غير مدفوعة',
      'partial': 'مدفوعة جزئياً',
      'confirm_payment': 'تأكيد الدفع',
      'payment_confirmed': 'تم تسجيل الدفع بنجاح!',
      'invoice_no': 'فاتورة رقم',
      'amount': 'المبلغ',
      'due_date': 'تاريخ الاستحقاق',
      'status': 'الحالة',
      'client': 'العميل',
      'phone': 'الهاتف',
      'area': 'المنطقة',
      'no_invoices': 'لا توجد فواتير',
      'no_clients': 'لا يوجد عملاء',
      'no_requests': 'لا توجد طلبات',
      'filter': 'تصفية',
      'today_collections': 'تحصيلات اليوم',
      'this_month': 'هذا الشهر',
      'collection_rate': 'نسبة التحصيل',
      'mark_collected': 'تسجيل تحصيل',
      'mark_partial': 'دفعة جزئية',
      'notes': 'ملاحظات التحصيل',
      'collected_amount': 'المبلغ المحصّل (ج.م)',
      'submit': 'حفظ',
      'cancel': 'إلغاء',
      'egp': 'ج.م',
      'view_details': 'عرض التفاصيل',
      'follow_up': 'متابعة',
      'address': 'العنوان',
      'contact_person': 'الشخص المسؤول',
      'loading': 'جاري تحميل البيانات...',
      'refresh': 'تحديث',
    },
  };

  String t(String key) => _loc[widget.language]?[key] ?? key;
  bool get isAr => widget.language == 'ar';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.token.isEmpty) {
      _loadMockData();
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Accept': 'application/json',
    };

    // Invoices
    try {
      final res = await http
          .get(Uri.parse('${widget.backendUrl}/invoices'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('collector_invoices', res.body);
        final d = jsonDecode(res.body);
        if (mounted) setState(() => _invoices = d is List ? d : (d['data'] as List? ?? []));
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('collector_invoices');
      if (cached != null) {
        final d = jsonDecode(cached);
        if (mounted) setState(() => _invoices = d is List ? d : (d['data'] as List? ?? []));
      } else {
        _loadMockData();
      }
    }

    // Clients
    try {
      final res = await http
          .get(Uri.parse('${widget.backendUrl}/clients'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('collector_clients', res.body);
        final d = jsonDecode(res.body);
        if (mounted) setState(() => _clients = d is List ? d : (d['data'] as List? ?? []));
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('collector_clients');
      if (cached != null) {
        final d = jsonDecode(cached);
        if (mounted) setState(() => _clients = d is List ? d : (d['data'] as List? ?? []));
      }
    }

    // Invoice Requests
    try {
      final res = await http
          .get(Uri.parse('${widget.backendUrl}/invoice-requests'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('collector_requests', res.body);
        final d = jsonDecode(res.body);
        if (mounted) setState(() => _invoiceRequests = d is List ? d : (d['data'] as List? ?? []));
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('collector_requests');
      if (cached != null) {
        final d = jsonDecode(cached);
        if (mounted) setState(() => _invoiceRequests = d is List ? d : (d['data'] as List? ?? []));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _invoices = [
      {
        'id': 5501,
        'invoice_number': 'INV-2026-101',
        'client_name': 'مستشفى الجيزة الدولي',
        'amount': 3250000.0,
        'paid_amount': 3250000.0,
        'status': 'Paid',
        'due_date': '2026-07-15',
        'created_at': '2026-06-10',
      },
      {
        'id': 5502,
        'invoice_number': 'INV-2026-102',
        'client_name': 'عيادة نصر سيتي المتخصصة',
        'amount': 450000.0,
        'paid_amount': 0.0,
        'status': 'Unpaid',
        'due_date': '2026-07-30',
        'created_at': '2026-06-20',
      },
      {
        'id': 5503,
        'invoice_number': 'INV-2026-103',
        'client_name': 'مجموعة كليوباترا الطبية',
        'amount': 1500000.0,
        'paid_amount': 500000.0,
        'status': 'Partial',
        'due_date': '2026-08-05',
        'created_at': '2026-07-01',
      },
      {
        'id': 5504,
        'invoice_number': 'INV-2026-104',
        'client_name': 'مركز ابن سينا الطبي',
        'amount': 280000.0,
        'paid_amount': 0.0,
        'status': 'Unpaid',
        'due_date': '2026-07-01',
        'created_at': '2026-06-01',
      },
      {
        'id': 5505,
        'invoice_number': 'INV-2026-105',
        'client_name': 'مستشفى السلام الدولي',
        'amount': 870000.0,
        'paid_amount': 870000.0,
        'status': 'Paid',
        'due_date': '2026-07-20',
        'created_at': '2026-06-15',
      },
    ];

    _clients = [
      {'id': 1, 'name': 'مستشفى الجيزة الدولي', 'phone': '01000000001', 'area': 'الجيزة', 'contact_person': 'أ. كريم مصطفى'},
      {'id': 2, 'name': 'عيادة نصر سيتي المتخصصة', 'phone': '01100000002', 'area': 'القاهرة', 'contact_person': 'د. سامية علي'},
      {'id': 3, 'name': 'مجموعة كليوباترا الطبية', 'phone': '01200000003', 'area': 'الإسكندرية', 'contact_person': 'م. طارق عبد الله'},
      {'id': 4, 'name': 'مركز ابن سينا الطبي', 'phone': '01000000004', 'area': 'المنصورة', 'contact_person': 'أ. هدى محمود'},
      {'id': 5, 'name': 'مستشفى السلام الدولي', 'phone': '01500000005', 'area': 'القاهرة', 'contact_person': 'م. يوسف رمضان'},
    ];
  }

  // ─── Stats helpers ──────────────────────────────────────────────────────────
  double get _totalCollected => _invoices.fold(0.0, (sum, inv) {
        final paid = (inv['paid_amount'] ?? (inv['status'] == 'Paid' ? (inv['amount'] ?? 0) : 0));
        return sum + (paid is num ? paid.toDouble() : 0.0);
      });

  double get _totalPending => _invoices.where((inv) {
        final s = (inv['status'] ?? '').toString().toLowerCase();
        return s == 'unpaid' || s == 'partial';
      }).fold(0.0, (sum, inv) {
        final amount = inv['amount'] ?? 0;
        final paid = inv['paid_amount'] ?? 0;
        return sum + ((amount is num ? amount.toDouble() : 0) - (paid is num ? paid.toDouble() : 0));
      });

  int get _overdueCount {
    final today = DateTime.now();
    return _invoices.where((inv) {
      final s = (inv['status'] ?? '').toString().toLowerCase();
      if (s == 'paid') return false;
      final dueDateStr = inv['due_date']?.toString();
      if (dueDateStr == null) return false;
      try {
        final due = DateTime.parse(dueDateStr);
        return due.isBefore(today);
      } catch (_) {
        return false;
      }
    }).length;
  }

  double get _collectionRate {
    if (_invoices.isEmpty) return 0.0;
    final paid = _invoices.where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'paid').length;
    return (paid / _invoices.length) * 100;
  }

  List<dynamic> get _filteredInvoices {
    return _invoices.where((inv) {
      final name = (inv['client_name'] ?? inv['client']?['name'] ?? '').toString().toLowerCase();
      final num = (inv['invoice_number'] ?? inv['id']?.toString() ?? '').toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || num.contains(_searchQuery);
      final status = (inv['status'] ?? '').toString().toLowerCase();
      final matchesFilter = _filterStatus == 'all' ||
          (_filterStatus == 'paid' && status == 'paid') ||
          (_filterStatus == 'unpaid' && status == 'unpaid') ||
          (_filterStatus == 'partial' && status == 'partial');
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ─── UI helpers ─────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return const Color(0xFF16A34A);
      case 'unpaid': return const Color(0xFFDC2626);
      case 'partial': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return t('paid');
      case 'unpaid': return t('unpaid');
      case 'partial': return t('partial');
      default: return status;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}م ${t('egp')}';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}ك ${t('egp')}';
    }
    return '${amount.toStringAsFixed(0)} ${t('egp')}';
  }

  bool _isOverdue(dynamic inv) {
    final s = (inv['status'] ?? '').toString().toLowerCase();
    if (s == 'paid') return false;
    final dueDateStr = inv['due_date']?.toString();
    if (dueDateStr == null) return false;
    try {
      return DateTime.parse(dueDateStr).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  // ─── Confirm Payment Dialog ──────────────────────────────────────────────────
  void _showConfirmPaymentDialog(dynamic invoice) {
    final amountController = TextEditingController(
      text: (invoice['amount'] ?? 0).toString(),
    );
    final notesController = TextEditingController();
    String paymentType = 'full';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t('confirm_payment'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primary),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: _secondary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${t('invoice_no')} ${invoice['invoice_number'] ?? invoice['id']}\n'
                              '${invoice['client_name'] ?? invoice['client']?['name'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(isAr ? 'نوع الدفع' : 'Payment Type',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setS(() => paymentType = 'full'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: paymentType == 'full' ? _primary : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  t('mark_collected'),
                                  style: TextStyle(
                                    color: paymentType == 'full' ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setS(() => paymentType = 'partial'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: paymentType == 'partial' ? _accent : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  t('mark_partial'),
                                  style: TextStyle(
                                    color: paymentType == 'partial' ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (paymentType == 'partial') ...[
                      Text(t('collected_amount'),
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          prefixIcon: const Icon(Icons.currency_exchange, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(t('notes'),
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: isAr ? 'أضف ملاحظات التحصيل...' : 'Add collection notes...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t('cancel'), style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _submitPayment(invoice, paymentType, amountController.text, notesController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paymentType == 'full' ? _primary : _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(t('submit'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _submitPayment(dynamic invoice, String type, String amount, String notes) async {
    // Optimistic UI update
    setState(() {
      final idx = _invoices.indexWhere((inv) => inv['id'] == invoice['id']);
      if (idx != -1) {
        _invoices[idx] = {
          ..._invoices[idx],
          'status': type == 'full' ? 'Paid' : 'Partial',
          'paid_amount': type == 'full' ? invoice['amount'] : double.tryParse(amount) ?? 0,
        };
      }
    });

    if (widget.token.isEmpty) {
      _showSuccessSnack(t('payment_confirmed'));
      return;
    }

    try {
      await http.patch(
        Uri.parse('${widget.backendUrl}/invoices/${invoice['id']}/payment'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': type == 'full' ? 'Paid' : 'Partial',
          'paid_amount': type == 'full' ? invoice['amount'] : double.tryParse(amount),
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 5));
      _showSuccessSnack(t('payment_confirmed'));
    } catch (_) {
      _showSuccessSnack(t('payment_confirmed')); // offline — already updated UI
    }
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: _accent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: [
              Tab(icon: const Icon(Icons.dashboard_outlined, size: 18), text: t('overview')),
              Tab(icon: const Icon(Icons.receipt_long_outlined, size: 18), text: t('invoices')),
              Tab(icon: const Icon(Icons.people_outline, size: 18), text: t('clients')),
              Tab(icon: const Icon(Icons.inbox_outlined, size: 18), text: t('requests')),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: _primary),
                      const SizedBox(height: 16),
                      Text(t('loading'), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildInvoicesTab(),
                    _buildClientsTab(),
                    _buildRequestsTab(),
                  ],
                ),
        ),
      ],
    );
  }

  // ─── Tab 0: Overview ─────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? '💰 لوحة التحصيل الميداني' : '💰 Field Collection',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr
                              ? 'إجمالي ${_invoices.length} فاتورة | $_overdueCount متأخرة'
                              : '${_invoices.length} Invoices total | $_overdueCount Overdue',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: t('refresh'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats cards — 2x2 grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              children: [
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: t('total_collected'),
                  value: _formatCurrency(_totalCollected),
                  color: const Color(0xFF16A34A),
                  bg: const Color(0xFFDCFCE7),
                ),
                _buildStatCard(
                  icon: Icons.pending_outlined,
                  label: t('pending'),
                  value: _formatCurrency(_totalPending),
                  color: const Color(0xFFD97706),
                  bg: const Color(0xFFFEF3C7),
                ),
                _buildStatCard(
                  icon: Icons.warning_amber_outlined,
                  label: t('overdue'),
                  value: '$_overdueCount ${isAr ? 'فاتورة' : 'Invoices'}',
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEE2E2),
                ),
                _buildStatCard(
                  icon: Icons.pie_chart_outline,
                  label: t('collection_rate'),
                  value: '${_collectionRate.toStringAsFixed(0)}%',
                  color: _primary,
                  bg: const Color(0xFFFEF3C7),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent invoices needing attention
            if (_overdueCount > 0) ...[
              _sectionTitle(isAr ? '⚠️ فواتير متأخرة تحتاج متابعة' : '⚠️ Overdue Invoices'),
              const SizedBox(height: 10),
              ..._invoices.where(_isOverdue).take(3).map((inv) => _buildInvoiceCard(inv, highlight: true)),
              const SizedBox(height: 16),
            ],

            // Recent paid
            _sectionTitle(isAr ? '✅ آخر المحصّلات' : '✅ Recent Collections'),
            const SizedBox(height: 10),
            ..._invoices
                .where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'paid')
                .take(3)
                .map((inv) => _buildInvoiceCard(inv)),

            if (_invoices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(t('no_invoices'), style: TextStyle(color: Colors.grey[400])),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.blueGrey[800],
        letterSpacing: 0.3,
      ),
    );
  }

  // ─── Tab 1: Invoices ─────────────────────────────────────────────────────────
  Widget _buildInvoicesTab() {
    final filtered = _filteredInvoices;
    return Column(
      children: [
        // Search & Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: t('search'),
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: _secondary),
                  filled: true,
                  fillColor: const Color(0xFFFEF9F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5D5B0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5D5B0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', t('all'), Icons.list_alt),
                    const SizedBox(width: 8),
                    _filterChip('paid', t('paid'), Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    _filterChip('unpaid', t('unpaid'), Icons.cancel_outlined),
                    const SizedBox(width: 8),
                    _filterChip('partial', t('partial'), Icons.timelapse_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        // Results count
        Container(
          color: const Color(0xFFFEF9F0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text(
                isAr ? '${filtered.length} نتيجة' : '${filtered.length} results',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: _primary,
            onRefresh: _loadData,
            child: filtered.isEmpty
                ? Center(
                    child: Text(t('no_invoices'),
                        style: TextStyle(color: Colors.grey[400], fontSize: 15)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildInvoiceCard(filtered[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final selected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _primary : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : Colors.grey[700],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(dynamic inv, {bool highlight = false}) {
    final status = (inv['status'] ?? '').toString();
    final clientName = inv['client_name'] ?? inv['client']?['name'] ?? '';
    final invNo = inv['invoice_number'] ?? 'INV-${inv['id']}';
    final amount = (inv['amount'] ?? 0).toDouble();
    final paidAmount = (inv['paid_amount'] ?? (status.toLowerCase() == 'paid' ? amount : 0.0)).toDouble();
    final dueDate = inv['due_date']?.toString() ?? '';
    final overdue = _isOverdue(inv);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight || overdue
            ? Border.all(color: const Color(0xFFDC2626), width: 1.5)
            : Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Invoice icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long, color: _statusColor(status), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(invNo,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount progress bar for partial
            if (status.toLowerCase() == 'partial') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'المحصّل: ${_formatCurrency(paidAmount)}' : 'Collected: ${_formatCurrency(paidAmount)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                  Text(isAr ? 'المتبقي: ${_formatCurrency(amount - paidAmount)}' : 'Remaining: ${_formatCurrency(amount - paidAmount)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: amount > 0 ? paidAmount / amount : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Icon(Icons.monetization_on_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(_formatCurrency(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary)),
                const Spacer(),
                if (dueDate.isNotEmpty) ...[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: overdue ? const Color(0xFFDC2626) : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dueDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: overdue ? const Color(0xFFDC2626) : Colors.grey[500],
                      fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
            if (overdue) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAr ? '⚠️ متأخر عن تاريخ الاستحقاق' : '⚠️ Overdue payment',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                ),
              ),
            ],
            // Action buttons
            if (status.toLowerCase() != 'paid') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showConfirmPaymentDialog(inv),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.payments_outlined, size: 15),
                      label: Text(t('confirm_payment'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Tab 2: Clients ──────────────────────────────────────────────────────────
  Widget _buildClientsTab() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadData,
      child: _clients.isEmpty
          ? Center(child: Text(t('no_clients'), style: TextStyle(color: Colors.grey[400])))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _clients.length,
              itemBuilder: (_, i) {
                final c = _clients[i];
                final name = c['name']?.toString() ?? '';
                final phone = c['phone']?.toString() ?? '';
                final area = c['area']?.toString() ?? '';
                final contact = c['contact_person']?.toString() ?? '';
                // Count invoices for this client
                final clientInvoices = _invoices.where((inv) {
                  final cn = (inv['client_name'] ?? inv['client']?['name'] ?? '').toString();
                  return cn == name;
                }).toList();
                final unpaidCount = clientInvoices.where((inv) => (inv['status'] ?? '').toString().toLowerCase() != 'paid').length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_primary, _secondary]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (area.isNotEmpty)
                                Text(area, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              if (contact.isNotEmpty)
                                Text(contact, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              if (phone.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.phone_outlined, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 3),
                                    Text(phone, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            if (unpaidCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unpaidCount ${isAr ? 'غير مدفوعة' : 'unpaid'}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (unpaidCount == 0 && clientInvoices.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isAr ? '✅ مكتمل' : '✅ Clear',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
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

  // ─── Tab 3: Invoice Requests ─────────────────────────────────────────────────
  Widget _buildRequestsTab() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadData,
      child: _invoiceRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(t('no_requests'), style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _invoiceRequests.length,
              itemBuilder: (_, i) {
                final r = _invoiceRequests[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.request_page_outlined, color: _secondary, size: 22),
                    ),
                    title: Text(
                      r['title'] ?? r['client_name'] ?? 'Request #${r['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      r['status'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    trailing: Text(
                      r['created_at']?.toString().substring(0, 10) ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
