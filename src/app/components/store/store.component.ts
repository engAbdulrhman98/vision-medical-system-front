import { Component, inject, signal, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../services/language.service';
import { ApiService, Product, Category, Brand } from '../../services/api.service';

@Component({
  selector: 'app-store',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './store.component.html'
})
export class StoreComponent {
  public langService = inject(LanguageService);
  private apiService = inject(ApiService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  // Data Signals
  public products = signal<Product[]>([]);
  public categories = signal<Category[]>([]);
  public brands = signal<Brand[]>([]);

  // Filter params
  public activeSearch = signal<string>('');
  public activeCategory = signal<string>('');
  public activeBrand = signal<string>('');

  // Mobile menu toggle
  public isMobileFilterOpen = signal<boolean>(false);

  // Search input binding
  public searchInput = '';

  constructor() {
    // Listen to query parameters to filter products dynamically
    this.route.queryParams.subscribe(params => {
      const search = params['search'] || '';
      const category = params['category'] || '';
      const brand = params['brand'] || '';

      this.activeSearch.set(search);
      this.activeCategory.set(category);
      this.activeBrand.set(brand);
      this.searchInput = search;

      this.loadProducts();
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

  private loadProducts() {
    this.apiService.getProducts(
      this.activeSearch(),
      this.activeCategory(),
      this.activeBrand()
    ).subscribe(list => {
      const prodList = Array.isArray(list) ? list : ((list as any)?.data || []);
      this.products.set(prodList);
    });
  }

  public getAvgRating(productId: number): number {
    return this.apiService.getAverageRating(productId);
  }

  public getApprovedReviewsCount(productId: number): number {
    return this.apiService.getReviewsForProduct(productId, true).length;
  }

  public handleSearch(event: Event) {
    event.preventDefault();
    this.updateFilters({ search: this.searchInput });
  }

  public selectCategory(slug: string) {
    this.updateFilters({ category: slug });
  }

  public selectBrand(slug: string) {
    this.updateFilters({ brand: slug });
  }

  public clearFilters() {
    this.router.navigate(['/store'], { queryParams: {} });
  }

  public removeFilter(type: 'search' | 'category' | 'brand') {
    const params = { ...this.route.snapshot.queryParams };
    delete params[type];
    this.router.navigate(['/store'], { queryParams: params });
  }

  private updateFilters(newParams: { [key: string]: string }) {
    const currentParams = { ...this.route.snapshot.queryParams };
    const merged = { ...currentParams, ...newParams };
    
    // Clean empty values
    Object.keys(merged).forEach(key => {
      if (!merged[key]) delete merged[key];
    });

    this.router.navigate(['/store'], { queryParams: merged });
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public getActiveCategoryName(): string {
    const slug = this.activeCategory();
    const cat = this.categories().find(c => c.slug === slug);
    return cat ? cat.name[this.getLocale()] : slug;
  }

  public getActiveBrandName(): string {
    const slug = this.activeBrand();
    const brand = this.brands().find(b => b.slug === slug);
    return brand ? brand.name[this.getLocale()] : slug;
  }

  public toggleMobileFilter() {
    this.isMobileFilterOpen.update(val => !val);
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
}
