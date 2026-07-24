import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ToastService, Toast } from '../../services/toast.service';
import { LanguageService } from '../../services/language.service';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div 
      class="fixed top-6 z-[9999] max-w-md w-full px-4 flex flex-col gap-3 transition-all duration-500"
      [ngClass]="langService.currentLang() === 'ar' ? 'left-0 sm:left-6' : 'right-0 sm:right-6'"
      [style.direction]="langService.currentLang() === 'ar' ? 'rtl' : 'ltr'"
    >
      @for (toast of toastService.toasts(); track toast.id) {
        <div 
          class="glass-card shadow-lg hover:shadow-xl rounded-2xl p-4 border border-slate-200/40 relative flex gap-3.5 items-start overflow-hidden transition-all duration-300 transform hover:scale-[1.02] animate-toast-in"
          [ngClass]="getBgBorderClass(toast.type)"
        >
          <!-- Accent Colored Left/Right Bar -->
          <div 
            class="absolute top-0 bottom-0 w-1.5"
            [ngClass]="[
              langService.currentLang() === 'ar' ? 'right-0' : 'left-0',
              getBarClass(toast.type)
            ]"
          ></div>

          <!-- Notification Icon -->
          <div class="flex-shrink-0 pt-0.5" [ngClass]="langService.currentLang() === 'ar' ? 'pr-2' : 'pl-2'">
            <i class="fa-solid text-lg" [ngClass]="getIconClass(toast.type)"></i>
          </div>

          <!-- Content -->
          <div class="flex-grow min-w-0 pr-1 pl-1">
            <h4 class="text-xs font-black uppercase tracking-wider text-slate-400 mb-0.5">
              {{ getTitleText(toast.type) }}
            </h4>
            <p class="text-sm font-semibold text-slate-800 leading-relaxed whitespace-pre-line">
              {{ getMessageText(toast.message) }}
            </p>
          </div>

          <!-- Close button -->
          <button 
            (click)="toastService.remove(toast.id)" 
            class="flex-shrink-0 text-slate-400 hover:text-slate-600 transition cursor-pointer p-1 rounded-lg hover:bg-slate-100/50"
          >
            <i class="fa-solid fa-xmark text-sm"></i>
          </button>

          <!-- Shrinking Progress Bar -->
          @if (toast.duration && toast.duration > 0) {
            <div 
              class="absolute bottom-0 left-0 right-0 h-1 bg-slate-100"
            >
              <div 
                class="h-full transition-all linear"
                [ngClass]="getProgressBarClass(toast.type)"
                [style.animation]="'shrink ' + toast.duration + 'ms linear forwards'"
              ></div>
            </div>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .glass-card {
      background: rgba(255, 255, 255, 0.85);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
    }
    @keyframes shrink {
      from { width: 100%; }
      to { width: 0%; }
    }
    @keyframes toast-in {
      from {
        opacity: 0;
        transform: translateY(-20px) scale(0.95);
      }
      to {
        opacity: 1;
        transform: translateY(0) scale(1);
      }
    }
    .animate-toast-in {
      animation: toast-in 0.35s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
    }
  `]
})
export class ToastContainerComponent {
  public toastService = inject(ToastService);
  public langService = inject(LanguageService);

  public getMessageText(message: string | { ar: string; en: string }): string {
    if (typeof message === 'string') return message;
    return this.langService.currentLang() === 'ar' ? message.ar : message.en;
  }

  public getTitleText(type: 'success' | 'error' | 'warning' | 'info'): string {
    const isAr = this.langService.currentLang() === 'ar';
    switch (type) {
      case 'success': return isAr ? 'نجاح' : 'Success';
      case 'error': return isAr ? 'خطأ' : 'Error';
      case 'warning': return isAr ? 'تحذير' : 'Warning';
      case 'info': return isAr ? 'تنبيه' : 'Info';
    }
  }

  public getIconClass(type: 'success' | 'error' | 'warning' | 'info'): string {
    switch (type) {
      case 'success': return 'fa-circle-check text-emerald-500';
      case 'error': return 'fa-circle-exclamation text-rose-500';
      case 'warning': return 'fa-triangle-exclamation text-amber-500';
      case 'info': return 'fa-circle-info text-blue-500';
    }
  }

  public getBgBorderClass(type: 'success' | 'error' | 'warning' | 'info'): string {
    switch (type) {
      case 'success': return 'bg-emerald-50/90 border-emerald-100';
      case 'error': return 'bg-rose-50/90 border-rose-100';
      case 'warning': return 'bg-amber-50/90 border-amber-100';
      case 'info': return 'bg-blue-50/90 border-blue-100';
    }
  }

  public getBarClass(type: 'success' | 'error' | 'warning' | 'info'): string {
    switch (type) {
      case 'success': return 'bg-emerald-500';
      case 'error': return 'bg-rose-500';
      case 'warning': return 'bg-amber-500';
      case 'info': return 'bg-blue-500';
    }
  }

  public getProgressBarClass(type: 'success' | 'error' | 'warning' | 'info'): string {
    switch (type) {
      case 'success': return 'bg-emerald-500/60';
      case 'error': return 'bg-rose-500/60';
      case 'warning': return 'bg-amber-500/60';
      case 'info': return 'bg-blue-500/60';
    }
  }
}
