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
  public currentUrl = signal<string>(typeof window !== 'undefined' ? window.location.pathname : '');
  public isInitialLoading = signal<boolean>(true);

  // computed check to determine if the dashboard standalone layout should be rendered
  public isDashboardRoute = computed(() => {
    const url = (this.currentUrl() || '').toLowerCase();
    const routerUrl = (this.router.url || '').toLowerCase();
    const href = (typeof window !== 'undefined' && window.location ? (window.location.href + window.location.pathname) : '').toLowerCase();
    
    return url.includes('dashboard') || 
           routerUrl.includes('dashboard') || 
           href.includes('dashboard');
  });

  constructor() {
    if (typeof window !== 'undefined') {
      const initialPath = window.location.pathname + window.location.search + window.location.hash;
      this.currentUrl.set(initialPath);
      setTimeout(() => {
        this.isInitialLoading.set(false);
      }, 200);
    }

    // Monitor route changes strictly on NavigationEnd to guarantee correct URL state
    this.router.events.pipe(
      filter((event): event is NavigationEnd => event instanceof NavigationEnd)
    ).subscribe((event: NavigationEnd) => {
      const targetUrl = event.urlAfterRedirects || event.url;
      this.currentUrl.set(targetUrl);
      this.isMobileMenuOpen.set(false);
      if (this.isInitialLoading()) {
        this.isInitialLoading.set(false);
      }
      if (typeof window !== 'undefined') {
        window.scrollTo({ top: 0, behavior: 'smooth' });
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
