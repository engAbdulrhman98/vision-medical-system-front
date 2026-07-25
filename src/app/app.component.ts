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

  // computed check to determine if the public layout should be rendered
  public isDashboardRoute = computed(() => {
    const url = this.currentUrl() || '';
    const routerUrl = this.router.url || '';
    const path = (typeof window !== 'undefined' && window.location) ? (window.location.pathname + window.location.hash + window.location.search) : '';
    
    return url.toLowerCase().includes('dashboard') || 
           routerUrl.toLowerCase().includes('dashboard') || 
           path.toLowerCase().includes('dashboard');
  });

  constructor() {
    if (typeof window !== 'undefined') {
      this.currentUrl.set(window.location.pathname + window.location.search);
    }

    // Monitor route changes immediately on NavigationStart & NavigationEnd
    this.router.events.subscribe((event: any) => {
      if (event && (event.url || event.urlAfterRedirects)) {
        this.currentUrl.set(event.urlAfterRedirects || event.url);
      }
      if (event instanceof NavigationEnd) {
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
