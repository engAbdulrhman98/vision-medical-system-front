import { Injectable, signal } from '@angular/core';

export interface Toast {
  id: number;
  type: 'success' | 'error' | 'warning' | 'info';
  message: string | { ar: string; en: string };
  duration?: number;
}

@Injectable({
  providedIn: 'root'
})
export class ToastService {
  public toasts = signal<Toast[]>([]);
  private nextId = 0;

  public show(
    type: 'success' | 'error' | 'warning' | 'info',
    message: string | { ar: string; en: string },
    duration = 4000
  ) {
    const id = this.nextId++;
    const newToast: Toast = { id, type, message, duration };
    this.toasts.update(current => [...current, newToast]);

    if (duration > 0) {
      setTimeout(() => {
        this.remove(id);
      }, duration);
    }
  }

  public success(message: string | { ar: string; en: string }, duration?: number) {
    this.show('success', message, duration);
  }

  public error(message: string | { ar: string; en: string }, duration?: number) {
    this.show('error', message, duration);
  }

  public warning(message: string | { ar: string; en: string }, duration?: number) {
    this.show('warning', message, duration);
  }

  public info(message: string | { ar: string; en: string }, duration?: number) {
    this.show('info', message, duration);
  }

  public remove(id: number) {
    this.toasts.update(current => current.filter(t => t.id !== id));
  }
}
