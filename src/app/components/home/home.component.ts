import { Component, inject, signal, ViewChild, ElementRef, OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../services/language.service';
import { ApiService, Product, Category, Brand } from '../../services/api.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './home.component.html'
})
export class HomeComponent implements OnInit, OnDestroy, AfterViewInit {
  public langService = inject(LanguageService);
  public apiService = inject(ApiService);
  private router = inject(Router);

  @ViewChild('brandsContainer') brandsContainer!: ElementRef<HTMLDivElement>;
  @ViewChild('productsContainer') productsContainer!: ElementRef<HTMLDivElement>;
  private autoScrollInterval: any = null;
  private autoScrollProductsInterval: any = null;

  // Data Signals
  public featuredProducts = signal<Product[]>([]);
  public categories = signal<Category[]>([]);
  public brands = signal<Brand[]>([]);

  ngOnInit() {
    this.startAutoScroll();
    this.startAutoScrollProducts();
  }

  ngAfterViewInit() {
    this.startAutoScroll();
    this.startAutoScrollProducts();
  }

  ngOnDestroy() {
    this.stopAutoScroll();
    this.stopAutoScrollProducts();
  }

  private doScroll(container: HTMLElement, delta: number) {
    if (!container) return;
    if (typeof container.scrollBy === 'function') {
      try {
        container.scrollBy({ left: delta, behavior: 'smooth' });
        return;
      } catch (e) {}
    }
    if ('scrollLeft' in container) {
      container.scrollLeft += delta;
    }
  }

  private doScrollTo(container: HTMLElement, position: number) {
    if (!container) return;
    if (typeof container.scrollTo === 'function') {
      try {
        container.scrollTo({ left: position, behavior: 'smooth' });
        return;
      } catch (e) {}
    }
    if ('scrollLeft' in container) {
      container.scrollLeft = position;
    }
  }

  public startAutoScroll() {
    if (typeof window === 'undefined') return;
    if (this.autoScrollInterval) return;
    this.autoScrollInterval = setInterval(() => {
      if (!this.brandsContainer || !this.brandsContainer.nativeElement) return;
      const container = this.brandsContainer.nativeElement;
      const maxScroll = (container.scrollWidth || 0) - (container.clientWidth || 0);
      if (maxScroll <= 0) return;
      
      const isRtl = this.langService.currentLang() === 'ar';
      const scrollStep = 300;
      const currentPos = Math.abs(container.scrollLeft || 0);

      if (currentPos >= maxScroll - 30) {
        this.doScrollTo(container, 0);
      } else {
        this.doScroll(container, isRtl ? -scrollStep : scrollStep);
      }
    }, 3000);
  }

  public stopAutoScroll() {
    if (this.autoScrollInterval) {
      clearInterval(this.autoScrollInterval);
      this.autoScrollInterval = null;
    }
  }

  public scrollBrands(direction: 'left' | 'right') {
    if (!this.brandsContainer || !this.brandsContainer.nativeElement) return;
    const container = this.brandsContainer.nativeElement;
    const scrollAmount = 320;
    const sign = direction === 'right' ? 1 : -1;
    this.doScroll(container, sign * scrollAmount);
  }

  public startAutoScrollProducts() {
    if (typeof window === 'undefined') return;
    if (this.autoScrollProductsInterval) return;
    this.autoScrollProductsInterval = setInterval(() => {
      if (!this.productsContainer || !this.productsContainer.nativeElement) return;
      const container = this.productsContainer.nativeElement;
      const maxScroll = (container.scrollWidth || 0) - (container.clientWidth || 0);
      if (maxScroll <= 0) return;
      
      const isRtl = this.langService.currentLang() === 'ar';
      const scrollStep = 360;
      const currentPos = Math.abs(container.scrollLeft || 0);

      if (currentPos >= maxScroll - 30) {
        this.doScrollTo(container, 0);
      } else {
        this.doScroll(container, isRtl ? -scrollStep : scrollStep);
      }
    }, 3500);
  }

  public stopAutoScrollProducts() {
    if (this.autoScrollProductsInterval) {
      clearInterval(this.autoScrollProductsInterval);
      this.autoScrollProductsInterval = null;
    }
  }

  public scrollProducts(direction: 'left' | 'right') {
    if (!this.productsContainer || !this.productsContainer.nativeElement) return;
    const container = this.productsContainer.nativeElement;
    const scrollAmount = 360;
    const sign = direction === 'right' ? 1 : -1;
    this.doScroll(container, sign * scrollAmount);
  }

  // Maintenance Form Fields
  public formName = '';
  public formPhone = '';
  public formGov = '';
  public formPlace = '';
  public formAddress = '';
  public formDeviceName = '';
  public formDeviceModel = '';
  public formProblemDesc = '';

  // Alert State
  public showSuccessAlert = signal<boolean>(false);
  public successMessage = signal<string>('');

  constructor() {
    this.loadData();
  }

  private loadData() {
    this.apiService.getProducts().subscribe(prods => {
      const list = Array.isArray(prods) ? prods : ((prods as any)?.data || []);
      this.featuredProducts.set(list.slice(0, 6));
    });
    this.apiService.getCategories().subscribe(cats => {
      const list = Array.isArray(cats) ? cats : ((cats as any)?.data || []);
      this.categories.set(list);
    });
    this.apiService.getBrands().subscribe(brands => {
      const list = Array.isArray(brands) ? brands : ((brands as any)?.data || []);
      this.brands.set(list);
    });
  }

  public getAvgRating(productId: number): number {
    const prod = this.featuredProducts().find(p => p.id === productId);
    return prod?.average_rating ?? 5;
  }

  public getApprovedReviewsCount(productId: number): number {
    const prod = this.featuredProducts().find(p => p.id === productId);
    return prod?.reviews_count ?? 0;
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public getBrandName(brandId?: number): string {
    if (!brandId) return '';
    const brand = this.brands().find(b => b.id === brandId);
    return brand ? brand.name[this.getLocale()] : '';
  }

  public getCategoryName(categoryId?: number): string {
    if (!categoryId) return '';
    const cat = this.categories().find(c => c.id === categoryId);
    return cat ? cat.name[this.getLocale()] : '';
  }

  public submitMaintenance(event: Event) {
    event.preventDefault();

    this.apiService.submitContact({
      name: this.formName,
      email: 'maintenance@visionmedical.local',
      phone: this.formPhone,
      subject: `طلب صيانة جهاز: ${this.formDeviceName} - ${this.formDeviceModel}`,
      message: `المحافظة: ${this.formGov}\nالمنطقة: ${this.formPlace}\nالعنوان: ${this.formAddress}\nوصف المشكلة: ${this.formProblemDesc}`
    }).subscribe(() => {
      this.successMessage.set(
        this.getLocale() === 'ar'
          ? 'تم تقديم طلب الصيانة بنجاح! سيتواصل معك أحد مهندسينا في أقرب وقت.'
          : 'Maintenance request submitted successfully! Our team will contact you shortly.'
      );
      this.showSuccessAlert.set(true);

      // Reset fields
      this.formName = '';
      this.formPhone = '';
      this.formGov = '';
      this.formPlace = '';
      this.formAddress = '';
      this.formDeviceName = '';
      this.formDeviceModel = '';
      this.formProblemDesc = '';

      // Hide alert after 5 seconds
      setTimeout(() => {
        this.showSuccessAlert.set(false);
      }, 5000);
    });
  }
}
