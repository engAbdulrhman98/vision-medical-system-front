import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../services/language.service';
import { ApiService, Product, Review, Category, Brand } from '../../services/api.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-product',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './product.component.html'
})
export class ProductComponent {
  public langService = inject(LanguageService);
  public apiService = inject(ApiService);
  private route = inject(ActivatedRoute);
  private toastService = inject(ToastService);

  // States
  public product = signal<Product | undefined>(undefined);
  public relatedProducts = signal<Product[]>([]);
  public approvedReviews = signal<Review[]>([]);
  public averageRating = signal<number>(5);
  public whatsappNumber = signal<string>('201001234567');
  public categoriesList = signal<Category[]>([]);
  public brandsList = signal<Brand[]>([]);

  // Review form states
  public reviewerName = '';
  public reviewerRating = '5';
  public reviewerComment = '';

  // Success message
  public showSuccessAlert = signal<boolean>(false);

  constructor() {
    this.route.params.subscribe(params => {
      const slug = params['slug'];
      this.loadProduct(slug);
    });

    this.apiService.getSettings().subscribe(settings => {
      this.whatsappNumber.set(settings.whatsapp);
    });
    this.apiService.getCategories().subscribe(cats => {
      this.categoriesList.set(cats);
    });
    this.apiService.getBrands().subscribe(brands => {
      this.brandsList.set(brands);
    });
  }

  private loadProduct(slug: string) {
    this.apiService.getProductBySlug(slug).subscribe(prod => {
      this.product.set(prod);
      if (prod) {
        this.approvedReviews.set(prod.reviews || []);
        this.averageRating.set(prod.average_rating || 5);

        // Get related products (same category, up to 4 items, excluding current)
        this.apiService.getCategories().subscribe(cats => {
          const catList = Array.isArray(cats) ? cats : ((cats as any)?.data || []);
          const category = catList.find((c: Category) => c.id === prod.category_id);
          if (category) {
            this.apiService.getProducts(undefined, category.slug).subscribe(prods => {
              const prodList = Array.isArray(prods) ? prods : ((prods as any)?.data || []);
              const related = prodList.filter((p: Product) => p.id !== prod.id).slice(0, 4);
              this.relatedProducts.set(related);
            });
          }
        });
      }
    });
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public getWhatsAppOrderUrl(): string {
    const prod = this.product();
    if (!prod) return '';

    const phone = this.whatsappNumber();
    const isAr = this.getLocale() === 'ar';
    
    // Formatting EGP price
    const priceStr = prod.price.toLocaleString('en-US', { minimumFractionDigits: 2 });
    const currentUrl = typeof window !== 'undefined' ? window.location.href : `http://localhost:4200/product/${prod.slug}`;

    const text = isAr 
      ? `مرحباً فيجن ميديكال، أرغب في الاستفسار عن وتأكيد طلب المنتج التالي:\n- المنتج: ${prod.name.ar}\n- السعر: ${priceStr} ج.م\n- الرابط: ${currentUrl}`
      : `Hello Vision Medical, I would like to inquire about and confirm ordering the following product:\n- Product: ${prod.name.en}\n- Price: ${priceStr} EGP\n- Link: ${currentUrl}`;

    return `https://wa.me/${phone}?text=${encodeURIComponent(text)}`;
  }

  public submitReview(event: Event) {
    event.preventDefault();
    const prod = this.product();
    if (!prod) return;

    this.apiService.submitReview(
      prod.id,
      this.reviewerName,
      Number(this.reviewerRating),
      this.reviewerComment
    ).subscribe(() => {
      // Show success alert & toast
      this.showSuccessAlert.set(true);
      this.toastService.success({
        ar: 'تم إرسال تقييمك بنجاح! سيتم نشره بعد المراجعة.',
        en: 'Your review has been submitted successfully! It will be published after approval.'
      });

      // Reset fields
      this.reviewerName = '';
      this.reviewerRating = '5';
      this.reviewerComment = '';

      // Hide alert after 5 seconds
      setTimeout(() => {
        this.showSuccessAlert.set(false);
      }, 5000);
    });

    // Log action to timeline
    this.apiService.addActivity(
      this.getLocale() === 'ar' 
        ? `تقديم تقييم جديد للمنتج: ${prod.name.ar} بواسطة ${this.reviewerName}` 
        : `New review submitted for: ${prod.name.en} by ${this.reviewerName}`
    ).subscribe();
  }

  public getBrandName(brandId?: number): string {
    if (!brandId) return '';
    const brand = this.brandsList().find(b => b.id === brandId);
    return brand ? brand.name[this.getLocale()] : '';
  }

  public getCategoryName(categoryId?: number): string {
    if (!categoryId) return '';
    const cat = this.categoriesList().find(c => c.id === categoryId);
    return cat ? cat.name[this.getLocale()] : '';
  }

  public getCategorySlug(categoryId?: number): string {
    if (!categoryId) return '';
    const cat = this.categoriesList().find(c => c.id === categoryId);
    return cat ? cat.slug : '';
  }
}
