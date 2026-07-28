import { Component, inject, signal, input, output, effect, untracked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { LanguageService } from '../../../services/language.service';

export interface NavigateTabEvent {
  role: 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' | 'engineer';
  tab: string;
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterLink],
  host: {
    'class': 'shrink-0 flex flex-col z-30 md:w-72 relative self-stretch h-full min-h-full bg-slate-900 border-e border-slate-800/80'
  },
  templateUrl: './sidebar.component.html',
})
export class SidebarComponent {
  public langService = inject(LanguageService);

  // Inputs
  public loggedUser = input<any>(null);
  public activeRole = input<'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' | 'engineer'>('admin');
  public adminActiveTab = input<string>('stats');
  public managerActiveTab = input<string>('products');
  public sellerActiveTab = input<string>('clients');
  public accountantActiveTab = input<string>('quotations');
  public isSidebarOpen = input<boolean>(false);

  // Outputs
  public navigateTab = output<NavigateTabEvent>();
  public toggleSidebar = output<void>();
  public logout = output<void>();
  public openAppDownload = output<void>();

  // Internal Signals for Collapsible Sub-menus
  public isCatalogOpen = signal<boolean>(false);
  public isEmployeesOpen = signal<boolean>(false);
  public isSettingsOpen = signal<boolean>(false);
  public isShowAllButtons = signal<boolean>(false);

  public toggleShowAllButtons() {
    this.isShowAllButtons.update(v => !v);
  }

  public isCatalogExpanded(): boolean {
    if (this.isCatalogOpen()) return true;
    const role = this.activeRole();
    const tab = this.managerActiveTab();
    return role === 'manager' && ['products', 'categories', 'brands'].includes(tab);
  }

  public isEmployeesExpanded(): boolean {
    if (this.isEmployeesOpen()) return true;
    const role = this.activeRole();
    const tab = this.adminActiveTab();
    return (role === 'admin' || role === 'ceo') && ['permissions', 'followup'].includes(tab);
  }

  public isSettingsExpanded(): boolean {
    if (this.isSettingsOpen()) return true;
    const role = this.activeRole();
    const tab = this.adminActiveTab();
    return (role === 'admin' && (tab === 'settings' || tab === 'permissions')) || (role === 'manager' && this.managerActiveTab() === 'areas');
  }

  public toggleCatalog() {
    this.isCatalogOpen.update(v => !v);
  }

  public toggleEmployees() {
    this.isEmployeesOpen.update(v => !v);
  }

  public toggleSettings() {
    this.isSettingsOpen.update(v => !v);
  }

  public isActive(role: 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' | 'engineer', tab: string): boolean {
    const userRole = this.getUserRole();
    const effectiveRole = (userRole === 'admin' || userRole === 'ceo') ? this.activeRole() : userRole;
    if (effectiveRole !== role) return false;
    switch (role) {
      case 'admin':
      case 'ceo':
        return this.adminActiveTab() === tab;
      case 'manager':
        return this.managerActiveTab() === tab;
      case 'seller':
      case 'engineer':
        return this.sellerActiveTab() === tab;
      case 'accountant':
        return this.accountantActiveTab() === tab;
    }
  }

  public onNavigate(role: 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' | 'engineer', tab: string, event?: Event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    this.navigateTab.emit({ role, tab });
  }

  public onToggleSidebar() {
    this.toggleSidebar.emit();
  }

  public onLogout() {
    this.logout.emit();
  }

  public getEffectiveRole(): 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' | 'engineer' {
    return this.activeRole();
  }

  public hasPermission(permission: string): boolean {
    if (this.isShowAllButtons()) return true;
    const effectiveRole = this.getEffectiveRole();
    if (effectiveRole === 'admin' || effectiveRole === 'ceo') return true;

    const user = this.loggedUser();
    if (!user) return false;

    const perms: string[] = user.permissions || [];
    if (perms.length > 0) {
      const spacePerm = permission.replace(/_/g, ' ');
      const underscorePerm = permission.replace(/\s+/g, '_');
      if (perms.includes('*') || perms.includes(permission) || perms.includes(spacePerm) || perms.includes(underscorePerm)) {
        return true;
      }
    }

    // Strict role-based default visibility rules for standard permissions
    const norm = permission.replace(/\s+/g, '_');
    switch (norm) {
      case 'view_clients':
      case 'create_clients':
      case 'view_tasks':
      case 'view_external_tasks':
      case 'view_quotations':
      case 'create_quotation':
      case 'view_invoices':
        return effectiveRole === 'seller' || effectiveRole === 'engineer' || effectiveRole === 'accountant' || effectiveRole === 'manager';
      case 'view_invoice_requests':
      case 'view_financial_reports':
        return effectiveRole === 'accountant' || effectiveRole === 'manager';
      case 'view_products':
      case 'view_categories':
      case 'view_brands':
      case 'view_maintenance_tasks':
      case 'manage_areas':
        return effectiveRole === 'manager' || effectiveRole === 'engineer';
      default:
        return false;
    }
  }

  public getUserRole(): 'admin' | 'ceo' | 'manager' | 'accountant' | 'seller' | 'engineer' {
    const u = this.loggedUser();
    if (!u) return 'admin';
    const email = String(u.email || '').toLowerCase();
    const r = String(u.role || u.rawRole || '').toLowerCase();
    if (r === 'admin' || r.includes('نظام')) return 'admin';
    if (r === 'ceo' || r.includes('المدير العام') || r.includes('general manager')) return 'ceo';
    if (r.includes('manager') || r.includes('operations')) return 'manager';
    if (r.includes('accountant') || r.includes('محاسب')) return 'accountant';
    if (r.includes('engineer') || r.includes('outdoor') || r.includes('indoor') || r.includes('فني') || r.includes('مهندس') || email.includes('engineer') || email.includes('tech')) return 'engineer';
    return 'seller';
  }

  public getUserDisplayRole(): string {
    const u = this.loggedUser();
    if (!u) return 'Staff';
    const isAr = this.langService.currentLang() === 'ar';
    const userRole = this.getUserRole();

    switch (userRole) {
      case 'engineer':
        return isAr ? '👷‍♂️ مهندس صيانة ميدانية' : 'Field Engineer';
      case 'seller':
        return isAr ? '💼 مسؤول مبيعات' : 'Sales Representative';
      case 'accountant':
        return isAr ? '💰 المحاسب المالي' : 'Accountant';
      case 'manager':
        return isAr ? '📊 مدير الصيانة والعمليات' : 'Operations Manager';
      case 'ceo':
        return isAr ? '👔 المدير العام' : 'General Manager';
      case 'admin':
        return isAr ? '👑 مدير النظام' : 'Administrator';
      default:
        return u.role || 'Staff';
    }
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
}
