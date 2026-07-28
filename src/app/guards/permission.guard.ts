import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { ToastService } from '../services/toast.service';

export const permissionGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const toastService = inject(ToastService);

  if (typeof window === 'undefined') {
    return true;
  }

  const userStr = localStorage.getItem('vm_logged_user');
  const token = localStorage.getItem('vm_auth_token');

  if (!userStr || !token) {
    router.navigate(['/login']);
    return false;
  }

  try {
    const user = JSON.parse(userStr);
    const userRole = String(user.role || '').toLowerCase();
    const requiredPermission = route.data?.['permission'] as string;

    // Super Admin & CEO bypass
    if (userRole === 'admin' || userRole === 'ceo') {
      return true;
    }

    const perms: string[] = user.permissions || [];
    if (perms.includes('*') || (requiredPermission && perms.includes(requiredPermission))) {
      return true;
    }

    toastService.error({
      ar: 'عذراً! لا تملك الصلاحية المطلوبة للوصول لهذا القسم.',
      en: 'Access denied! Required permission is missing.'
    });

    router.navigate(['/dashboard']);
    return false;
  } catch (e) {
    router.navigate(['/login']);
    return false;
  }
};
