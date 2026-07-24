import { Component, inject, signal, model, OnInit, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../../services/language.service';
import { ApiService, Client, Area } from '../../../services/api.service';
import { TasksComponent } from '../tasks/tasks.component';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-seller-view',
  standalone: true,
  imports: [CommonModule, FormsModule, TasksComponent],
  templateUrl: './seller-view.component.html'
})
export class SellerViewComponent implements OnInit {
  public langService = inject(LanguageService);
  public apiService = inject(ApiService);
  private toastService = inject(ToastService);

  public activeSubTab = model<string>('clients');

  constructor() {
    effect(() => {
      const tab = this.activeSubTab();
      if (tab === 'clients' && this.clients().length === 0) {
        this.loadClients();
      }
    });
  }

  // State Signals
  public clients = signal<Client[]>([]);
  public areas = signal<Area[]>([]);
  public governorates = signal<Area[]>([]);
  public cities = signal<Area[]>([]);
  public isLoading = signal<boolean>(false);
  public searchQuery = signal<string>('');

  // Add Client Form Modal
  public showAddClientModal = signal<boolean>(false);
  public newClient = {
    name: '',
    type: 'غير محدد',
    phone: '',
    governorate_id: 0,
    city_id: 0,
    detailed_address: '',
    notes: ''
  };

  // Edit Client Form Modal State
  public showEditClientModal = signal<boolean>(false);
  public editingClientId = signal<number | null>(null);
  public editClient = {
    name: '',
    type: 'Hospital',
    phone: '',
    governorate_id: 0,
    city_id: 0,
    detailed_address: '',
    notes: ''
  };
  public editCities = signal<Area[]>([]);

  // Client Address Modal State
  public selectedClientForAddress = signal<any | null>(null);
  public showAddressModal = signal<boolean>(false);

  // Client Contact Person Modal State
  public selectedClientForContacts = signal<any | null>(null);
  public showContactsModal = signal<boolean>(false);
  public clientContacts = signal<any[]>([]);
  public newContact = { name: '', phone: '', job_title: '' };

  ngOnInit() {
    this.loadClients();
    this.loadAreas();
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public loadClients() {
    this.isLoading.set(true);
    this.apiService.getClients(1, 1000).subscribe({
      next: (res: any) => {
        const list = res.data || res || [];
        this.clients.set(list);
        this.isLoading.set(false);
      },
      error: () => this.isLoading.set(false)
    });
  }

  public loadAreas() {
    this.apiService.getAreas(1, 1000).subscribe({
      next: (res: any) => {
        const list = res.data || res || [];
        this.areas.set(list);
        this.governorates.set(list.filter((a: any) => a.type === 'governorate'));
      }
    });
  }

  public onGovernorateChange() {
    this.newClient.city_id = 0;
    if (!this.newClient.governorate_id) {
      this.cities.set([]);
      return;
    }
    const filtered = this.areas().filter((a: any) => a.type === 'city' && a.parent_id === +this.newClient.governorate_id);
    this.cities.set(filtered);
  }

  public getAreaNameString(gov: any): string {
    if (!gov || !gov.name) return '';
    if (typeof gov.name === 'string') return gov.name;
    return gov.name[this.getLocale()] || gov.name.ar || gov.name.en || '';
  }

  public getClientName(name: any): string {
    if (!name) return '';
    if (typeof name === 'string') return name;
    if (typeof name === 'object') {
      const loc = this.getLocale();
      return name[loc] || name.ar || name.en || Object.values(name)[0] || '';
    }
    return String(name);
  }

  public getClientTypeAr(type?: string): string {
    if (!type || type === 'غير محدد') return 'غير محدد';
    const map: Record<string, string> = {
      'Hospital': 'مستشفى',
      'Clinic': 'عيادة',
      'Center': 'مركز طبي',
      'Company': 'شركة / معمل'
    };
    return map[type] || type;
  }

  public filterIncompleteOnly = signal<boolean>(false);
  public selectedGovFilter = signal<string>('all');
  public selectedTypeFilter = signal<string>('all');

  public toggleIncompleteFilter() {
    this.filterIncompleteOnly.set(!this.filterIncompleteOnly());
  }

  public resetClientFilters() {
    this.filterIncompleteOnly.set(false);
    this.searchQuery.set('');
    this.selectedGovFilter.set('all');
    this.selectedTypeFilter.set('all');
  }

  public isIncompleteClient(c: any): boolean {
    const type = this.getClientTypeAr(c.type);
    const gov = c.governorate || 'غير معروف';
    const city = c.city || 'غير معروف';
    const phone = c.phone || 'غير معروف';
    const addr = c.detailed_address || (c as any).address || 'غير معروف';

    return type === 'غير محدد' || gov === 'غير معروف' || city === 'غير معروف' || phone === 'غير معروف' || addr === 'غير معروف';
  }

  public getFilteredClients() {
    let list = this.clients();

    if (this.filterIncompleteOnly()) {
      list = list.filter(c => this.isIncompleteClient(c));
    }

    if (this.selectedGovFilter() !== 'all') {
      const targetGov = this.selectedGovFilter().toLowerCase();
      list = list.filter(c => (c.governorate || '').toLowerCase().includes(targetGov));
    }

    if (this.selectedTypeFilter() !== 'all') {
      list = list.filter(c => c.type === this.selectedTypeFilter());
    }

    const q = this.searchQuery().toLowerCase().trim();
    if (!q) return list;

    return list.filter(c => {
      const name = this.getClientName(c.name).toLowerCase();
      const phone = (c.phone || 'غير معروف').toLowerCase();
      const gov = (c.governorate || 'غير معروف').toLowerCase();
      const city = (c.city || 'غير معروف').toLowerCase();
      const type = this.getClientTypeAr(c.type).toLowerCase();
      const address = (c.detailed_address || (c as any).address || 'غير معروف').toLowerCase();

      return name.includes(q) || phone.includes(q) || gov.includes(q) || city.includes(q) || type.includes(q) || address.includes(q);
    });
  }

  public handleCreateClient() {
    if (!this.newClient.name.trim()) {
      alert(this.getLocale() === 'ar' ? 'الرجاء كتابة اسم العميل / المستشفى' : 'Please enter client name');
      return;
    }

    const govObj = this.governorates().find((g: any) => g.id === Number(this.newClient.governorate_id));
    const cityObj = this.cities().find((c: any) => c.id === Number(this.newClient.city_id));

    const areaId = Number(this.newClient.city_id) > 0 
      ? Number(this.newClient.city_id) 
      : (Number(this.newClient.governorate_id) > 0 ? Number(this.newClient.governorate_id) : null);

    const payload = {
      name: this.newClient.name.trim(),
      type: this.newClient.type || 'غير محدد',
      governorate: govObj ? (typeof govObj.name === 'object' ? (govObj.name as any).ar : String(govObj.name)) : 'غير معروف',
      city: cityObj ? (typeof cityObj.name === 'object' ? (cityObj.name as any).ar : String(cityObj.name)) : 'غير معروف',
      phone: this.newClient.phone?.trim() ? this.newClient.phone.trim() : 'غير معروف',
      area_id: areaId,
      detailed_address: this.newClient.detailed_address?.trim() ? this.newClient.detailed_address.trim() : 'غير معروف',
      notes: this.newClient.notes
    };

    this.apiService.createClient(payload).subscribe({
      next: () => {
        this.loadClients();
        this.showAddClientModal.set(false);
        this.newClient = { name: '', type: 'غير محدد', phone: '', governorate_id: 0, city_id: 0, detailed_address: '', notes: '' };
        this.toastService.success({ ar: 'تم تسجيل العميل بنجاح', en: 'Client registered successfully' });
      }
    });
  }

  public openAddressModal(client: any) {
    this.selectedClientForAddress.set(client);
    this.showAddressModal.set(true);
  }

  public openContactsModal(client: any) {
    this.selectedClientForContacts.set(client);
    this.showContactsModal.set(true);
    this.loadContacts(client.id);
  }

  public loadContacts(clientId: number) {
    this.apiService.getClientContacts(clientId).subscribe({
      next: (res: any) => this.clientContacts.set(res || [])
    });
  }

  public handleAddContact() {
    const client = this.selectedClientForContacts();
    if (!client || !this.newContact.name.trim()) return;

    this.apiService.createClientContact(client.id, this.newContact).subscribe({
      next: () => {
        this.loadContacts(client.id);
        this.newContact = { name: '', phone: '', job_title: '' };
        this.toastService.success({ ar: 'تمت إضافة مسؤول التواصل', en: 'Contact added' });
      }
    });
  }

  public handleDeleteContact(contactId: number) {
    const client = this.selectedClientForContacts();
    if (!client) return;
    this.apiService.deleteClientContact(contactId).subscribe({
      next: () => this.loadContacts(client.id)
    });
  }

  public exportClients() {
    this.apiService.exportClients().subscribe({
      next: (blob: Blob) => {
        if (!blob || blob.size === 0) {
          window.open('http://localhost:8000/api/clients/export', '_blank');
          this.toastService.success({ ar: 'جاري تنزيل ملف العملاء والمسئولين...', en: 'Downloading file...' });
          return;
        }
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = url;
        a.download = 'clients_and_contacts.xlsx';
        document.body.appendChild(a);
        a.click();
        setTimeout(() => {
          document.body.removeChild(a);
          window.URL.revokeObjectURL(url);
        }, 300);
        this.toastService.success({ ar: 'تم تصدير العملاء والمسئولين بنجاح', en: 'Clients & Contacts exported successfully' });
      },
      error: (err: any) => {
        console.error('Export Error:', err);
        window.open('http://localhost:8000/api/clients/export', '_blank');
        this.toastService.success({ ar: 'جاري تنزيل ملف العملاء والمسئولين...', en: 'Downloading file...' });
      }
    });
  }

  public onImportFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      const file = input.files[0];
      this.apiService.importClients(file).subscribe({
        next: (res: any) => {
          this.toastService.success({ ar: res.message || 'تم استيراد العملاء والمسئولين بنجاح', en: 'Import successful' });
          this.loadClients();
          input.value = '';
        },
        error: (err: any) => {
          this.toastService.error({ ar: err.error?.message || 'فشل استيراد البيانات', en: 'Import failed' });
          input.value = '';
        }
      });
    }
  }

  public openEditClientModal(client: any) {
    this.editingClientId.set(client.id);
    const clientName = this.getClientName(client.name);

    let govId = 0;
    let cityId = 0;

    if (client.area_id) {
      const area = this.areas().find((a: any) => a.id === client.area_id);
      if (area) {
        if (area.type === 'city') {
          cityId = area.id;
          govId = area.parent_id || 0;
        } else if (area.type === 'governorate') {
          govId = area.id;
        }
      }
    }

    if (!govId && client.governorate) {
      const govArea = this.governorates().find((a: any) =>
        a.name === client.governorate ||
        a.name?.ar === client.governorate ||
        a.name?.en === client.governorate
      );
      if (govArea) govId = govArea.id;
    }

    if (govId) {
      const filtered = this.areas().filter((a: any) => a.type === 'city' && a.parent_id === +govId);
      this.editCities.set(filtered);
    } else {
      this.editCities.set([]);
    }

    this.editClient = {
      name: clientName,
      type: client.type || 'غير محدد',
      phone: (client.phone === 'غير معروف') ? '' : (client.phone || ''),
      governorate_id: govId,
      city_id: cityId,
      detailed_address: (client.detailed_address === 'غير معروف') ? '' : (client.detailed_address || ''),
      notes: client.notes || ''
    };

    this.showEditClientModal.set(true);
  }

  public onEditGovernorateChange() {
    this.editClient.city_id = 0;
    if (!this.editClient.governorate_id) {
      this.editCities.set([]);
      return;
    }
    const filtered = this.areas().filter((a: any) => a.type === 'city' && +a.parent_id === +this.editClient.governorate_id);
    this.editCities.set(filtered);
  }

  public handleUpdateClient() {
    if (!this.editClient.name.trim() || !this.editingClientId()) {
      alert(this.getLocale() === 'ar' ? 'الرجاء كتابة اسم العميل / المستشفى' : 'Please enter client name');
      return;
    }

    const govObj = this.governorates().find((g: any) => +g.id === +this.editClient.governorate_id);
    const cityObj = this.editCities().find((c: any) => +c.id === +this.editClient.city_id);

    const areaId = Number(this.editClient.city_id) > 0 
      ? Number(this.editClient.city_id) 
      : (Number(this.editClient.governorate_id) > 0 ? Number(this.editClient.governorate_id) : null);

    const govName = govObj ? this.getClientName(govObj.name) : null;
    const cityName = cityObj ? this.getClientName(cityObj.name) : null;

    const payload: any = {
      name: this.editClient.name.trim(),
      type: this.editClient.type || 'غير محدد',
      phone: this.editClient.phone?.trim() ? this.editClient.phone.trim() : 'غير معروف',
      area_id: areaId,
      detailed_address: this.editClient.detailed_address?.trim() ? this.editClient.detailed_address.trim() : 'غير معروف',
      notes: this.editClient.notes
    };

    if (govName) payload.governorate = govName;
    else if (!this.editClient.governorate_id) payload.governorate = 'غير معروف';

    if (cityName) payload.city = cityName;
    else if (!this.editClient.city_id) payload.city = 'غير معروف';

    this.apiService.updateClient(this.editingClientId()!, payload).subscribe({
      next: () => {
        this.loadClients();
        this.showEditClientModal.set(false);
        this.editingClientId.set(null);
        this.toastService.success({ ar: 'تم تحديث بيانات العميل بنجاح', en: 'Client updated successfully' });
      },
      error: (err: any) => {
        console.error('Client update error:', err);
        this.toastService.error({ ar: err.error?.message || 'فشل تحديث العميل', en: 'Failed to update client' });
      }
    });
  }

  public handleDeleteClient(client: any) {
    const clientName = this.getClientName(client.name);
    const confirmMsg = this.getLocale() === 'ar' 
      ? `هل أنت تأكد من رغبتك في حذف العميل "${clientName}"؟`
      : `Are you sure you want to delete client "${clientName}"?`;

    if (confirm(confirmMsg)) {
      this.apiService.deleteClient(client.id).subscribe({
        next: () => {
          this.loadClients();
          this.toastService.success({ ar: 'تم حذف العميل بنجاح', en: 'Client deleted successfully' });
        },
        error: () => {
          this.toastService.error({ ar: 'فشل حذف العميل', en: 'Failed to delete client' });
        }
      });
    }
  }
}
