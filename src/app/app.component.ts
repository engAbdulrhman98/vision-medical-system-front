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
    const url = this.currentUrl();
    if (typeof window !== 'undefined' && window.location && window.location.pathname.includes('/dashboard')) {
      return true;
    }
    return !!(url && url.includes('/dashboard'));
  });

  constructor() {
    if (typeof window !== 'undefined') {
      this.currentUrl.set(window.location.pathname);
    }

    // Monitor route changes to hide/show header/footer and close mobile menu
    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe((event: any) => {
      this.currentUrl.set(event.urlAfterRedirects || event.url);
      this.isMobileMenuOpen.set(false);
      
      // Scroll to top on navigation
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
