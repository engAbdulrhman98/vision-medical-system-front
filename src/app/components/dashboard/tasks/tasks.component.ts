import { Component, inject, signal, OnInit, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService, Task } from '../../../services/api.service';
import { LanguageService } from '../../../services/language.service';

@Component({
  selector: 'app-tasks',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './tasks.component.html'
})
export class TasksComponent implements OnInit {
  public apiService = inject(ApiService);
  public langService = inject(LanguageService);

  @Input() role: 'admin' | 'ceo' | 'manager' | 'seller' | 'accountant' = 'admin';
  @Input() taskType: 'all' | 'internal' | 'external' = 'all';

  // State Signals
  public tasks = signal<Task[]>([]);
  public devices = signal<any[]>([]);
  public clients = signal<any[]>([]);
  public technicians = signal<any[]>([]);
  public allAreas = signal<any[]>([]);
  public governorates = signal<any[]>([]);
  public cities = signal<any[]>([]);
  public isLoading = signal<boolean>(false);

  // Follow Up / Task updates timeline state
  public selectedTask = signal<any | null>(null);
  public showFollowUpDrawer = signal<boolean>(false);
  public newFollowUpNote = '';
  public newFollowUpProgress = 0;

  // General Component State
  public showCreateForm = signal<boolean>(false);
  public successMessage = signal<string>('');
  public errorMessage = signal<string>('');

  // Table Filters State
  public filterGovernorateId = signal<number>(0);
  public filterCityId = signal<number>(0);
  public filterClientId = signal<number>(0);
  public filterCities = signal<any[]>([]);

  // Interactive Search & Category Filters State
  public searchQuery = signal<string>('');
  public statusFilter = signal<string>('all');
  public priorityFilter = signal<string>('all');
  public engineerFilter = signal<number>(0);

  public resetTaskFilters() {
    this.searchQuery.set('');
    this.statusFilter.set('all');
    this.priorityFilter.set('all');
    this.engineerFilter.set(0);
    this.filterGovernorateId.set(0);
    this.filterCityId.set(0);
    this.filterClientId.set(0);
  }

  public getFilteredTasks(): Task[] {
    let list = this.tasks();

    if (this.statusFilter() !== 'all') {
      list = list.filter(t => t.status === this.statusFilter());
    }

    if (this.priorityFilter() !== 'all') {
      list = list.filter(t => t.priority === this.priorityFilter());
    }

    if (this.engineerFilter()) {
      list = list.filter(t => t.user_id === Number(this.engineerFilter()));
    }

    const q = this.searchQuery().toLowerCase().trim();
    if (q) {
      list = list.filter(t => {
        const rawClient = (t as any).client_name;
        const title = typeof t.title === 'object' ? ((t.title as any)?.ar || (t.title as any)?.en || '') : String(t.title || '');
        const client = typeof rawClient === 'object' ? (rawClient?.ar || rawClient?.en || '') : String(rawClient || '');
        const eng = ((t as any).engineer_name || '').toLowerCase();
        const desc = (t.description || '').toLowerCase();

        return title.toLowerCase().includes(q) || client.toLowerCase().includes(q) || eng.includes(q) || desc.includes(q);
      });
    }

    return list;
  }

  public exportTasksToCSV() {
    const filtered = this.getFilteredTasks();
    let csvContent = 'data:text/csv;charset=utf-8,\uFEFF';
    csvContent += 'ID,Title,Client,Engineer,Status,Priority,Progress,Scheduled At\n';
    
    filtered.forEach(t => {
      const rawClient = (t as any).client_name;
      const title = typeof t.title === 'object' ? ((t.title as any)?.ar || (t.title as any)?.en || '') : String(t.title || '');
      const client = typeof rawClient === 'object' ? (rawClient?.ar || rawClient?.en || '') : String(rawClient || '');
      const eng = (t as any).engineer_name || '';
      const status = this.translateStatus(t.status);
      const priority = t.priority || 'medium';
      const progress = (t.progress || 0) + '%';
      const date = t.scheduled_at || '';
      
      csvContent += `"${t.id}","${title.replace(/"/g, '""')}","${client.replace(/"/g, '""')}","${eng.replace(/"/g, '""')}","${status}","${priority}","${progress}","${date}"\n`;
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `tasks_export_${new Date().toISOString().slice(0,10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  public translateStatus(status: string): string {
    if (this.getLocale() === 'ar') {
      switch (status) {
        case 'pending': return 'قيد الانتظار';
        case 'in_progress': return 'قيد التنفيذ';
        case 'completed': return 'مكتملة';
        case 'cancelled': return 'ملغاة';
        default: return status;
      }
    }
    return status.replace('_', ' ');
  }

  // Form Fields
  public title = '';
  public description = '';
  public priority = 'medium';
  public taskTypeForm = 'external';
  public deviceId = 0;
  public clientId = 0;
  public governorateId = 0;
  public cityId = 0;
  public userId = 0;
  public scheduledAt = '';

  // Client Contacts State
  public clientContacts = signal<any[]>([]);
  public clientContactId = 0;
  public showNewContactForm = signal<boolean>(false);
  public newContactName = '';
  public newContactPhone = '';
  public newContactJobTitle = '';

  // OTP Verification State
  public showOtpModal = signal<boolean>(false);
  public otpTask = signal<any | null>(null);
  public otpCodeInput = '';
  public otpInfo = signal<any | null>(null);
  public isGeneratingOtp = signal<boolean>(false);
  public isVerifyingOtp = signal<boolean>(false);

  // Field Visit Outcome State
  public showOutcomeModal = signal<boolean>(false);
  public outcomeTask = signal<any | null>(null);
  public selectedOutcome: 'accepted' | 'rejected' = 'accepted';
  public actionTypeOption: 'invoice_request' | 'maintenance_request' = 'invoice_request';
  public rejectionReasonInput = '';
  public outcomeNoteInput = '';

  // Accountant Processing State
  public showAccountantModal = signal<boolean>(false);
  public accountantTask = signal<any | null>(null);
  public accountantNoteInput = '';

  ngOnInit() {
    this.loadTasks();
    this.loadAllAreas();
    this.loadClients();
    this.loadDevices();
    this.loadTechnicians();
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public getAreaName(area: any): string {
    if (!area) return '';
    if (typeof area.name === 'string') return area.name;
    return area.name?.ar || area.name?.en || '';
  }

  public loadTasks() {
    this.isLoading.set(true);
    const filters: any = {};
    if (this.taskType !== 'all') {
      filters.type = this.taskType;
    }
    if (this.filterGovernorateId()) {
      filters.governorate_id = this.filterGovernorateId();
    }
    if (this.filterCityId()) {
      filters.city_id = this.filterCityId();
    }
    if (this.filterClientId()) {
      filters.client_id = this.filterClientId();
    }

    this.apiService.getTasks(filters).subscribe({
      next: (res: any) => {
        this.tasks.set(res || []);
        this.isLoading.set(false);
      },
      error: () => this.isLoading.set(false)
    });
  }

  public loadAllAreas() {
    this.apiService.getAreas(1, 1000).subscribe({
      next: (res: any) => {
        const list = res.data || res || [];
        this.allAreas.set(list);
        const govs = list.filter((a: any) => a.type === 'governorate');
        this.governorates.set(govs);
      }
    });
  }

  public onGovernorateChange() {
    this.cityId = 0;
    this.clientId = 0;
    this.deviceId = 0;
    if (!this.governorateId) {
      this.cities.set([]);
      return;
    }
    const filteredCities = this.allAreas().filter((a: any) => a.type === 'city' && a.parent_id === +this.governorateId);
    this.cities.set(filteredCities);
  }

  public onCityChange() {
    this.clientId = 0;
    this.clientContactId = 0;
    this.clientContacts.set([]);
    this.deviceId = 0;
  }

  public onClientSelectChange() {
    this.clientContactId = 0;
    this.showNewContactForm.set(false);
    if (!this.clientId) {
      this.clientContacts.set([]);
      return;
    }

    const selectedClient = this.clients().find((c: any) => c.id === +this.clientId);
    if (selectedClient && selectedClient.area_id) {
      const clientArea = this.allAreas().find((a: any) => a.id === +selectedClient.area_id);
      if (clientArea) {
        if (clientArea.type === 'city') {
          this.cityId = clientArea.id;
          if (clientArea.parent_id) {
            this.governorateId = clientArea.parent_id;
            this.cities.set(this.allAreas().filter((a: any) => a.type === 'city' && a.parent_id === +clientArea.parent_id));
          }
        } else if (clientArea.type === 'governorate') {
          this.governorateId = clientArea.id;
          this.cityId = 0;
          this.cities.set(this.allAreas().filter((a: any) => a.type === 'city' && a.parent_id === +clientArea.id));
        }
      }
    }

    this.apiService.getClientContacts(+this.clientId).subscribe({
      next: (res: any) => this.clientContacts.set(res || [])
    });
  }

  public getFilteredClients() {
    let list = this.clients();
    if (this.cityId) {
      list = list.filter((c: any) => c.area_id === +this.cityId);
    } else if (this.governorateId) {
      const cityIds = this.allAreas()
        .filter((a: any) => a.type === 'city' && a.parent_id === +this.governorateId)
        .map((a: any) => a.id);
      list = list.filter((c: any) => cityIds.includes(c.area_id) || c.area_id === +this.governorateId);
    }
    return list;
  }

  public loadDevices() {
    this.apiService.getDevices().subscribe({
      next: (res: any) => this.devices.set(res || [])
    });
  }

  public loadClients() {
    this.apiService.getClients().subscribe({
      next: (res: any) => this.clients.set(res || [])
    });
  }

  public getClientName(name: any): string {
    if (!name) return '-';
    if (typeof name === 'string') return name;
    if (typeof name === 'object') {
      const loc = this.getLocale();
      return name[loc] || name.ar || name.en || Object.values(name)[0] || '';
    }
    return String(name);
  }

  public getRoleNameAr(role: string): string {
    switch (role) {
      case 'Field Engineer': return 'مهندس صيانة ميداني 🛠️';
      case 'Sales Representative': return 'مندوب مبيعات 💼';
      case 'Maintenance Engineer': return 'مهندس صيانة داخلية (ورشة) 🏢';
      case 'Accountant': return 'محاسب 📑';
      case 'Operations Manager': return 'مدير عمليات';
      case 'Admin': return 'مدير النظام';
      case 'CEO': return 'المدير التنفيذي';
      default: return role || 'موظف';
    }
  }

  public loadTechnicians() {
    this.apiService.getUsers().subscribe({
      next: (res: any) => {
        const techs = (res || []).filter((u: any) =>
          u.role === 'Operations Manager' ||
          u.role === 'Field Engineer' ||
          u.role === 'Maintenance Engineer' ||
          u.role === 'Sales Representative' ||
          u.role === 'Admin' ||
          u.role === 'CEO'
        );
        this.technicians.set(techs);
      }
    });
  }

  public handleCreateTask(event: Event) {
    event.preventDefault();
    if (!this.title.trim() || !this.clientId || !this.userId || !this.scheduledAt) {
      this.errorMessage.set(this.getLocale() === 'ar' ? 'الرجاء ملء جميع الحقول المطلوبة' : 'Please fill in all required fields');
      return;
    }

    const payload = {
      title_ar: this.title,
      title_en: this.title,
      description: this.description,
      priority: this.priority,
      device_id: this.deviceId || null,
      client_id: this.clientId,
      client_contact_id: this.clientContactId || null,
      governorate_id: this.governorateId || null,
      city_id: this.cityId || null,
      user_id: this.userId,
      scheduled_at: this.scheduledAt,
      type: this.taskTypeForm || this.taskType
    };

    this.isLoading.set(true);
    this.apiService.createTask(payload).subscribe({
      next: () => {
        this.successMessage.set(this.getLocale() === 'ar' ? 'تم إنشاء المهمة وتعيينها بنجاح' : 'Task created and assigned successfully');
        this.title = '';
        this.description = '';
        this.clientId = 0;
        this.userId = 0;
        this.loadTasks();
        this.showCreateForm.set(false);
        this.isLoading.set(false);
        setTimeout(() => this.successMessage.set(''), 3000);
      },
      error: () => this.isLoading.set(false)
    });
  }

  public handleStatusChange(taskId: number, event: any) {
    const status = event.target.value;
    this.apiService.updateTaskStatus(taskId, status).subscribe({
      next: () => this.loadTasks()
    });
  }

  public handleConfirmDelivery(task: any) {
    this.apiService.addTaskUpdate(task.id, {
      note: 'تم تسليم الفاتورة / المستند لمسؤول المستشفى بنجاح وإكمال المهمة بنجاح',
      progress: 100
    }).subscribe({
      next: () => {
        this.successMessage.set(this.getLocale() === 'ar' ? 'تم تأكيد التسليم وإغلاق المهمة كـ مكتملة' : 'Delivery confirmed and task completed');
        this.loadTasks();
        setTimeout(() => this.successMessage.set(''), 3000);
      }
    });
  }

  public openOtpModal(task: any) {
    this.apiService.updateTaskStatus(task.id, 'completed').subscribe({
      next: () => {
        this.successMessage.set(this.getLocale() === 'ar' ? 'تم إكمال المهمة وإغلاق الطلب بنجاح' : 'Task completed successfully');
        this.loadTasks();
        setTimeout(() => this.successMessage.set(''), 3000);
      }
    });
  }

  public handleGenerateOtp(taskId: number) {
    this.isGeneratingOtp.set(true);
    this.apiService.generateTaskOtp(taskId).subscribe({
      next: (res: any) => {
        this.otpInfo.set(res);
        this.isGeneratingOtp.set(false);
      },
      error: () => this.isGeneratingOtp.set(false)
    });
  }

  public handleVerifyOtp() {
    if (!this.otpCodeInput || this.otpCodeInput.length !== 4) return;
    const task = this.otpTask();
    if (!task) return;

    this.isVerifyingOtp.set(true);
    this.apiService.verifyTaskOtp(task.id, this.otpCodeInput).subscribe({
      next: (res: any) => {
        this.isVerifyingOtp.set(false);
        this.showOtpModal.set(false);
        this.successMessage.set(res.message || 'تم التوثيق بنجاح');
        this.loadTasks();
      },
      error: () => this.isVerifyingOtp.set(false)
    });
  }

  public openFollowUpDrawer(task: any) {
    this.selectedTask.set(task);
    this.newFollowUpProgress = task.progress || 0;
    this.newFollowUpNote = '';
    this.showFollowUpDrawer.set(true);
  }

  public handleAddFollowUpNote() {
    const task = this.selectedTask();
    if (!task || !this.newFollowUpNote.trim()) return;

    this.apiService.addTaskUpdate(task.id, {
      note: this.newFollowUpNote,
      progress: this.newFollowUpProgress
    }).subscribe({
      next: () => {
        this.newFollowUpNote = '';
        this.loadTasks();
        this.showFollowUpDrawer.set(false);
      }
    });
  }

  public openOutcomeModal(task: any) {
    this.outcomeTask.set(task);
    this.selectedOutcome = 'accepted';
    this.actionTypeOption = 'invoice_request';
    this.rejectionReasonInput = '';
    this.outcomeNoteInput = '';
    this.showOutcomeModal.set(true);
  }

  public handleSubmitOutcome() {
    const task = this.outcomeTask();
    if (!task) return;

    const payload = {
      outcome: this.selectedOutcome,
      action_type: this.selectedOutcome === 'accepted' ? this.actionTypeOption : null,
      rejection_reason: this.selectedOutcome === 'rejected' ? this.rejectionReasonInput : null,
      note: this.outcomeNoteInput
    };

    this.apiService.submitTaskOutcome(task.id, payload).subscribe({
      next: (res: any) => {
        this.showOutcomeModal.set(false);
        this.successMessage.set(res.message || 'تم تسجيل نتيجة الزيارة بنجاح');
        this.loadTasks();
        setTimeout(() => this.successMessage.set(''), 3000);
      }
    });
  }

  public openAccountantModal(task: any) {
    this.accountantTask.set(task);
    this.accountantNoteInput = '';
    this.showAccountantModal.set(true);
  }

  public handleProcessAccountantAction() {
    const task = this.accountantTask();
    if (!task || !this.accountantNoteInput.trim()) return;

    const payload = {
      accountant_note: this.accountantNoteInput.trim()
    };

    this.apiService.processTaskAccountantAction(task.id, payload).subscribe({
      next: (res: any) => {
        this.showAccountantModal.set(false);
        this.successMessage.set(res.message || 'تم تجهيز الفاتورة / الطلب بنجاح');
        this.loadTasks();
        setTimeout(() => this.successMessage.set(''), 3000);
      }
    });
  }
}
