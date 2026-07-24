import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LanguageService } from '../../services/language.service';

@Component({
  selector: 'app-about',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './about.component.html'
})
export class AboutComponent {
  public langService = inject(LanguageService);

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }
}
