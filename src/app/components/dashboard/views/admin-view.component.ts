import { Component, inject, signal, model, effect, untracked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../../services/language.service';
import { ApiService, Review, ContactMessage, ActivityLog } from '../../../services/api.service';
import { TasksComponent } from '../tasks/tasks.component';
import { EmployeesComponent } from '../employees/employees.component';
import { EmployeeFollowupComponent } from '../employee-followup/employee-followup.component';
import { ChatComponent } from '../chat/chat.component';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-admin-view',
  standalone: true,
  imports: [CommonModule, FormsModule, TasksComponent, EmployeesComponent, EmployeeFollowupComponent, ChatComponent],
  templateUrl: './admin-view.component.html'
})
export class AdminViewComponent {
  public langService = inject(LanguageService);
  public apiService = inject(ApiService);
  private toastService = inject(ToastService);

  // States
  public stats = signal<any>({
    total_visits: 0,
    today_visits: 0,
    products: 0,
    categories: 0,
    brands: 0,
    pending_reviews: 0,
    unread_messages: 0
  });
  public pendingReviews: any = signal([]);
  public messages: any = signal([]);
  public logs: any = signal([]);

  // Active view tabs
  public activeSubTab = model<string>('stats');

  // Roles & Users state from DB
  public systemRoles = signal<any[]>([]);
  public users = signal<any[]>([]);
  public selectedRoleIndex = signal<number>(0);
  public expandedGroups = signal<number[]>([1, 2, 3, 4, 5, 6]);

  public toggleGroup(groupId: number) {
    const current = this.expandedGroups();
    if (current.includes(groupId)) {
      this.expandedGroups.set(current.filter(id => id !== groupId));
    } else {
      this.expandedGroups.set([...current, groupId]);
    }
  }

  // Role Assignment form state
  public assignEmail = '';
  public assignSelectedRole = 'Admin';
  public showAssignmentSuccess = signal<boolean>(false);

  // ─── Settings state ───────────────────────────────────────────────
  public settingsActiveTab = signal<'core' | 'about' | 'footer' | 'hours' | 'app'>('core');
  public settingsLoading = signal<boolean>(false);
  public settingsSaved = signal<boolean>(false);
  public settingsError = signal<string>('');
  public settingsForm = signal<any>({
    store_name: { ar: '', en: '' },
    store_email: '',
    store_phone: '',
    whatsapp: '',
    maintenance_phone: '',
    maintenance_whatsapp: '',
    about_us_title: { ar: '', en: '' },
    about_us_content: { ar: '', en: '' },
    footer_text: { ar: '', en: '' },
    company_map_link: '',
    app_android_url: '',
    app_ios_url: '',
    app_version: 'v2.5.2',
    app_release_notes: '',
    working_hours_days: {
      saturday:  { open: true,  from: '08:00', to: '17:00' },
      sunday:    { open: true,  from: '08:00', to: '17:00' },
      monday:    { open: true,  from: '08:00', to: '17:00' },
      tuesday:   { open: true,  from: '08:00', to: '17:00' },
      wednesday: { open: true,  from: '08:00', to: '17:00' },
      thursday:  { open: true,  from: '08:00', to: '17:00' },
      friday:    { open: false, from: '08:00', to: '17:00' },
    }
  });

  public readonly dayKeys = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  public readonly dayLabels: Record<string, { ar: string; en: string }> = {
    saturday:  { ar: 'السبت',    en: 'Sat' },
    sunday:    { ar: 'الأحد',    en: 'Sun' },
    monday:    { ar: 'الاثنين',  en: 'Mon' },
    tuesday:   { ar: 'الثلاثاء', en: 'Tue' },
    wednesday: { ar: 'الأربعاء', en: 'Wed' },
    thursday:  { ar: 'الخميس',   en: 'Thu' },
    friday:    { ar: 'الجمعة',   en: 'Fri' },
  };

  public getDayLabel(day: string): string {
    const lang: 'ar' | 'en' = this.langService.currentLang();
    return this.dayLabels[day]?.[lang] ?? day;
  }

  private settingsLoaded = false;

  public loadSettings(force = false) {
    if (this.settingsLoaded && !force) return;
    this.settingsLoaded = true;
    this.settingsLoading.set(true);
    this.apiService.getSettings().subscribe({
      next: (res) => {
        const days: any = {};
        for (const d of this.dayKeys) {
          const raw = res.working_hours_days?.[d] || {};
          days[d] = {
            open: raw.open === '1' || raw.open === true || raw.open === 1,
            from: raw.from || '08:00',
            to: raw.to || '17:00'
          };
        }
        this.settingsForm.set({
          store_name: res.store_name || { ar: '', en: '' },
          store_email: res.store_email || '',
          store_phone: res.store_phone || '',
          whatsapp: res.whatsapp || '',
          maintenance_phone: res.maintenance_phone || '',
          maintenance_whatsapp: res.maintenance_whatsapp || '',
          about_us_title: res.about_us_title || { ar: '', en: '' },
          about_us_content: res.about_us_content || { ar: '', en: '' },
          footer_text: res.footer_text || { ar: '', en: '' },
          company_map_link: res.company_map_link || '',
          app_android_url: res.app_android_url || 'https://vision-medical-system-front-production.up.railway.app/downloads/vision-medical.apk',
          app_ios_url: res.app_ios_url || 'https://apps.apple.com',
          app_version: res.app_version || 'v2.5.2',
          app_release_notes: res.app_release_notes || '',
          working_hours_days: days
        });
        this.settingsLoading.set(false);
      },
      error: () => this.settingsLoading.set(false)
    });
  }

  public handleSaveSettings() {
    this.settingsSaved.set(false);
    this.settingsError.set('');
    this.apiService.updateSettings(this.settingsForm()).subscribe({
      next: () => {
        this.settingsSaved.set(true);
        this.toastService.success({
          ar: 'تم حفظ إعدادات الموقع بنجاح!',
          en: 'Site settings saved successfully!'
        });
        setTimeout(() => this.settingsSaved.set(false), 3500);
      },
      error: (err) => {
        const backendMsg = err?.error?.message || err?.error?.error || '';
        const validationErrors = err?.error?.errors ? Object.values(err.error.errors).flat().join(', ') : '';
        const errorText = validationErrors || backendMsg || (this.getLocale() === 'ar' ? 'فشل حفظ الإعدادات. تحقق من الحقول.' : 'Failed to save settings. Check the fields.');
        this.settingsError.set(errorText);
        this.toastService.error(errorText);
      }
    });
  }

  public patchSettings(path: string[], value: any) {
    const form = { ...this.settingsForm() };
    let obj: any = form;
    for (let i = 0; i < path.length - 1; i++) {
      obj[path[i]] = { ...obj[path[i]] };
      obj = obj[path[i]];
    }
    obj[path[path.length - 1]] = value;
    this.settingsForm.set(form);
  }

  public toggleDay(day: string) {
    const form = { ...this.settingsForm() };
    form.working_hours_days = { ...form.working_hours_days };
    form.working_hours_days[day] = { ...form.working_hours_days[day], open: !form.working_hours_days[day].open };
    this.settingsForm.set(form);
  }

  public patchDayTime(day: string, field: 'from' | 'to', value: string) {
    const form = { ...this.settingsForm() };
    form.working_hours_days = { ...form.working_hours_days };
    form.working_hours_days[day] = { ...form.working_hours_days[day], [field]: value };
    this.settingsForm.set(form);
  }
  // ─────────────────────────────────────────────────────────────────

  constructor() {
    this.refreshData();
    effect(() => {
      const tab = this.activeSubTab();
      untracked(() => {
        if (tab === 'settings') {
          this.loadSettings();
        } else if (tab === 'permissions' && this.systemRoles().length === 0) {
          this.loadRolesAndUsers();
        }
      });
    }, { allowSignalWrites: true });
  }

  public refreshData() {
    this.apiService.getDashboardStats().subscribe({
      next: stats => this.stats.set(stats),
      error: () => {}
    });
    this.apiService.getPendingReviews().subscribe({
      next: reviews => this.pendingReviews.set(reviews),
      error: () => {}
    });
    this.apiService.getMessages().subscribe({
      next: messages => this.messages.set(messages),
      error: () => {}
    });
    this.apiService.getActivityLogs().subscribe({
      next: logs => this.logs.set(logs),
      error: () => {}
    });
  }

  public loadRolesAndUsers() {
    this.apiService.getRoles().subscribe({
      next: roles => this.systemRoles.set(roles),
      error: () => {}
    });
    this.apiService.getUsers().subscribe({
      next: users => this.users.set(users),
      error: () => {}
    });
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public handleApproveReview(reviewId: number) {
    this.apiService.approveReview(reviewId).subscribe(() => {
      this.refreshData();
      this.toastService.success({
        ar: 'تم قبول ونشر التقييم بنجاح!',
        en: 'Review approved and published successfully!'
      });
    });
  }

  public handleDeleteReview(reviewId: number) {
    if (confirm(this.getLocale() === 'ar' ? 'هل أنت متأكد من حذف هذا التقييم؟' : 'Are you sure you want to delete this review?')) {
      this.apiService.deleteReview(reviewId).subscribe(() => {
        this.refreshData();
        this.toastService.success({
          ar: 'تم حذف التقييم بنجاح!',
          en: 'Review deleted successfully!'
        });
      });
    }
  }

  public handleReadMessage(msgId: number) {
    this.apiService.readMessage(msgId).subscribe(() => {
      this.refreshData();
      this.toastService.info({
        ar: 'تم تحديد الرسالة كمقروءة.',
        en: 'Message marked as read.'
      });
    });
  }

  public handleDeleteMessage(msgId: number) {
    if (confirm(this.getLocale() === 'ar' ? 'هل أنت متأكد من حذف هذه الرسالة؟' : 'Are you sure you want to delete this message?')) {
      this.apiService.deleteMessage(msgId).subscribe(() => {
        this.refreshData();
        this.toastService.success({
          ar: 'تم حذف الرسالة بنجاح!',
          en: 'Message deleted successfully!'
        });
      });
    }
  }

  public selectSubTab(tab: 'stats' | 'reviews' | 'messages' | 'permissions' | 'settings') {
    this.activeSubTab.set(tab);
    if (tab === 'settings') this.loadSettings();
  }

  public togglePermission(roleIndex: number, permission: string) {
    const roles = this.systemRoles();
    const roleName = roles[roleIndex].name;
    this.apiService.togglePermission(roleName, permission).subscribe(() => {
      this.apiService.addActivity(
        this.getLocale() === 'ar' 
          ? `تعديل صلاحيات دور: ${roleName}` 
          : `Modified permissions for role: ${roleName}`,
        'Admin'
      ).subscribe(() => {
        this.refreshData();
        this.toastService.success({
          ar: `تم تعديل صلاحية (${this.translatePermission(permission)}) بنجاح!`,
          en: `Permission (${permission}) modified successfully!`
        });
      });
    });
  }

  public handleAssignRole(event: Event) {
    event.preventDefault();
    if (!this.assignEmail) return;

    this.apiService.assignRole(this.assignEmail, this.assignSelectedRole).subscribe({
      next: () => {
        this.apiService.addActivity(
          this.getLocale() === 'ar' 
            ? `تعيين دور (${this.assignSelectedRole}) للبريد الإلكتروني: ${this.assignEmail}` 
            : `Assigned role (${this.assignSelectedRole}) to email: ${this.assignEmail}`,
          'Admin'
        ).subscribe(() => {
          this.refreshData();
          this.showAssignmentSuccess.set(true);
          this.toastService.success({
            ar: `تم تعيين دور (${this.assignSelectedRole}) للبريد الإلكتروني: ${this.assignEmail} بنجاح!`,
            en: `Assigned role (${this.assignSelectedRole}) to email: ${this.assignEmail} successfully!`
          });
          setTimeout(() => this.showAssignmentSuccess.set(false), 3000);
          this.assignEmail = '';
        });
      },
      error: () => {
        this.toastService.error({
          ar: 'حدث خطأ أثناء تعيين الدور. يرجى التأكد من صحة البريد الإلكتروني المدخل.',
          en: 'Failed to assign role. Make sure the email exists and is valid.'
        });
      }
    });
  }

  public translatePermission(perm: string): string {
    const isAr = this.getLocale() === 'ar';
    const translations: { [key: string]: { ar: string; en: string } } = {
      'view tasks': { ar: 'عرض المهام وتكليفات الصيانة', en: 'View Tasks' },
      'create tasks': { ar: 'إنشاء المهام وتكليفات جديدة', en: 'Create Tasks' },
      'edit tasks': { ar: 'تعديل المهام المسجلة', en: 'Edit Tasks' },
      'delete tasks': { ar: 'حذف المهام من النظام', en: 'Delete Tasks' },
      'assign tasks': { ar: 'تعيين وتكليف المهام للمهندسين', en: 'Assign Tasks' },

      'view maintenance_schedules': { ar: 'عرض جداول الصيانة الوقائية', en: 'View Maintenance Schedules' },
      'create maintenance_schedules': { ar: 'جدولة مواعيد صيانة جديدة', en: 'Create Maintenance Schedules' },
      'edit maintenance_schedules': { ar: 'تعديل جداول الصيانة', en: 'Edit Maintenance Schedules' },
      'delete maintenance_schedules': { ar: 'حذف جداول الصيانة', en: 'Delete Maintenance Schedules' },

      'view devices': { ar: 'عرض الأجهزة الطبية للعملاء', en: 'View Medical Devices' },
      'create devices': { ar: 'تسجيل وتنزيل جهاز طبي جديد', en: 'Create Medical Devices' },
      'edit devices': { ar: 'تعديل بيانات وملفات الأجهزة', en: 'Edit Medical Devices' },
      'delete devices': { ar: 'حذف جهاز طبي من النظام', en: 'Delete Medical Devices' },

      'view maintenance_reports': { ar: 'عرض تقارير الصيانة الفنية', en: 'View Maintenance Reports' },
      'create maintenance_reports': { ar: 'كتابة تقرير صيانة جديد', en: 'Create Maintenance Reports' },
      'edit maintenance_reports': { ar: 'تعديل تقرير صيانة معتمد', en: 'Edit Maintenance Reports' },
      'delete maintenance_reports': { ar: 'حذف تقرير صيانة من الأرشيف', en: 'Delete Maintenance Reports' },

      'view stock_items': { ar: 'عرض قطع الغيار والمستلزمات', en: 'View Stock Items' },
      'create stock_items': { ar: 'إضافة وتوريد قطع غيار جديدة', en: 'Create Stock Items' },
      'edit stock_items': { ar: 'تعديل كميات وأسعار قطع الغيار', en: 'Edit Stock Items' },
      'delete stock_items': { ar: 'حذف صنف قطع غيار', en: 'Delete Stock Items' },

      'view products': { ar: 'عرض كتالوج المنتجات الطبية', en: 'View Products' },
      'create products': { ar: 'إضافة منتج طبي للكتالوج', en: 'Create Products' },
      'edit products': { ar: 'تعديل أسعار وبيانات المنتجات', en: 'Edit Products' },
      'delete products': { ar: 'إزالة منتج طبي من الكتالوج', en: 'Delete Products' },

      'view clients': { ar: 'عرض سجل العملاء والمستشفيات والعيادات', en: 'View Clients Directory' },
      'create clients': { ar: 'إضافة وتسجيل عميل / مستشفى جديد', en: 'Create Clients' },
      'edit clients': { ar: 'تعديل بيانات وفروع العملاء ومسؤولي التواصل', en: 'Edit Clients' },
      'delete clients': { ar: 'حذف سجل عميل من النظام', en: 'Delete Clients' },
      'view external_tasks': { ar: 'عرض تكليفات الصيانة الخارجية والزيارات الميدانية', en: 'View External Maintenance Visits' },

      'view quotations': { ar: 'عرض عروض الأسعار الصادرة', en: 'View Quotations' },
      'create quotations': { ar: 'إنشاء وإصدار عرض سعر للعميل', en: 'Create Quotations' },
      'create_quotation': { ar: 'طلب إنشاء عرض سعر وإرساله للمحاسب', en: 'Request Quotation' },
      'edit quotations': { ar: 'تعديل بنود وتفاصيل عرض السعر', en: 'Edit Quotations' },
      'delete quotations': { ar: 'حذف وإلغاء عرض سعر معتمد', en: 'Delete Quotations' },

      'view invoices': { ar: 'عرض الفواتير والتحصيل الميداني', en: 'View Invoices' },
      'view invoice_requests': { ar: 'عرض طلبات الفواتير والاعتماد', en: 'View Invoice Requests' },
      'view financials': { ar: 'عرض تقارير الحسابات والتحصيلات', en: 'View Financials' },
      'manage financials': { ar: 'إدارة المعاملات والمدفوعات والمراجعات', en: 'Manage Financials' },

      'manage users': { ar: 'إدارة حسابات الموظفين وتعديل صلاحياتهم', en: 'Manage Users & Roles' },
      'manage settings': { ar: 'تحديث بيانات الشركة وإعدادات المتجر العامة', en: 'Manage Settings' }
    };

    return translations[perm] ? (isAr ? translations[perm].ar : translations[perm].en) : perm;
  }
}
