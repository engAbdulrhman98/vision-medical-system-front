import { Component, inject, signal, OnInit, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from '../../services/api.service';
import { LanguageService } from '../../services/language.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-download-modal',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './app-download-modal.component.html'
})
export class AppDownloadModalComponent implements OnInit {
  public apiService = inject(ApiService);
  public langService = inject(LanguageService);
  private toastService = inject(ToastService);

  @Output() close = new EventEmitter<void>();

  public appInfo = signal<any>(null);
  public isLoading = signal<boolean>(true);

  ngOnInit() {
    this.loadAppInfo();
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public loadAppInfo() {
    this.isLoading.set(true);
    this.apiService.getAppDownloadInfo().subscribe({
      next: (data: any) => {
        this.appInfo.set(data);
        this.isLoading.set(false);
      },
      error: () => {
        // Fallback info if API isn't reachble
        this.appInfo.set({
          app_name: { ar: 'تطبيق فيجن ميديكال الذكي', en: 'Vision Medical Mobile App' },
          version: 'v2.4.0',
          file_size: '28.4 MB',
          android_download_url: 'http://localhost:8000/api/app/download/apk',
          ios_download_url: 'https://apps.apple.com',
          features: [
            { icon: 'fa-screwdriver-wrench', title: { ar: 'متابعة المهام الميدانية', en: 'Field Tasks' }, description: { ar: 'استلام وتحديث مهام الصيانة والمبيعات بجميع المواقع.', en: 'Receive and update visits on site.' } },
            { icon: 'fa-shield-halved', title: { ar: 'توثيق الزيارات برمز OTP', en: 'OTP Verification' }, description: { ar: 'توثيق الخدمة مع مسؤولي المستشفيات بأمان.', en: 'Secure OTP validation with hospital staff.' } },
            { icon: 'fa-bell', title: { ar: 'إشعارات وبث مباشر', en: 'Live Alerts' }, description: { ar: 'تنبيه فوري بالتكليفات والملاحظات الجديدة.', en: 'Instant alerts for assigned tasks.' } }
          ]
        });
        this.isLoading.set(false);
      }
    });
  }

  public downloadAndroidApk() {
    const url = this.appInfo()?.android_download_url || 'http://localhost:8000/api/app/download/apk';
    window.open(url, '_blank');
    this.toastService.success({
      ar: 'جاري بدأ تنزيل تطبيق أندرويد (Vision Medical APK)...',
      en: 'Starting Vision Medical Android APK download...'
    });
  }

  public openIosAppStore() {
    const url = this.appInfo()?.ios_download_url || 'https://apps.apple.com';
    window.open(url, '_blank');
    this.toastService.info({
      ar: 'تطبيق iOS على متجر App Store وسيكون متاحاً قريباً.',
      en: 'Redirecting to App Store...'
    });
  }

  public closeModal() {
    this.close.emit();
  }
}
