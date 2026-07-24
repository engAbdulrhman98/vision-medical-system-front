import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { LanguageService } from '../../services/language.service';
import { ApiService } from '../../services/api.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './login.component.html'
})
export class LoginComponent {
  public langService = inject(LanguageService);
  public apiService = inject(ApiService);
  private router = inject(Router);
  private toastService = inject(ToastService);

  // Form Fields
  public email = '';
  public password = '';
  
  // Statuses
  public errorMessage = signal<string | null>(null);
  public isLoading = signal<boolean>(false);

  public fillCredentials(emailStr: string, passwordStr: string) {
    this.email = emailStr;
    this.password = passwordStr;
    this.onSubmit();
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public onSubmit() {
    this.errorMessage.set(null);
    this.isLoading.set(true);

    this.apiService.login(this.email, this.password).subscribe({
      next: (response) => {
        // Save access token and map user details
        if (typeof window !== 'undefined') {
          localStorage.setItem('vm_auth_token', response.access_token);

          const backendRole = response.user.roles?.[0]?.name || 'Service Engineer outdoor';
          let frontendRole = 'seller';
          let nameAr = response.user.name;
          let nameEn = response.user.name;

          if (backendRole === 'CEO') {
            frontendRole = 'admin';
            nameAr = 'المدير العام';
            nameEn = 'General Manager';
          } else if (backendRole === 'Admin') {
            frontendRole = 'admin';
            nameAr = 'الأدمن';
            nameEn = 'Administrator';
          } else if (backendRole === 'Operations Manager') {
            frontendRole = 'manager';
            nameAr = 'مدير الصيانة';
            nameEn = 'Operations Manager';
          } else if (backendRole === 'Accountant') {
            frontendRole = 'accountant';
            nameAr = 'المحاسب المالي';
            nameEn = 'Financial Accountant';
          } else if (backendRole === 'Service Engineer outdoor') {
            frontendRole = 'seller';
            nameAr = 'مهندس صيانة خارجي';
            nameEn = 'Service Engineer outdoor';
          } else if (backendRole === 'Service Engineer indoor') {
            frontendRole = 'seller';
            nameAr = 'مهندس صيانة داخلي';
            nameEn = 'Service Engineer indoor';
          } else if (backendRole === 'Sale') {
            frontendRole = 'seller';
            nameAr = 'مبيعات';
            nameEn = 'Sales Representative';
          }

          localStorage.setItem('vm_logged_user', JSON.stringify({
            id: response.user.id,
            email: response.user.email,
            role: frontendRole,
            name: { ar: nameAr, en: nameEn },
            permissions: response.user.all_permissions || []
          }));
        }

        this.isLoading.set(false);
        this.toastService.success({
          ar: 'تم تسجيل الدخول بنجاح! مرحباً بك في لوحة التحكم.',
          en: 'Logged in successfully! Welcome back to the dashboard.'
        });
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.isLoading.set(false);
        const errMsg = this.langService.currentLang() === 'ar' 
          ? 'خطأ في تسجيل الدخول. يرجى التحقق من البريد الإلكتروني وكلمة المرور.' 
          : 'Login failed. Please check your email and password.';
        this.errorMessage.set(errMsg);
        this.toastService.error(errMsg);
      }
    });
  }

  public toggleLanguage() {
    const nextLang = this.langService.currentLang() === 'ar' ? 'en' : 'ar';
    this.langService.setLanguage(nextLang);
  }
}
