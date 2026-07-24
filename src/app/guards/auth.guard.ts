import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { ToastService } from '../services/toast.service';

export const authGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const toastService = inject(ToastService);

  if (typeof window !== 'undefined') {
    const userStr = localStorage.getItem('vm_logged_user');
    const token = localStorage.getItem('vm_auth_token');

    if (userStr && token) {
      return true;
    }
  }

  // Not logged in: show warning toast and redirect to login
  toastService.warning({
    ar: 'عذراً! يجب عليك تسجيل الدخول أولاً للوصول إلى لوحة التحكم.',
    en: 'Sorry! You must log in first to access the dashboard.'
  });

  router.navigate(['/login']);
  return false;
};
