import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';

export const guestGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);

  if (typeof window !== 'undefined') {
    const userStr = localStorage.getItem('vm_logged_user');
    const token = localStorage.getItem('vm_auth_token');

    if (userStr && token) {
      router.navigate(['/dashboard']);
      return false;
    }
  }

  return true;
};
