import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { LanguageService } from '../../services/language.service';
import { ApiService } from '../../services/api.service';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-contact',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './contact.component.html'
})
export class ContactComponent {
  public langService = inject(LanguageService);
  private apiService = inject(ApiService);
  private sanitizer = inject(DomSanitizer);
  private toastService = inject(ToastService);

  // States
  public whatsappNumber = '';
  public phoneNumber = '';
  public emailAddress = '';
  public companyMapLink = '';
  public sanitizedMapLink: SafeResourceUrl | null = null;

  // Form parameters
  public contactName = '';
  public contactEmail = '';
  public contactSubject = '';
  public contactMessage = '';

  // Success alert
  public showSuccessAlert = signal<boolean>(false);

  constructor() {
    this.apiService.getSettings().subscribe(settings => {
      this.whatsappNumber = settings.whatsapp;
      this.phoneNumber = settings.store_phone;
      this.emailAddress = settings.store_email;
      this.companyMapLink = settings.company_map_link;

      if (this.companyMapLink) {
        this.sanitizedMapLink = this.sanitizer.bypassSecurityTrustResourceUrl(this.companyMapLink);
      }
    });
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public submitContactForm(event: Event) {
    event.preventDefault();

    this.apiService.submitContact(
      this.contactName,
      this.contactEmail,
      this.contactSubject || '[رسالة عامة]',
      this.contactMessage
    ).subscribe(() => {
      // Show success alert & toast
      this.showSuccessAlert.set(true);
      this.toastService.success({
        ar: 'تم إرسال رسالتك بنجاح! شكرًا لتواصلك معنا وسنقوم بالرد عليك في أقرب وقت.',
        en: 'Your message has been sent successfully! Thank you for contacting us, we will reply shortly.'
      });

      // Reset form fields
      this.contactName = '';
      this.contactEmail = '';
      this.contactSubject = '';
      this.contactMessage = '';

      // Hide alert after 5 seconds
      setTimeout(() => {
        this.showSuccessAlert.set(false);
      }, 5000);
    });

    // Add activity log
    this.apiService.addActivity(
      this.getLocale() === 'ar' 
        ? `استلام رسالة جديدة من العميل: ${this.contactName} بموضوع: ${this.contactSubject}`
        : `New message received from: ${this.contactName} with subject: ${this.contactSubject}`
    ).subscribe();
  }
}
