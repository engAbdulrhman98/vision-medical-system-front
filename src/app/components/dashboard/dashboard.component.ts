import { Component, inject, signal, OnInit, OnDestroy, computed, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../services/language.service';
import { ApiService } from '../../services/api.service';
import { AdminViewComponent } from './views/admin-view.component';
import { ManagerViewComponent } from './views/manager-view.component';
import { AccountantViewComponent } from './views/accountant-view.component';
import { SellerViewComponent } from './views/seller-view.component';
import { ChatComponent } from './chat/chat.component';
import { SidebarComponent } from './sidebar/sidebar.component';
import { AppDownloadModalComponent } from '../app-download-modal/app-download-modal.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    FormsModule,
    AdminViewComponent,
    ManagerViewComponent,
    AccountantViewComponent,
    SellerViewComponent,
    ChatComponent,
    SidebarComponent,
    AppDownloadModalComponent
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent implements OnInit, OnDestroy {
  public langService = inject(LanguageService);
  private router = inject(Router);
  private apiService = inject(ApiService);
  private notificationsPollInterval: any;

  // States
  public activeRole = signal<'admin' | 'ceo' | 'manager' | 'accountant' | 'seller'>('admin');
  public isRoleSelectorOpen = signal<boolean>(false);
  public isSidebarOpen = signal<boolean>(false);
  public isCatalogOpen = signal<boolean>(false);
  public isSettingsOpen = signal<boolean>(false);
  public isEmployeesOpen = signal<boolean>(false);
  public showAppDownloadModal = signal<boolean>(false);
  public loggedUser = signal<any>(null);
  public managerActiveTab = signal<string>('products');
  public adminActiveTab = signal<string>('stats');
  public sellerActiveTab = signal<string>('clients');
  public accountantActiveTab = signal<string>('quotations');

  public toggleRoleSelector() {
    this.isRoleSelectorOpen.update(v => !v);
  }

  public selectRoleView(role: 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller') {
    this.activeRole.set(role);
    this.isRoleSelectorOpen.set(false);
  }

  public getActiveRoleLabel(): string {
    const role = this.activeRole();
    const isAr = this.langService.currentLang() === 'ar';
    switch (role) {
      case 'admin':
        return isAr ? '👑 مدير النظام (Admin)' : 'Admin View';
      case 'ceo':
        return isAr ? '👔 المدير العام (متابعة الموظفين)' : 'CEO / General Manager';
      case 'manager':
        return isAr ? '📊 مدير الصيانة والمنتجات' : 'Manager View';
      case 'accountant':
        return isAr ? '💰 المحاسب والماليات' : 'Accountant View';
      case 'seller':
        return isAr ? '💼 المبيعات والعملاء' : 'Sales View';
    }
  }

  public toggleCatalogMenu() {
    this.isCatalogOpen.update(v => !v);
  }

  public toggleSettingsMenu() {
    this.isSettingsOpen.update(v => !v);
  }

  public toggleEmployeesMenu() {
    this.isEmployeesOpen.update(v => !v);
  }

  private isInitialized = false;

  constructor() {
    effect(() => {
      const role = this.activeRole();
      const managerTab = this.managerActiveTab();
      const adminTab = this.adminActiveTab();
      const sellerTab = this.sellerActiveTab();
      const accountantTab = this.accountantActiveTab();

      if (typeof window !== 'undefined' && this.isInitialized) {
        localStorage.setItem('vm_dashboard_role', role);
        localStorage.setItem('vm_manager_active_tab', managerTab);
        localStorage.setItem('vm_admin_active_tab', adminTab);
        localStorage.setItem('vm_seller_active_tab', sellerTab);
        localStorage.setItem('vm_accountant_active_tab', accountantTab);
      }
    });
  }

  // Change Password Modal States
  public showChangePasswordModal = signal<boolean>(false);
  public currentPassword = signal<string>('');
  public newPassword = signal<string>('');
  public newPasswordConfirm = signal<string>('');
  public changePasswordError = signal<string | null>(null);
  public isChangingPassword = signal<boolean>(false);

  public submitChangePassword() {
    this.changePasswordError.set(null);
    if (!this.currentPassword() || !this.newPassword()) {
      this.changePasswordError.set('يرجى ملء جميع الحقول المطلوبة.');
      return;
    }
    if (this.newPassword() !== this.newPasswordConfirm()) {
      this.changePasswordError.set('كلمة المرور الجديدة غير متطابقة مع تأكيد كلمة المرور.');
      return;
    }
    if (this.newPassword().length < 6) {
      this.changePasswordError.set('يجب ألا تقل كلمة المرور الجديدة عن 6 أحرف.');
      return;
    }

    this.isChangingPassword.set(true);
    this.apiService.changePassword(this.currentPassword(), this.newPassword(), this.newPasswordConfirm()).subscribe({
      next: (res) => {
        this.isChangingPassword.set(false);
        this.showChangePasswordModal.set(false);
        const user = this.loggedUser();
        if (user) {
          user.must_change_password = false;
          this.loggedUser.set({ ...user });
          if (typeof window !== 'undefined') {
            localStorage.setItem('vm_logged_user', JSON.stringify(user));
          }
        }
      },
      error: (err) => {
        this.isChangingPassword.set(false);
        this.changePasswordError.set(err?.error?.message || 'كلمة المرور الحالية غير صحيحة.');
      }
    });
  }

  ngOnInit() {
    if (typeof window !== 'undefined') {
      const userStr = localStorage.getItem('vm_logged_user');
      if (!userStr) {
        this.router.navigate(['/login']);
        return;
      }
      try {
        const user = JSON.parse(userStr);
        this.loggedUser.set(user);

        if (user && user.must_change_password) {
          const roleName = String(user.role || '').toLowerCase();
          if (!roleName.includes('admin') && !roleName.includes('manager')) {
            this.showChangePasswordModal.set(true);
          }
        }

        this.loadNotifications();

        if (typeof window !== 'undefined') {
          this.notificationsPollInterval = setInterval(() => {
            this.loadNotifications();
          }, 60000);
        }

        // Restore role from local storage if saved
        const userRole = this.getUserRole();
        const savedRole = localStorage.getItem('vm_dashboard_role') as any;
        if (savedRole && (userRole === 'admin' || savedRole === userRole)) {
          this.activeRole.set(savedRole);
        } else {
          this.activeRole.set(userRole);
        }

        // Restore tabs
        const savedManagerTab = localStorage.getItem('vm_manager_active_tab');
        if (savedManagerTab) this.managerActiveTab.set(savedManagerTab);

        const savedAdminTab = localStorage.getItem('vm_admin_active_tab');
        if (savedAdminTab) this.adminActiveTab.set(savedAdminTab);

        const savedSellerTab = localStorage.getItem('vm_seller_active_tab');
        if (savedSellerTab) this.sellerActiveTab.set(savedSellerTab);

        const savedAccountantTab = localStorage.getItem('vm_accountant_active_tab');
        if (savedAccountantTab) this.accountantActiveTab.set(savedAccountantTab);

        this.isInitialized = true;
      } catch (e) {
        console.error('Failed to parse logged user', e);
        this.router.navigate(['/login']);
      }
    }
  }

  ngOnDestroy() {
    if (this.notificationsPollInterval) {
      clearInterval(this.notificationsPollInterval);
    }
  }

  public getUserRole(): 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' {
    const u = this.loggedUser();
    if (!u || !u.role) return 'admin';
    const r = String(u.role).toLowerCase();
    if (r === 'admin' || r.includes('نظام')) return 'admin';
    if (r === 'ceo' || r.includes('المدير العام') || r.includes('general manager')) return 'ceo';
    if (r.includes('manager') || r.includes('operations')) return 'manager';
    if (r.includes('accountant') || r.includes('محاسب')) return 'accountant';
    return 'seller';
  }

  public getEffectiveRole(): 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' {
    const userRole = this.getUserRole();
    if (userRole === 'admin' || userRole === 'ceo') return this.activeRole();
    const currentActive = this.activeRole();
    if (currentActive === userRole) return currentActive;
    return userRole;
  }

  public hasPermission(permission: string): boolean {
    const user = this.loggedUser();
    if (!user) return false;
    if (user.role === 'admin' || user.role === 'ceo') return true;
    const perms = user.permissions || [];
    return perms.includes(permission);
  }

  public selectRole(role: 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller') {
    this.activeRole.set(role);
    this.isSidebarOpen.set(false);
  }

  public navigateTab(role: 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller', tab: string) {
    const userRole = this.getUserRole();
    const effectiveRole = (userRole === 'admin' || userRole === 'ceo') ? role : userRole;
    this.activeRole.set(effectiveRole);

    if (effectiveRole === 'admin' || effectiveRole === 'ceo') this.adminActiveTab.set(tab);
    else if (effectiveRole === 'manager') this.managerActiveTab.set(tab);
    else if (effectiveRole === 'accountant') this.accountantActiveTab.set(tab);
    else if (effectiveRole === 'seller') this.sellerActiveTab.set(tab);
    this.isSidebarOpen.set(false);
  }

  public toggleLanguage() {
    const nextLang = this.langService.currentLang() === 'ar' ? 'en' : 'ar';
    this.langService.setLanguage(nextLang);
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public getUserName(): string {
    const u = this.loggedUser();
    if (!u) return '';
    if (typeof u.name === 'string') return u.name;
    return u.name?.ar || u.name?.en || 'Vision Staff';
  }

  public getUserInitial(): string {
    const name = this.getUserName();
    return name ? name.charAt(0).toUpperCase() : 'U';
  }

  public toggleSidebar() {
    this.isSidebarOpen.update(val => !val);
  }

  public logout() {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('vm_logged_user');
    }
    this.router.navigate(['/login']);
  }

  // Notification states & operations
  public isNotificationsOpen = signal<boolean>(false);
  public notifications = signal<any[]>([]);

  public loadNotifications() {
    this.apiService.getNotifications().subscribe({
      next: (res) => {
        this.notifications.set(res || []);
      },
      error: (err) => {
        console.error('Failed to load notifications', err);
      }
    });
  }

  private formatTimeAgo(dateVal: any): string {
    if (!dateVal) return '';
    try {
      let date: Date;
      if (typeof dateVal === 'object' && dateVal.date) {
        date = new Date(dateVal.date);
      } else {
        date = new Date(dateVal);
      }
      if (isNaN(date.getTime())) return '';
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffMins = Math.floor(diffMs / 60000);
      if (diffMins < 1) return 'now';
      if (diffMins < 60) return `${diffMins}m`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `${diffHours}h`;
      const diffDays = Math.floor(diffHours / 24);
      return `${diffDays}d`;
    } catch {
      return '';
    }
  }

  public unreadNotificationsCount = computed(() => {
    return this.notifications().filter(n => !n.read_at).length;
  });

  public notificationGroups = computed(() => {
    const list = this.notifications();
    const isAr = this.langService.currentLang() === 'ar';
    
    // Group notifications by type
    const groupsMap: { [key: string]: any[] } = {};
    for (const notif of list) {
      let type = 'system';
      if (notif.task_id && notif.maintenance_report_id) {
        type = 'products';
      } else if (notif.task_id) {
        type = 'system';
      } else if (notif.role_name === 'Accountant') {
        type = 'financial';
      }
      
      if (!groupsMap[type]) {
        groupsMap[type] = [];
      }
      groupsMap[type].push(notif);
    }

    const typeDetails: { [key: string]: { label: string; icon: string; bg: string } } = {
      system: {
        label: isAr ? 'النظام والصلاحيات' : 'System & Permissions',
        icon: 'fa-solid fa-shield-halved text-blue-500',
        bg: 'bg-blue-50'
      },
      messages: {
        label: isAr ? 'الرسائل والتواصل' : 'Messages & Contacts',
        icon: 'fa-solid fa-envelope text-amber-500',
        bg: 'bg-amber-50'
      },
      reviews: {
        label: isAr ? 'التقييمات والمراجعة' : 'Reviews & Approvals',
        icon: 'fa-solid fa-star text-yellow-500',
        bg: 'bg-yellow-50'
      },
      inventory: {
        label: isAr ? 'المخزون والمستودع' : 'Stock & Inventory',
        icon: 'fa-solid fa-boxes-stacked text-rose-500',
        bg: 'bg-rose-50'
      },
      products: {
        label: isAr ? 'المنتجات والأقسام' : 'Products & Categories',
        icon: 'fa-solid fa-stethoscope text-indigo-500',
        bg: 'bg-indigo-50'
      },
      financial: {
        label: isAr ? 'المالية والفواتير' : 'Financial & Billings',
        icon: 'fa-solid fa-file-invoice-dollar text-emerald-500',
        bg: 'bg-emerald-50'
      },
      clients: {
        label: isAr ? 'العملاء والشركاء' : 'Clients & Partners',
        icon: 'fa-solid fa-users text-teal-500',
        bg: 'bg-teal-50'
      },
      sales: {
        label: isAr ? 'المبيعات وعروض الأسعار' : 'Sales & Quotations',
        icon: 'fa-solid fa-chart-line text-cyan-500',
        bg: 'bg-cyan-50'
      }
    };

    return Object.keys(groupsMap).map(type => ({
      type,
      label: typeDetails[type]?.label || type,
      icon: typeDetails[type]?.icon || 'fa-solid fa-bell text-slate-500',
      bg: typeDetails[type]?.bg || 'bg-slate-50',
      items: groupsMap[type].map(item => {
        const titleObj = item.title;
        const msgObj = item.message;
        let text = '';
        if (titleObj) {
          text = isAr ? (titleObj.ar || titleObj.en || '') : (titleObj.en || titleObj.ar || '');
        }
        if (!text && msgObj) {
          text = isAr ? (msgObj.ar || msgObj.en || '') : (msgObj.en || msgObj.ar || '');
        }
        if (!text) {
          text = typeof item.title === 'string' ? item.title : '';
        }
        
        return {
          id: item.id,
          unread: !item.read_at,
          text: text || (isAr ? 'تنبيه جديد' : 'New notification'),
          time: item.created_at ? this.formatTimeAgo(item.created_at) : ''
        };
      })
    }));
  });

  public toggleNotifications() {
    console.log('toggleNotifications clicked! Current state:', this.isNotificationsOpen());
    this.isNotificationsOpen.set(!this.isNotificationsOpen());
    console.log('New state:', this.isNotificationsOpen());
  }

  public markAsRead(id: number) {
    this.apiService.markNotificationAsRead(id).subscribe({
      next: () => this.loadNotifications(),
      error: (err) => console.error('Failed to mark notification as read', err)
    });
  }

  public markAllAsRead() {
    this.apiService.markAllNotificationsAsRead().subscribe({
      next: () => this.loadNotifications(),
      error: (err) => console.error('Failed to mark all as read', err)
    });
  }
}
