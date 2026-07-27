import { Component, signal, inject } from '@angular/core';
import { RouterOutlet, RouterLink, Router, NavigationEnd } from '@angular/router';
import { LanguageService } from '../../services/language.service';
import { filter } from 'rxjs/operators';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-public-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule],
  templateUrl: './public-layout.component.html',
})
export class PublicLayoutComponent {
  public langService = inject(LanguageService);
  private router = inject(Router);

  public isMobileMenuOpen = signal<boolean>(false);
  public currentUrl = signal<string>(typeof window !== 'undefined' ? (window.location.pathname + window.location.search + window.location.hash) : '');

  constructor() {
    if (typeof window !== 'undefined') {
      const initialPath = window.location.pathname + window.location.search + window.location.hash;
      this.currentUrl.set(initialPath);
    }

    this.router.events.pipe(
      filter((event): event is NavigationEnd => event instanceof NavigationEnd)
    ).subscribe((event: NavigationEnd) => {
      const targetUrl = event.urlAfterRedirects || event.url;
      this.currentUrl.set(targetUrl);
      this.isMobileMenuOpen.set(false);
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
