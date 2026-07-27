import { Component, computed, signal, inject } from '@angular/core';
import { RouterOutlet, RouterLink, Router, NavigationEnd } from '@angular/router';
import { LanguageService } from './services/language.service';
import { filter } from 'rxjs/operators';
import { CommonModule } from '@angular/common';
import { ToastContainerComponent } from './components/toast-container/toast-container.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule, ToastContainerComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  public title = 'vision-medical-system-front';
  public langService = inject(LanguageService);
  private router = inject(Router);

  // States
  public isMobileMenuOpen = signal<boolean>(false);
  public currentUrl = signal<string>(typeof window !== 'undefined' ? (window.location.pathname + window.location.search + window.location.hash) : '');
  public isInitialLoading = signal<boolean>(false);

  // computed check to determine if the dashboard standalone layout should be rendered
  public isDashboardRoute = computed(() => {
    if (typeof window !== 'undefined' && window.location) {
      const path = (window.location.pathname || '').toLowerCase();
      const href = (window.location.href || '').toLowerCase();
      if (path.includes('dashboard') || href.includes('dashboard')) {
        return true;
      }
    }
    const url = (this.currentUrl() || '').toLowerCase();
    const routerUrl = (this.router.url || '').toLowerCase();
    return url.includes('dashboard') || routerUrl.includes('dashboard');
  });

  constructor() {
    if (typeof window !== 'undefined') {
      const initialPath = window.location.pathname + window.location.search + window.location.hash;
      this.currentUrl.set(initialPath);
    }

    // Monitor router events immediately to keep URL state in sync on refresh and navigation
    this.router.events.subscribe((event) => {
      if (typeof window !== 'undefined' && window.location) {
        const path = window.location.pathname + window.location.search + window.location.hash;
        if (path) this.currentUrl.set(path);
      }
      if (event instanceof NavigationEnd) {
        const targetUrl = event.urlAfterRedirects || event.url;
        this.currentUrl.set(targetUrl);
        this.isMobileMenuOpen.set(false);
        if (typeof window !== 'undefined') {
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }
      }
    });
  }

  public toggleMobileMenu() {
    this.isMobileMenuOpen.update(val => !val);
  }

  public toggleLanguage() {
    const nextLang = this.langService.currentLang() === 'ar' ? 'en' : 'ar';
    this.langService.setLanguage(nextLang);
  }
}
