import { Component, inject, signal, model, OnInit, effect, untracked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../../services/language.service';
import { ApiService, Area, Product, Category, Brand } from '../../../services/api.service';
import { TasksComponent } from '../tasks/tasks.component';
import { EmployeeFollowupComponent } from '../employee-followup/employee-followup.component';
import { EmployeesComponent } from '../employees/employees.component';
import { ToastService } from '../../../services/toast.service';

@Component({
  selector: 'app-manager-view',
  standalone: true,
  imports: [CommonModule, FormsModule, TasksComponent, EmployeeFollowupComponent, EmployeesComponent],
  templateUrl: './manager-view.component.html'
})
export class ManagerViewComponent implements OnInit {
  public langService = inject(LanguageService);
  public apiService = inject(ApiService);
  private toastService = inject(ToastService);

  public activeSubTab = model<string>('products');

  // Area Tab filter: 'governorate' | 'city' | 'town'
  public areaFilterType = signal<'governorate' | 'city' | 'town'>('governorate');
  public areas = signal<Area[]>([]);
  public products = signal<Product[]>([]);
  public categories = signal<Category[]>([]);
  public brands = signal<Brand[]>([]);
  public isLoadingAreas = signal<boolean>(false);

  // New Area Form state
  public showAddAreaModal = signal<boolean>(false);
  public newArea = { name: '', type: 'city', parentId: null as number | null };

  // Edit Area Form state
  public showEditAreaModal = signal<boolean>(false);
  public editArea = { id: 0, name: '', type: 'city', parentId: null as number | null };

  constructor() {
    effect(() => {
      const tab = this.activeSubTab();
      untracked(() => {
        this.loadActiveTabData();
      });
    });
  }

  ngOnInit() {
    this.loadActiveTabData();
  }

  public loadActiveTabData() {
    const tab = this.activeSubTab();
    if (tab === 'areas' && this.areas().length === 0) {
      this.loadAreas();
    } else if (tab === 'products' && this.products().length === 0) {
      this.loadProducts();
    } else if (tab === 'categories' && this.categories().length === 0) {
      this.loadCategories();
    } else if (tab === 'brands' && this.brands().length === 0) {
      this.loadBrands();
    }
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public loadProducts() {
    this.apiService.getProducts().subscribe({
      next: prods => this.products.set(prods || []),
      error: () => {}
    });
  }

  public loadCategories() {
    this.apiService.getCategories().subscribe({
      next: cats => this.categories.set(cats || []),
      error: () => {}
    });
  }

  public loadBrands() {
    this.apiService.getBrands().subscribe({
      next: b => this.brands.set(b || []),
      error: () => {}
    });
  }

  public loadAreas() {
    this.isLoadingAreas.set(true);
    this.apiService.getAreas(1, 1000).subscribe({
      next: (res: any) => {
        const list = res.data || res || [];
        this.areas.set(list);
        this.isLoadingAreas.set(false);
      },
      error: () => this.isLoadingAreas.set(false)
    });
  }

  public getGovernoratesList() {
    return this.areas().filter(a => a.type === 'governorate');
  }

  public getCitiesList() {
    return this.areas().filter(a => a.type === 'city');
  }

  public getTownsAndVillagesList() {
    return this.areas().filter(a => a.type === 'town' || a.type === 'village' || a.type === 'center');
  }

  public getAreaName(area: any): string {
    if (!area) return '';
    if (typeof area.name === 'string') return area.name;
    return area.name?.ar || area.name?.en || '';
  }

  public handleAddArea() {
    if (!this.newArea.name.trim()) {
      alert(this.getLocale() === 'ar' ? 'الرجاء إدخال اسم المنطقة' : 'Please enter area name');
      return;
    }
    const payload = {
      name: this.newArea.name,
      type: this.newArea.type,
      parent_id: this.newArea.parentId
    };

    this.apiService.createArea(payload).subscribe({
      next: () => {
        this.loadAreas();
        this.showAddAreaModal.set(false);
        this.newArea = { name: '', type: 'city', parentId: null };
        this.toastService.success({ ar: 'تمت إضافة المنطقة بنجاح', en: 'Area added successfully' });
      }
    });
  }

  public startEditArea(area: Area) {
    this.editArea = {
      id: area.id,
      name: this.getAreaName(area),
      type: area.type,
      parentId: area.parent_id || null
    };
    this.showEditAreaModal.set(true);
  }

  public handleUpdateArea() {
    if (!this.editArea.name.trim()) return;
    const payload = {
      name: this.editArea.name,
      type: this.editArea.type,
      parent_id: this.editArea.parentId
    };

    this.apiService.updateArea(this.editArea.id, payload).subscribe({
      next: () => {
        this.loadAreas();
        this.showEditAreaModal.set(false);
        this.toastService.success({ ar: 'تم تحديث المنطقة بنجاح', en: 'Area updated successfully' });
      }
    });
  }

  // Product filters
  public productSearchQuery = signal<string>('');
  public productCategoryFilter = signal<string>('all');
  public productBrandFilter = signal<string>('all');

  // Area search filter
  public areaSearchQuery = signal<string>('');

  public getFilteredProducts(): Product[] {
    let list = this.products();
    const cat = this.productCategoryFilter();
    if (cat !== 'all') {
      list = list.filter(p => String(p.category_id) === String(cat) || p.category?.slug === cat);
    }
    const brand = this.productBrandFilter();
    if (brand !== 'all') {
      list = list.filter(p => String(p.brand_id) === String(brand) || p.brand?.slug === brand);
    }
    const q = this.productSearchQuery().toLowerCase().trim();
    if (q) {
      list = list.filter(p => {
        const name = typeof p.name === 'object' ? (p.name.ar || p.name.en || '') : String(p.name || '');
        const sku = ((p as any).sku || '').toLowerCase();
        return name.toLowerCase().includes(q) || sku.includes(q);
      });
    }
    return list;
  }

  // Export / Import Helpers
  public exportProducts() {
    this.apiService.exportProducts().subscribe({
      next: (blob) => this.downloadFile(blob, 'products.xlsx', 'http://localhost:8000/api/products/export'),
      error: () => window.open('http://localhost:8000/api/products/export', '_blank')
    });
  }

  public importProducts(event: Event) {
    const file = this.getFileFromEvent(event);
    if (!file) return;
    this.apiService.importProducts(file).subscribe({
      next: (res: any) => {
        this.toastService.success({ ar: res.message || 'تم استيراد المنتجات بنجاح', en: 'Products imported' });
        this.loadProducts();
      },
      error: (err: any) => this.toastService.error({ ar: err.error?.message || 'فشل استيراد المنتجات', en: 'Import failed' })
    });
  }

  public exportCategories() {
    this.apiService.exportCategories().subscribe({
      next: (blob) => this.downloadFile(blob, 'categories.xlsx', 'http://localhost:8000/api/categories/export'),
      error: () => window.open('http://localhost:8000/api/categories/export', '_blank')
    });
  }

  public importCategories(event: Event) {
    const file = this.getFileFromEvent(event);
    if (!file) return;
    this.apiService.importCategories(file).subscribe({
      next: (res: any) => {
        this.toastService.success({ ar: res.message || 'تم استيراد التصنيفات بنجاح', en: 'Categories imported' });
        this.loadCategories();
      },
      error: (err: any) => this.toastService.error({ ar: err.error?.message || 'فشل استيراد التصنيفات', en: 'Import failed' })
    });
  }

  public exportBrands() {
    this.apiService.exportBrands().subscribe({
      next: (blob) => this.downloadFile(blob, 'brands.xlsx', 'http://localhost:8000/api/brands/export'),
      error: () => window.open('http://localhost:8000/api/brands/export', '_blank')
    });
  }

  public importBrands(event: Event) {
    const file = this.getFileFromEvent(event);
    if (!file) return;
    this.apiService.importBrands(file).subscribe({
      next: (res: any) => {
        this.toastService.success({ ar: res.message || 'تم استيراد العلامات التجارية بنجاح', en: 'Brands imported' });
        this.loadBrands();
      },
      error: (err: any) => this.toastService.error({ ar: err.error?.message || 'فشل استيراد العلامات التجارية', en: 'Import failed' })
    });
  }

  public exportAreas() {
    this.apiService.exportAreas().subscribe({
      next: (blob) => this.downloadFile(blob, 'areas.xlsx', 'http://localhost:8000/api/areas/export'),
      error: () => window.open('http://localhost:8000/api/areas/export', '_blank')
    });
  }

  public importAreas(event: Event) {
    const file = this.getFileFromEvent(event);
    if (!file) return;
    this.apiService.importAreas(file).subscribe({
      next: (res: any) => {
        this.toastService.success({ ar: res.message || 'تم استيراد المناطق بنجاح', en: 'Areas imported' });
        this.loadAreas();
      },
      error: (err: any) => this.toastService.error({ ar: err.error?.message || 'فشل استيراد المناطق', en: 'Import failed' })
    });
  }

  private downloadFile(blob: Blob, filename: string, fallbackUrl: string) {
    if (!blob || blob.size === 0) {
      window.open(fallbackUrl, '_blank');
      return;
    }
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    setTimeout(() => {
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
    }, 300);
    this.toastService.success({ ar: 'تم تنزيل الملف بنجاح', en: 'File downloaded successfully' });
  }

  public handleDeleteArea(id: number) {
    if (confirm(this.getLocale() === 'ar' ? 'هل أنت تأكد من حذف هذه المنطقة؟' : 'Delete this area?')) {
      this.apiService.deleteArea(id).subscribe({
        next: () => {
          this.loadAreas();
          this.toastService.success({ ar: 'تم حذف المنطقة بنجاح', en: 'Area deleted successfully' });
        }
      });
    }
  }

  private getFileFromEvent(event: Event): File | null {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      const file = input.files[0];
      input.value = '';
      return file;
    }
    return null;
  }
}
