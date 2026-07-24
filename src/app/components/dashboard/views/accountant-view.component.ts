import { Component, inject, signal, model } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../../services/language.service';
import { ApiService } from '../../../services/api.service';

import { TasksComponent } from '../tasks/tasks.component';

@Component({
  selector: 'app-accountant-view',
  standalone: true,
  imports: [CommonModule, FormsModule, TasksComponent],
  templateUrl: './accountant-view.component.html'
})
export class AccountantViewComponent {
  public langService = inject(LanguageService);
  public apiService = inject(ApiService);

  // Sub-tabs: 'quotations', 'new', 'invoices', 'new_invoice', 'reports'
  public activeSubTab = model<string>('quotations');

  // Shared State
  public quotations = signal<any[]>([]);
  public invoices = signal<any[]>([]);
  public clients = signal<any[]>([]);
  public showSuccessMsg = signal<string>('');

  // Search & Filter State
  public searchText = '';
  public selectedStatus = '';

  public invoiceSearchText = '';
  public invoiceSelectedStatus = '';

  // New Quotation State
  public newQuotation = {
    client_id: 0,
    quotation_number: '',
    status: 'pending',
    total_amount: 0,
    items: [] as any[],
    valid_until: '',
    notes: ''
  };
  public newItem = { name: '', quantity: 1, unit_price: 0 };

  // New Invoice State
  public newInvoice = {
    client_id: 0,
    quotation_id: null as number | null,
    invoice_number: '',
    amount: 0,
    status: 'unpaid',
    due_date: '',
    notes: ''
  };

  constructor() {
    this.loadQuotations();
    this.loadInvoices();
    this.loadClients();
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  // Loaders
  public loadQuotations() {
    this.apiService.getQuotations(this.searchText || undefined, this.selectedStatus || undefined)
      .subscribe({
        next: data => this.quotations.set(data || []),
        error: () => {}
      });
  }

  public loadInvoices() {
    this.apiService.getInvoices(this.invoiceSearchText || undefined, this.invoiceSelectedStatus || undefined)
      .subscribe({
        next: data => this.invoices.set(data || []),
        error: () => {}
      });
  }

  public loadClients() {
    this.apiService.getClients().subscribe({
      next: data => this.clients.set(data || []),
      error: () => {}
    });
  }

  // Quotation Handlers
  public handleSearch() {
    this.loadQuotations();
  }

  public handleCreateQuotation(event: Event) {
    event.preventDefault();
    if (!this.newQuotation.client_id) {
      alert(this.getLocale() === 'ar' ? 'يرجى اختيار عميل!' : 'Please select a client!');
      return;
    }
    if (this.newQuotation.items.length === 0) {
      alert(this.getLocale() === 'ar' ? 'يرجى إضافة بند واحد على الأقل عرض السعر!' : 'Please add at least one item to the quotation!');
      return;
    }

    // Auto-generate number if blank
    if (!this.newQuotation.quotation_number) {
      this.newQuotation.quotation_number = 'QT-' + new Date().getFullYear() + '-' + Math.floor(1000 + Math.random() * 9000);
    }

    this.apiService.createQuotation(this.newQuotation).subscribe(() => {
      this.showSuccessMsg.set(this.getLocale() === 'ar' ? 'تم إنشاء عرض السعر بنجاح!' : 'Quotation created successfully!');
      this.loadQuotations();
      this.resetQuotationForm();
      this.activeSubTab.set('quotations');
      setTimeout(() => this.showSuccessMsg.set(''), 3000);
    });
  }

  public handleDeleteQuotation(id: number) {
    if (confirm(this.getLocale() === 'ar' ? 'هل أنت متأكد من حذف هذا العرض؟' : 'Are you sure you want to delete this quotation?')) {
      this.apiService.deleteQuotation(id).subscribe(() => {
        this.loadQuotations();
        // Also reload invoices as some might link to this
        this.loadInvoices();
      });
    }
  }

  public handleUpdateStatus(quotation: any, newStatus: string) {
    this.apiService.updateQuotation(quotation.id, { ...quotation, status: newStatus })
      .subscribe(() => this.loadQuotations());
  }

  // Items Array Helpers
  public addItem() {
    if (this.newItem.name && this.newItem.quantity > 0 && this.newItem.unit_price >= 0) {
      this.newQuotation.items.push({
        ...this.newItem,
        total_price: this.newItem.quantity * this.newItem.unit_price
      });
      this.calculateTotalQuotationAmount();
      this.newItem = { name: '', quantity: 1, unit_price: 0 };
    }
  }

  public removeItem(index: number) {
    this.newQuotation.items.splice(index, 1);
    this.calculateTotalQuotationAmount();
  }

  private calculateTotalQuotationAmount() {
    this.newQuotation.total_amount = this.newQuotation.items.reduce(
      (sum, item) => sum + (item.total_price || 0),
      0
    );
  }

  private resetQuotationForm() {
    this.newQuotation = {
      client_id: 0,
      quotation_number: '',
      status: 'pending',
      total_amount: 0,
      items: [],
      valid_until: '',
      notes: ''
    };
    this.newItem = { name: '', quantity: 1, unit_price: 0 };
  }

  // Invoice Handlers
  public handleSearchInvoices() {
    this.loadInvoices();
  }

  public handleCreateInvoice(event: Event) {
    event.preventDefault();
    if (!this.newInvoice.client_id) {
      alert(this.getLocale() === 'ar' ? 'يرجى اختيار عميل للفاتورة!' : 'Please select a client for the invoice!');
      return;
    }
    if (this.newInvoice.amount <= 0) {
      alert(this.getLocale() === 'ar' ? 'يرجى تحديد مبلغ الفاتورة!' : 'Please set the invoice amount!');
      return;
    }

    this.apiService.createInvoice(this.newInvoice).subscribe(() => {
      this.showSuccessMsg.set(this.getLocale() === 'ar' ? 'تم إنشاء الفاتورة بنجاح!' : 'Invoice created successfully!');
      this.loadInvoices();
      this.resetInvoiceForm();
      this.activeSubTab.set('invoices');
      setTimeout(() => this.showSuccessMsg.set(''), 3000);
    });
  }

  public handleDeleteInvoice(id: number) {
    if (confirm(this.getLocale() === 'ar' ? 'هل أنت متأكد من حذف هذه الفاتورة؟' : 'Are you sure you want to delete this invoice?')) {
      this.apiService.deleteInvoice(id).subscribe(() => this.loadInvoices());
    }
  }

  public handleUpdateInvoiceStatus(invoice: any, newStatus: string) {
    this.apiService.updateInvoice(invoice.id, { ...invoice, status: newStatus })
      .subscribe(() => this.loadInvoices());
  }

  public handleQuotationSelectionChange() {
    if (this.newInvoice.quotation_id) {
      const selectedQ = this.quotations().find(q => q.id === +this.newInvoice.quotation_id!);
      if (selectedQ) {
        this.newInvoice.client_id = selectedQ.client_id;
        this.newInvoice.amount = selectedQ.total_amount;
        this.newInvoice.notes = this.getLocale() === 'ar' 
          ? `فاتورة ناتجة عن عرض السعر رقم ${selectedQ.quotation_number}`
          : `Invoice generated from quotation ${selectedQ.quotation_number}`;
      }
    }
  }

  private resetInvoiceForm() {
    this.newInvoice = {
      client_id: 0,
      quotation_id: null,
      invoice_number: '',
      amount: 0,
      status: 'unpaid',
      due_date: '',
      notes: ''
    };
  }

  // UI Helpers (Labels & Classes)
  public getStatusLabel(status: string): string {
    const locale = this.getLocale();
    const labels: Record<string, Record<string, string>> = {
      pending:   { ar: 'قيد المراجعة', en: 'Pending Review' },
      sent:      { ar: 'تم الإرسال', en: 'Sent' },
      approved:  { ar: 'موافق عليه', en: 'Approved' },
      accepted:  { ar: 'مقبول', en: 'Accepted' },
      rejected:  { ar: 'مرفوض', en: 'Rejected' },
      completed: { ar: 'مكتمل', en: 'Completed' },
      expired:   { ar: 'منتهي الصلاحية', en: 'Expired' }
    };
    return labels[status]?.[locale] ?? status;
  }

  public getStatusClass(status: string): string {
    const classes: Record<string, string> = {
      pending:   'bg-amber-50 border-amber-200 text-amber-800',
      sent:      'bg-blue-50 border-blue-200 text-blue-800',
      approved:  'bg-emerald-50 border-emerald-200 text-emerald-800',
      accepted:  'bg-emerald-50 border-emerald-200 text-emerald-800',
      completed: 'bg-indigo-50 border-indigo-200 text-indigo-800',
      rejected:  'bg-rose-50 border-rose-200 text-rose-800',
      expired:   'bg-slate-100 border-slate-200 text-slate-600'
    };
    return classes[status] ?? 'bg-slate-50 border-slate-200 text-slate-700';
  }

  public getInvoiceStatusLabel(status: string): string {
    const locale = this.getLocale();
    const labels: Record<string, Record<string, string>> = {
      unpaid:         { ar: 'غير مدفوعة', en: 'Unpaid' },
      paid:           { ar: 'مدفوعة بالكامل', en: 'Paid' },
      partially_paid: { ar: 'مدفوعة جزئياً', en: 'Partially Paid' }
    };
    return labels[status]?.[locale] ?? status;
  }

  public getInvoiceStatusClass(status: string): string {
    const classes: Record<string, string> = {
      unpaid:         'bg-rose-50 border-rose-200 text-rose-800',
      paid:           'bg-emerald-50 border-emerald-200 text-emerald-800',
      partially_paid: 'bg-amber-50 border-amber-200 text-amber-800'
    };
    return classes[status] ?? 'bg-slate-50 border-slate-200 text-slate-700';
  }

  // Reports Calculations
  public getPaidInvoicesTotal(): number {
    return this.invoices()
      .filter(inv => inv.status === 'paid')
      .reduce((sum, inv) => sum + (+inv.amount || 0), 0);
  }

  public getUnpaidInvoicesTotal(): number {
    return this.invoices()
      .filter(inv => inv.status === 'unpaid')
      .reduce((sum, inv) => sum + (+inv.amount || 0), 0);
  }

  public getPartiallyPaidInvoicesTotal(): number {
    return this.invoices()
      .filter(inv => inv.status === 'partially_paid')
      .reduce((sum, inv) => sum + (+inv.amount || 0), 0);
  }

  public getInvoicesTotalSum(): number {
    return this.invoices().reduce((sum, inv) => sum + (+inv.amount || 0), 0);
  }

  public getApprovedQuotationsCount(): number {
    return this.quotations().filter(q => q.status === 'approved' || q.status === 'accepted' || q.status === 'completed').length;
  }

  public getQuotationSuccessRate(): number {
    const total = this.quotations().length;
    if (total === 0) return 0;
    const approved = this.getApprovedQuotationsCount();
    return Math.round((approved / total) * 100);
  }

  // KPIs
  public getTotalEstimated(): number {
    return this.quotations().reduce((sum: number, q: any) => sum + (+q.total_amount || 0), 0);
  }

  public getPendingCount(): number {
    return this.quotations().filter((q: any) => q.status === 'pending').length;
  }

  public getCompletedCount(): number {
    return this.quotations().filter((q: any) => q.status === 'completed').length;
  }
}
