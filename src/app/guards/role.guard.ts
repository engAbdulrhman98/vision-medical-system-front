import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { ToastService } from '../services/toast.service';

export const roleGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const toastService = inject(ToastService);

  if (typeof window === 'undefined') {
    return true;
  }

  const userStr = localStorage.getItem('vm_logged_user');
  const token = localStorage.getItem('vm_auth_token');

  if (!userStr || !token) {
    toastService.warning({
      ar: 'عذراً! يجب تسجيل الدخول للوصول لهذه الصفحة.',
      en: 'Access denied! Please log in first.'
    });
    router.navigate(['/login']);
    return false;
  }

  try {
    const user = JSON.parse(userStr);
    const userRole = String(user.role || '').toLowerCase();
    const allowedRoles: string[] = route.data?.['roles'] || [];

    // Admin & CEO have super access to all routes
    if (userRole === 'admin' || userRole === 'ceo' || userRole.includes('مدير')) {
      return true;
    }

    if (allowedRoles.length > 0 && !allowedRoles.some(r => r.toLowerCase() === userRole)) {
      toastService.error({
        ar: 'عذراً! ليس لديك الصلاحية الوظيفية للوصول لهذه الصفحة.',
        en: 'Unauthorized! Your role does not allow access to this view.'
      });
      router.navigate(['/dashboard']);
      return false;
    }

    return true;
  } catch (e) {
    router.navigate(['/login']);
    return false;
  }
};
