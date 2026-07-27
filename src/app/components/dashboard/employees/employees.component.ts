import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../services/api.service';
import { LanguageService } from '../../../services/language.service';

@Component({
  selector: 'app-employees',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './employees.component.html',
  styleUrl: './employees.component.css'
})
export class EmployeesComponent implements OnInit {
  public apiService = inject(ApiService);
  public langService = inject(LanguageService);

  // State
  public employees = signal<any[]>([]);
  public filteredEmployees = signal<any[]>([]);
  public roles = signal<string[]>([]);
  public isLoading = signal(false);
  public showForm = signal(false);
  public editingEmployee = signal<any | null>(null);
  public successMessage = signal('');
  public errorMessage = signal('');
  public searchText = '';
  public filterRole = '';

  // Form Fields
  public formName = '';
  public formEmail = '';
  public formPassword = '';
  public formRole = '';
  public showPassword = false;

  // ─── Permissions Modal State ───
  public showPermissionsModal = signal(false);
  public permissionsEmployee = signal<any | null>(null);
  public allPermissions = signal<Array<{ name: string; id: number }>>([]);
  public rolePermissions = signal<string[]>([]);
  public directPermissions = signal<string[]>([]);
  public permLoading = signal(false);
  public permSaving = signal(false);
  public permSuccess = signal('');

  // ─── Progress Dashboard State ───
  public showProgressModal = signal(false);
  public selectedEmployeeForProgress = signal<any | null>(null);

  // ─── Create Role Modal State ───
  public showCreateRoleModal = signal(false);
  public newRoleName = '';
  public newRoleDescriptionAr = '';
  public isCreatingRole = signal(false);

  public isAdmin(): boolean {
    if (typeof window === 'undefined') return false;
    const userStr = localStorage.getItem('vm_logged_user');
    if (!userStr) return false;
    try {
      const user = JSON.parse(userStr);
      const role = (user.role || '').toLowerCase();
      return role === 'admin';
    } catch {
      return false;
    }
  }

  public openCreateRoleModal() {
    if (!this.isAdmin()) {
      this.errorMessage.set(this.lang === 'ar' ? 'عذراً! مدير النظام (Admin) فقط هو المصرح له بإنشاء أدوار وظيفية جديدة.' : 'Sorry! Only Admin can create new roles.');
      return;
    }
    this.newRoleName = '';
    this.newRoleDescriptionAr = '';
    this.showCreateRoleModal.set(true);
  }

  public handleCreateRole(e: Event) {
    e.preventDefault();
    if (!this.newRoleName.trim()) return;

    this.isCreatingRole.set(true);
    this.apiService.createRole({
      name: this.newRoleName.trim(),
      description_ar: this.newRoleDescriptionAr.trim() || this.newRoleName.trim(),
      description_en: this.newRoleName.trim()
    }).subscribe({
      next: (res: any) => {
        this.isCreatingRole.set(false);
        this.showCreateRoleModal.set(false);
        this.successMessage.set(this.lang === 'ar' ? `تم إضافة الدور الوظيفي الجديد (${this.newRoleName}) بنجاح!` : `New role (${this.newRoleName}) created successfully!`);
        this.loadRoles();
        setTimeout(() => this.successMessage.set(''), 4000);
      },
      error: (err: any) => {
        this.isCreatingRole.set(false);
        this.errorMessage.set(err?.error?.message || (this.lang === 'ar' ? 'فشل إنشاء الدور الجديد' : 'Failed to create role'));
      }
    });
  }

  public openProgressModal(emp: any) {
    this.selectedEmployeeForProgress.set(emp);
    this.showProgressModal.set(true);
  }

  public closeProgressModal() {
    this.showProgressModal.set(false);
    this.selectedEmployeeForProgress.set(null);
  }

  // Permissions grouped by category for UI display
  public readonly permGroups: Array<{ labelAr: string; labelEn: string; icon: string; color: string; perms: string[] }> = [
    { labelAr: 'المهام', labelEn: 'Tasks', icon: 'fa-list-check', color: 'text-violet-600 bg-violet-50',
      perms: ['view tasks', 'create tasks', 'edit tasks', 'delete tasks', 'assign tasks'] },
    { labelAr: 'الأجهزة', labelEn: 'Devices', icon: 'fa-stethoscope', color: 'text-sky-600 bg-sky-50',
      perms: ['view devices', 'create devices', 'edit devices', 'delete devices'] },
    { labelAr: 'تقارير الصيانة', labelEn: 'Maintenance Reports', icon: 'fa-file-waveform', color: 'text-teal-600 bg-teal-50',
      perms: ['view maintenance_reports', 'create maintenance_reports', 'edit maintenance_reports', 'delete maintenance_reports'] },
    { labelAr: 'جداول الصيانة', labelEn: 'Maintenance Schedules', icon: 'fa-calendar-check', color: 'text-blue-600 bg-blue-50',
      perms: ['view maintenance_schedules', 'create maintenance_schedules', 'edit maintenance_schedules', 'delete maintenance_schedules'] },
    { labelAr: 'المخزون', labelEn: 'Stock Items', icon: 'fa-warehouse', color: 'text-amber-600 bg-amber-50',
      perms: ['view stock_items', 'create stock_items', 'edit stock_items', 'delete stock_items'] },
    { labelAr: 'المنتجات', labelEn: 'Products', icon: 'fa-boxes-stacked', color: 'text-emerald-600 bg-emerald-50',
      perms: ['view products', 'create products', 'edit products', 'delete products'] },
    { labelAr: 'عروض الأسعار', labelEn: 'Quotations', icon: 'fa-file-invoice', color: 'text-rose-600 bg-rose-50',
      perms: ['view quotations', 'create quotations', 'edit quotations', 'delete quotations'] },
    { labelAr: 'الشؤون المالية', labelEn: 'Financials', icon: 'fa-coins', color: 'text-yellow-600 bg-yellow-50',
      perms: ['view financials', 'manage financials'] },
    { labelAr: 'إدارة النظام', labelEn: 'System Admin', icon: 'fa-shield-halved', color: 'text-slate-600 bg-slate-100',
      perms: ['manage users', 'manage settings'] },
  ];

  // Role display maps
  public readonly roleColors: Record<string, string> = {
    'Admin':                     'bg-red-100 text-red-800 border-red-200',
    'CEO':                       'bg-purple-100 text-purple-800 border-purple-200',
    'Operations Manager':        'bg-blue-100 text-blue-800 border-blue-200',
    'Service Engineer outdoor':  'bg-emerald-100 text-emerald-800 border-emerald-200',
    'Service Engineer indoor':   'bg-amber-100 text-amber-800 border-amber-200',
    'Accountant':                'bg-rose-100 text-rose-800 border-rose-200',
    'Sale':                      'bg-teal-100 text-teal-800 border-teal-200',
  };

  public readonly roleIcons: Record<string, string> = {
    'Admin':                     'fa-user-shield',
    'CEO':                       'fa-crown',
    'Operations Manager':        'fa-diagram-project',
    'Service Engineer outdoor':  'fa-screwdriver-wrench',
    'Service Engineer indoor':   'fa-gear',
    'Accountant':                'fa-calculator',
    'Sale':                      'fa-cart-shopping',
  };

  public get lang() { return this.langService.currentLang(); }

  ngOnInit() {
    this.loadEmployees();
    this.loadRoles();
  }

  // ─── Employee CRUD ───

  public loadEmployees() {
    this.isLoading.set(true);
    this.apiService.getEmployees().subscribe({
      next: (res: any) => {
        this.employees.set(res || []);
        this.applyFilter();
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error('Failed to load employees', err);
        this.isLoading.set(false);
      }
    });
  }

  public loadRoles() {
    this.apiService.getRoles().subscribe({
      next: (res: any[]) => {
        this.roles.set(res.map((r: any) => r.name));
      },
      error: () => {
        this.roles.set(['Admin', 'CEO', 'Operations Manager', 'Service Engineer outdoor', 'Service Engineer indoor', 'Accountant', 'Sale']);
      }
    });
  }

  public applyFilter() {
    let list = this.employees();
    if (this.searchText.trim()) {
      const q = this.searchText.toLowerCase();
      list = list.filter(e => e.name.toLowerCase().includes(q) || e.email.toLowerCase().includes(q));
    }
    if (this.filterRole) {
      list = list.filter(e => e.role === this.filterRole);
    }
    this.filteredEmployees.set(list);
  }

  public exportEmployeesToCSV() {
    const list = this.filteredEmployees();
    let csvContent = 'data:text/csv;charset=utf-8,\uFEFF';
    csvContent += 'ID,Name,Email,Role,Completed Tasks,Active Tasks,Total Tasks\n';
    
    list.forEach(e => {
      csvContent += `"${e.id}","${(e.name || '').replace(/"/g, '""')}","${e.email}","${e.role}","${e.completed_tasks_count || 0}","${e.active_tasks_count || 0}","${e.tasks_count || 0}"\n`;
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `employees_report_${new Date().toISOString().slice(0,10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  public openCreateForm() {
    if (!this.isAdmin()) {
      this.errorMessage.set(this.lang === 'ar' ? 'عذراً! مدير النظام (Admin) فقط هو المصرح له بإنشاء حسابات الموظفين الجديدة.' : 'Sorry! Only Admin can create employee accounts.');
      return;
    }
    this.editingEmployee.set(null);
    this.formName = '';
    this.formEmail = '';
    this.formPassword = '';
    this.formRole = this.roles()[0] || 'Service Engineer';
    this.showForm.set(true);
    this.errorMessage.set('');
  }

  public openEditForm(emp: any) {
    this.editingEmployee.set(emp);
    this.formName = emp.name;
    this.formEmail = emp.email;
    this.formPassword = '';
    this.formRole = emp.role;
    this.showForm.set(true);
    this.errorMessage.set('');
  }

  public cancelForm() {
    this.showForm.set(false);
    this.editingEmployee.set(null);
    this.errorMessage.set('');
  }

  public handleSubmit(e: Event) {
    e.preventDefault();
    if (!this.formName.trim() || !this.formEmail.trim() || !this.formRole) {
      this.errorMessage.set(this.lang === 'ar' ? 'يرجى ملء جميع الحقول المطلوبة' : 'Please fill in all required fields');
      return;
    }
    if (!this.editingEmployee() && !this.formPassword.trim()) {
      this.errorMessage.set(this.lang === 'ar' ? 'كلمة المرور مطلوبة للموظفين الجدد' : 'Password is required for new employees');
      return;
    }
    this.isLoading.set(true);
    this.errorMessage.set('');
    const editing = this.editingEmployee();
    if (editing) {
      const payload: any = { name: this.formName, email: this.formEmail, role: this.formRole };
      if (this.formPassword.trim()) payload.password = this.formPassword;
      this.apiService.updateEmployee(editing.id, payload).subscribe({
        next: () => {
          this.successMessage.set(this.lang === 'ar' ? 'تم تحديث بيانات الموظف بنجاح' : 'Employee updated successfully');
          this.showForm.set(false);
          this.loadEmployees();
          this.isLoading.set(false);
          setTimeout(() => this.successMessage.set(''), 3500);
        },
        error: (err) => {
          this.errorMessage.set(err?.error?.message || (this.lang === 'ar' ? 'فشل التحديث' : 'Update failed.'));
          this.isLoading.set(false);
        }
      });
    } else {
      this.apiService.createEmployee({ name: this.formName, email: this.formEmail, password: this.formPassword, role: this.formRole }).subscribe({
        next: () => {
          this.successMessage.set(this.lang === 'ar' ? 'تم إضافة الموظف بنجاح' : 'Employee added successfully');
          this.showForm.set(false);
          this.loadEmployees();
          this.isLoading.set(false);
          setTimeout(() => this.successMessage.set(''), 3500);
        },
        error: (err) => {
          this.errorMessage.set(err?.error?.message || (this.lang === 'ar' ? 'فشل إنشاء الموظف.' : 'Failed to create employee.'));
          this.isLoading.set(false);
        }
      });
    }
  }

  public handleDelete(emp: any) {
    const msg = this.lang === 'ar'
      ? `هل أنت متأكد من حذف الموظف "${emp.name}"؟`
      : `Are you sure you want to delete "${emp.name}"?`;
    if (confirm(msg)) {
      this.apiService.deleteEmployee(emp.id).subscribe({
        next: () => {
          this.successMessage.set(this.lang === 'ar' ? 'تم حذف الموظف بنجاح' : 'Employee deleted successfully');
          this.loadEmployees();
          setTimeout(() => this.successMessage.set(''), 3000);
        },
        error: (err) => console.error('Delete failed', err)
      });
    }
  }

  // ─── Permissions Modal ───

  public openPermissionsModal(emp: any) {
    // If same employee clicked again, just close (toggle)
    if (this.showPermissionsModal() && this.permissionsEmployee()?.id === emp.id) {
      this.closePermissionsModal();
      return;
    }
    this.permissionsEmployee.set(emp);
    this.showPermissionsModal.set(true);
    this.permLoading.set(true);
    this.permSuccess.set('');
    this.apiService.getEmployeePermissions(emp.id).subscribe({
      next: (res) => {
        this.allPermissions.set(res.all || []);
        this.rolePermissions.set(res.role || []);
        this.directPermissions.set([...(res.direct || [])]);
        this.permLoading.set(false);
        // Smooth-scroll to the permissions section
        setTimeout(() => {
          document.getElementById('permissions-inline-section')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }, 80);
      },
      error: () => { this.permLoading.set(false); }
    });
  }


  public closePermissionsModal() {
    this.showPermissionsModal.set(false);
    this.permissionsEmployee.set(null);
    this.directPermissions.set([]);
    this.rolePermissions.set([]);
    this.permSuccess.set('');
  }

  public isDirectPerm(name: string): boolean {
    return this.directPermissions().includes(name);
  }

  public isRolePerm(name: string): boolean {
    return this.rolePermissions().includes(name);
  }

  /** Returns true if permission is granted (either via role or directly) */
  public isEffectivePerm(name: string): boolean {
    return this.isRolePerm(name) || this.isDirectPerm(name);
  }

  public toggleDirectPerm(name: string) {
    if (this.isRolePerm(name)) return; // role perms cannot be unchecked
    const current = this.directPermissions();
    if (current.includes(name)) {
      this.directPermissions.set(current.filter(p => p !== name));
    } else {
      this.directPermissions.set([...current, name]);
    }
  }

  public savePermissions() {
    const emp = this.permissionsEmployee();
    if (!emp) return;
    this.permSaving.set(true);
    this.apiService.syncEmployeePermissions(emp.id, this.directPermissions()).subscribe({
      next: () => {
        this.permSaving.set(false);
        this.permSuccess.set(this.lang === 'ar' ? '✓ تم حفظ الصلاحيات الإضافية بنجاح!' : '✓ Extra permissions saved successfully!');
        setTimeout(() => { this.permSuccess.set(''); this.closePermissionsModal(); }, 2200);
      },
      error: () => { this.permSaving.set(false); }
    });
  }

  public countDirectPerms(): number {
    return this.directPermissions().filter(p => !this.isRolePerm(p)).length;
  }

  // ─── Display Helpers ───

  public getRoleColor(role: string): string {
    return this.roleColors[role] || 'bg-slate-100 text-slate-700 border-slate-200';
  }

  public getRoleIcon(role: string): string {
    return this.roleIcons[role] || 'fa-user';
  }

  public getInitials(name: string): string {
    return name.split(' ').slice(0, 2).map(w => w[0]?.toUpperCase() || '').join('');
  }

  public getAvatarGradient(id: number): string {
    const gradients = [
      'from-violet-500 to-purple-700',
      'from-blue-500 to-indigo-700',
      'from-emerald-500 to-teal-700',
      'from-amber-500 to-orange-600',
      'from-rose-500 to-pink-700',
      'from-sky-500 to-blue-700',
      'from-teal-500 to-emerald-600',
    ];
    return gradients[id % gradients.length];
  }

  public countByRole(role: string): number {
    return this.employees().filter(e => e.role === role).length;
  }

  /** Format permission name for display */
  public formatPermName(perm: string): string {
    return perm.replace(/_/g, ' ')
               .replace(/\b\w/g, c => c.toUpperCase());
  }
}
