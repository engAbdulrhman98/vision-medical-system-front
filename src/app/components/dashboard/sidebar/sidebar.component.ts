import { Component, inject, input, output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { LanguageService } from '../../../services/language.service';

export interface NavigateTabEvent {
  role: 'admin' | 'manager' | 'accountant' | 'seller';
  tab: string;
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterLink],
  host: {
    'class': 'shrink-0 flex flex-col z-30 md:w-72 relative'
  },
  template: `
    <!-- Mobile Sidebar Overlay -->
    @if (isSidebarOpen()) {
      <div 
        class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs z-40 md:hidden transition-opacity duration-300"
        (click)="onToggleSidebar()">
      </div>
    }

    <!-- Sidebar Navigation Drawer -->
    <aside 
      class="bg-slate-900 text-slate-300 flex flex-col justify-between shadow-2xl border-slate-800/80 z-50 transition-all duration-300 select-none fixed top-0 bottom-0 w-72 h-screen md:sticky md:top-0 md:h-screen"
      [ngClass]="{
        'translate-x-0': isSidebarOpen(),
        'rtl:right-0 ltr:left-0': true,
        'rtl:translate-x-full md:rtl:translate-x-0': !isSidebarOpen() && langService.currentLang() === 'ar',
        'ltr:-translate-x-full md:ltr:translate-x-0': !isSidebarOpen() && langService.currentLang() === 'en'
      }"
      [style]="langService.currentLang() === 'ar' ? 'border-left: 1px solid rgba(30, 41, 59, 0.8);' : 'border-right: 1px solid rgba(30, 41, 59, 0.8);'">
      
      <!-- Top Header & Menu Content -->
      <div class="overflow-y-auto flex-grow scrollbar-thin scrollbar-thumb-slate-800 scrollbar-track-transparent">
        
        <!-- Sidebar Brand Logo / Header -->
        <div class="p-4 px-5 border-b border-slate-800/80 flex items-center justify-between bg-slate-950/90 backdrop-blur-md sticky top-0 z-10">
          <div class="flex items-center gap-3.5">
            <div class="w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-700 rounded-xl flex items-center justify-center text-white text-lg shrink-0 shadow-lg shadow-emerald-950/50 border border-emerald-400/20">
              <i class="fa-solid fa-user-shield"></i>
            </div>
            <div>
              <span class="text-sm font-bold text-white block leading-tight tracking-wide">
                {{ langService.t('admin_portal') }}
              </span>
              <span class="text-[10px] font-bold text-emerald-400 uppercase tracking-widest block mt-0.5 opacity-90">
                Vision Control Panel
              </span>
            </div>
          </div>
          
          <!-- Mobile Close Button -->
          <button 
            (click)="onToggleSidebar()" 
            class="md:hidden w-8 h-8 flex items-center justify-center text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition-all border-0 bg-transparent cursor-pointer">
            <i class="fa-solid fa-xmark text-lg"></i>
          </button>
        </div>

        <!-- Navigation Sections -->
        <div class="p-3.5 space-y-5">

          <!-- 1. SALES & FIELD ENGINEERING (المبيعات والصيانة الميدانية) -->
          @if (getUserRole() === 'admin' || getUserRole() === 'seller') {
            <div class="space-y-1">
              <div class="px-2.5 py-1 flex items-center justify-between">
                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">
                  {{ langService.currentLang() === 'ar' ? 'المبيعات والصيانة الميدانية' : 'SALES & FIELD ENGINEERING' }}
                </span>
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
              </div>
              
              <nav class="space-y-1">
                <!-- Clients List -->
                <button (click)="onNavigate('seller', 'clients')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('seller', 'clients') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-users text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('seller', 'clients') ? 'text-white' : 'text-slate-400 group-hover:text-emerald-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'سجل العملاء والمستشفيات' : 'Clients & Hospitals' }}</span>
                  </div>
                </button>

                <!-- Add Client -->
                <button (click)="onNavigate('seller', 'new_client')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('seller', 'new_client') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-user-plus text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('seller', 'new_client') ? 'text-white' : 'text-slate-400 group-hover:text-emerald-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'إضافة عميل جديد' : 'Add New Client' }}</span>
                  </div>
                </button>

                <!-- Daily Tasks -->
                <button (click)="onNavigate('seller', 'tasks')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('seller', 'tasks') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-list-check text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('seller', 'tasks') ? 'text-white' : 'text-slate-400 group-hover:text-emerald-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'مهام المبيعات والصيانة' : 'Sales & Field Tasks' }}</span>
                  </div>
                </button>

                <!-- External Tasks -->
                <button (click)="onNavigate('seller', 'external-tasks')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('seller', 'external-tasks') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-screwdriver-wrench text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('seller', 'external-tasks') ? 'text-white' : 'text-slate-400 group-hover:text-emerald-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'الصيانة الخارجية والميدانية' : 'External Maintenance Visits' }}</span>
                  </div>
                </button>
              </nav>
            </div>
          }

          <!-- 2. REPORTS & FINANCIALS (التقارير والماليات) -->
          @if (getUserRole() === 'admin' || getUserRole() === 'accountant') {
            <div class="space-y-1">
              <div class="px-2.5 py-1 flex items-center justify-between">
                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">
                  {{ langService.currentLang() === 'ar' ? 'التقارير والماليات' : 'REPORTS & FINANCIALS' }}
                </span>
                <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
              </div>
              
              <nav class="space-y-1">
                <!-- Quotations List -->
                <button (click)="onNavigate('accountant', 'quotations')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('accountant', 'quotations') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-file-invoice text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('accountant', 'quotations') ? 'text-white' : 'text-slate-400 group-hover:text-rose-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'عروض الأسعار' : 'Quotations' }}</span>
                  </div>
                </button>

                <!-- Create Quotation -->
                <button (click)="onNavigate('accountant', 'new')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('accountant', 'new') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-file-circle-plus text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('accountant', 'new') ? 'text-white' : 'text-slate-400 group-hover:text-rose-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'إنشاء عرض سعر' : 'Create Quotation' }}</span>
                  </div>
                </button>

                <!-- Invoices List -->
                <button (click)="onNavigate('accountant', 'invoices')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('accountant', 'invoices') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-receipt text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('accountant', 'invoices') ? 'text-white' : 'text-slate-400 group-hover:text-rose-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'الفواتير والتحصيل' : 'Invoices' }}</span>
                  </div>
                </button>

                <!-- Accountant Workflow Tasks -->
                <button (click)="onNavigate('accountant', 'tasks')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('accountant', 'tasks') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-file-circle-check text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('accountant', 'tasks') ? 'text-white' : 'text-slate-400 group-hover:text-amber-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'طلبات الفواتير وأوامر الصيانة' : 'Invoice & Order Requests' }}</span>
                  </div>
                </button>

                <!-- Reports -->
                <button (click)="onNavigate('accountant', 'reports')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('accountant', 'reports') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-chart-pie text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('accountant', 'reports') ? 'text-white' : 'text-slate-400 group-hover:text-rose-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'التقارير المالية' : 'Financial Reports' }}</span>
                  </div>
                </button>
              </nav>
            </div>
          }

          <!-- 3. INVENTORY CONTROL (إدارة المستودع) -->
          @if (getUserRole() === 'admin' || getUserRole() === 'manager') {
            <div class="space-y-1">
              <div class="px-2.5 py-1 flex items-center justify-between">
                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">
                  {{ langService.currentLang() === 'ar' ? 'إدارة المستودع' : 'INVENTORY CONTROL' }}
                </span>
                <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
              </div>
              
              <nav class="space-y-1">
                <!-- Grouped Catalog Menu -->
                <div class="rounded-2xl border border-slate-800/90 bg-slate-950/40 overflow-hidden shadow-xs">
                  <button (click)="toggleCatalog()"
                    class="w-full flex items-center justify-between px-3.5 py-2.5 text-xs font-bold text-slate-200 hover:text-white hover:bg-slate-800/60 transition cursor-pointer border-0 bg-transparent text-start font-sans">
                    <div class="flex items-center gap-2.5">
                      <div class="w-6 h-6 rounded-lg bg-amber-500/15 text-amber-400 flex items-center justify-center shrink-0 border border-amber-500/20">
                        <i class="fa-solid fa-boxes-packing text-[11px]"></i>
                      </div>
                      <span class="text-xs font-bold">{{ langService.currentLang() === 'ar' ? 'كتالوج المنتجات الطبية' : 'Medical Products Catalog' }}</span>
                    </div>
                    <i class="fa-solid fa-chevron-down text-[10px] text-slate-400 transition-transform duration-200"
                       [class.rotate-180]="isCatalogOpen()" [class.text-amber-400]="isCatalogOpen()"></i>
                  </button>

                  @if (isCatalogOpen()) {
                    <div class="space-y-1 p-1.5 pt-0 bg-slate-950/70 border-t border-slate-800/80">
                      <!-- Medical Products -->
                      <button (click)="onNavigate('manager', 'products')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('manager', 'products') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-boxes-stacked text-xs w-4 text-center text-amber-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'المنتجات الطبية' : 'Medical Products' }}</span>
                        </div>
                      </button>

                      <!-- Categories -->
                      <button (click)="onNavigate('manager', 'categories')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('manager', 'categories') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-folder-open text-xs w-4 text-center text-sky-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'الأقسام والتصنيفات' : 'Categories' }}</span>
                        </div>
                      </button>

                      <!-- Brands -->
                      <button (click)="onNavigate('manager', 'brands')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('manager', 'brands') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-tag text-xs w-4 text-center text-emerald-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'الماركات والعلامات' : 'Brands' }}</span>
                        </div>
                      </button>
                    </div>
                  }
                </div>

                <!-- Maintenance Tasks -->
                <button (click)="onNavigate('manager', 'tasks')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('manager', 'tasks') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-list-check text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('manager', 'tasks') ? 'text-white' : 'text-slate-400 group-hover:text-amber-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'تكليفات الصيانة' : 'Maintenance Tasks' }}</span>
                  </div>
                </button>

                <!-- External Tasks -->
                <button (click)="onNavigate('manager', 'external-tasks')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('manager', 'external-tasks') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-screwdriver-wrench text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('manager', 'external-tasks') ? 'text-white' : 'text-slate-400 group-hover:text-amber-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'تكليفات الصيانة الخارجية' : 'External Tasks' }}</span>
                  </div>
                </button>
              </nav>
            </div>
          }

          <!-- 4. ADMINISTRATOR (المدير العام) -->
          @if (getUserRole() === 'admin') {
            <div class="space-y-1">
              <div class="px-2.5 py-1 flex items-center justify-between">
                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">
                  {{ langService.currentLang() === 'ar' ? 'المدير العام' : 'ADMINISTRATOR' }}
                </span>
                <span class="w-1.5 h-1.5 rounded-full bg-cyan-500"></span>
              </div>
              
              <nav class="space-y-1">
                <!-- Dashboard Home Stats -->
                <button (click)="onNavigate('admin', 'stats')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('admin', 'stats') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-chart-pie text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('admin', 'stats') ? 'text-white' : 'text-slate-400 group-hover:text-cyan-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'لوحة التحكم الرئيسية' : 'Dashboard' }}</span>
                  </div>
                </button>

                <!-- Grouped Employees Section -->
                <div class="rounded-2xl border border-slate-800/90 bg-slate-950/40 overflow-hidden shadow-xs">
                  <button (click)="toggleEmployees()"
                    class="w-full flex items-center justify-between px-3.5 py-2.5 text-xs font-bold text-slate-200 hover:text-white hover:bg-slate-800/60 transition cursor-pointer border-0 bg-transparent text-start font-sans">
                    <div class="flex items-center gap-2.5">
                      <div class="w-6 h-6 rounded-lg bg-cyan-500/15 text-cyan-400 flex items-center justify-center shrink-0 border border-cyan-500/20">
                        <i class="fa-solid fa-users-gear text-[11px]"></i>
                      </div>
                      <span class="text-xs font-bold">{{ langService.currentLang() === 'ar' ? 'إدارة ومتابعة الموظفين' : 'Employees & Follow-up' }}</span>
                    </div>
                    <i class="fa-solid fa-chevron-down text-[10px] text-slate-400 transition-transform duration-200"
                       [class.rotate-180]="isEmployeesOpen()" [class.text-cyan-400]="isEmployeesOpen()"></i>
                  </button>

                  @if (isEmployeesOpen()) {
                    <div class="space-y-1 p-1.5 pt-0 bg-slate-950/70 border-t border-slate-800/80">
                      <!-- Employees List -->
                      <button (click)="onNavigate('admin', 'employees')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('admin', 'employees') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-id-card text-xs w-4 text-center text-cyan-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'قائمة الموظفين' : 'Employees List' }}</span>
                        </div>
                      </button>

                      <!-- Employee Follow-up -->
                      <button (click)="onNavigate('manager', 'employee-followup')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('manager', 'employee-followup') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-chart-line text-xs w-4 text-center text-emerald-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'متابعة وتقييم الموظفين' : 'Employee Follow-up' }}</span>
                        </div>
                      </button>
                    </div>
                  }
                </div>

                <!-- Admin Tasks -->
                <button (click)="onNavigate('admin', 'tasks')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('admin', 'tasks') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-list-check text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('admin', 'tasks') ? 'text-white' : 'text-slate-400 group-hover:text-cyan-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'مهام الصيانة' : 'Maintenance Tasks' }}</span>
                  </div>
                </button>

                <!-- Admin External Tasks -->
                <button (click)="onNavigate('admin', 'external-tasks')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('admin', 'external-tasks') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-screwdriver-wrench text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('admin', 'external-tasks') ? 'text-white' : 'text-slate-400 group-hover:text-cyan-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'مهام الصيانة الخارجية' : 'External Tasks' }}</span>
                  </div>
                </button>

                <!-- Reviews -->
                <button (click)="onNavigate('admin', 'reviews')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('admin', 'reviews') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-star text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('admin', 'reviews') ? 'text-white' : 'text-slate-400 group-hover:text-cyan-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'المراجعات والتقييمات' : 'Product Reviews' }}</span>
                  </div>
                </button>

                <!-- Messages -->
                <button (click)="onNavigate('admin', 'messages')"
                  class="w-full group flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                  [ngClass]="isActive('admin', 'messages') ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold shadow-md shadow-emerald-950/40' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                  <div class="flex items-center gap-3">
                    <i class="fa-solid fa-envelope text-sm w-5 text-center transition-transform group-hover:scale-110"
                       [ngClass]="isActive('admin', 'messages') ? 'text-white' : 'text-slate-400 group-hover:text-cyan-400'"></i>
                    <span>{{ langService.currentLang() === 'ar' ? 'الرسائل والاتصالات' : 'Messages' }}</span>
                  </div>
                </button>

                <!-- Grouped Settings & System Section -->
                <div class="rounded-2xl border border-slate-800/90 bg-slate-950/40 overflow-hidden shadow-xs">
                  <button (click)="toggleSettings()"
                    class="w-full flex items-center justify-between px-3.5 py-2.5 text-xs font-bold text-slate-200 hover:text-white hover:bg-slate-800/60 transition cursor-pointer border-0 bg-transparent text-start font-sans">
                    <div class="flex items-center gap-2.5">
                      <div class="w-6 h-6 rounded-lg bg-indigo-500/15 text-indigo-400 flex items-center justify-center shrink-0 border border-indigo-500/20">
                        <i class="fa-solid fa-sliders text-[11px]"></i>
                      </div>
                      <span class="text-xs font-bold">{{ langService.currentLang() === 'ar' ? 'إعدادات وصلاحيات النظام' : 'System & Location Settings' }}</span>
                    </div>
                    <i class="fa-solid fa-chevron-down text-[10px] text-slate-400 transition-transform duration-200"
                       [class.rotate-180]="isSettingsOpen()" [class.text-indigo-400]="isSettingsOpen()"></i>
                  </button>

                  @if (isSettingsOpen()) {
                    <div class="space-y-1 p-1.5 pt-0 bg-slate-950/70 border-t border-slate-800/80">
                      <!-- Roles & Permissions -->
                      <button (click)="onNavigate('admin', 'permissions')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('admin', 'permissions') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-shield-halved text-xs w-4 text-center text-indigo-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'الأدوار والصلاحيات' : 'Roles & Permissions' }}</span>
                        </div>
                      </button>

                      <!-- Site Settings -->
                      <button (click)="onNavigate('admin', 'settings')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('admin', 'settings') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-gear text-xs w-4 text-center text-amber-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'إعدادات الموقع' : 'Site Settings' }}</span>
                        </div>
                      </button>

                      <!-- Areas & Cities -->
                      <button (click)="onNavigate('manager', 'areas')"
                        class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 border-0 bg-transparent text-start cursor-pointer font-sans"
                        [ngClass]="isActive('manager', 'areas') ? 'bg-emerald-600 text-white font-bold shadow-xs' : 'text-slate-400 hover:bg-slate-800/80 hover:text-slate-100'">
                        <div class="flex items-center gap-2.5 ps-1">
                          <i class="fa-solid fa-map-location-dot text-xs w-4 text-center text-rose-400"></i>
                          <span>{{ langService.currentLang() === 'ar' ? 'المناطق والمدن' : 'Areas & Cities' }}</span>
                        </div>
                      </button>
                    </div>
                  }
                </div>
              </nav>
            </div>
          }

        </div>
      </div>

      <!-- Sidebar Footer (User Info & Actions) -->
      <div class="p-3.5 border-t border-slate-800/80 bg-slate-950/80 backdrop-blur-md space-y-2.5 shrink-0">
        <!-- User Badge Profile Card -->
        <div class="flex items-center gap-3 px-2 py-1.5 rounded-xl bg-slate-900/60 border border-slate-800/60">
          <div class="w-9 h-9 bg-gradient-to-tr from-emerald-700 to-teal-500 text-white rounded-xl flex items-center justify-center font-extrabold text-sm shrink-0 shadow-md border border-emerald-400/30">
            {{ getUserInitial() }}
          </div>
          <div class="overflow-hidden min-w-0 flex-1">
            <span class="text-xs font-bold text-white block truncate">
              {{ getUserName() }}
            </span>
            <span class="text-[10px] font-semibold text-emerald-400 uppercase tracking-wider block truncate">
              {{ loggedUser()?.role || 'Staff' }}
            </span>
          </div>
        </div>
        
        <!-- View Store Button -->
        <a routerLink="/" 
           class="flex items-center justify-center gap-2 bg-slate-800/80 hover:bg-slate-800 text-slate-200 text-xs font-semibold py-2 rounded-xl transition-all border border-slate-700/50 hover:border-slate-600 cursor-pointer no-underline">
          <i class="fa-solid fa-globe text-emerald-400"></i>
          <span>{{ langService.t('view_store') }}</span>
        </a>

        <!-- Download App Banner in Sidebar -->
        <button (click)="openAppDownload.emit()"
                class="w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-700 hover:from-emerald-700 hover:to-teal-800 text-white font-bold text-xs transition cursor-pointer border-0 shadow-md">
          <div class="flex items-center gap-2.5">
            <i class="fa-solid fa-mobile-screen-button text-base animate-pulse"></i>
            <span>{{ langService.currentLang() === 'ar' ? 'تطبيق الموبايل الذكي' : 'Mobile App APK' }}</span>
          </div>
          <i class="fa-solid fa-download text-xs text-emerald-200"></i>
        </button>

        <!-- Logout Button -->
        <button (click)="onLogout()" 
                class="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold text-rose-400 hover:bg-rose-500/10 hover:text-rose-300 transition-all border border-rose-500/20 cursor-pointer bg-transparent">
          <i class="fa-solid fa-arrow-right-from-bracket"></i>
          <span>{{ langService.t('logout') }}</span>
        </button>
      </div>
    </aside>
  `
})
export class SidebarComponent {
  public langService = inject(LanguageService);

  // Inputs
  public loggedUser = input<any>(null);
  public activeRole = input<'admin' | 'manager' | 'accountant' | 'seller'>('admin');
  public adminActiveTab = input<string>('stats');
  public managerActiveTab = input<string>('products');
  public sellerActiveTab = input<string>('clients');
  public accountantActiveTab = input<string>('quotations');
  public isSidebarOpen = input<boolean>(false);

  // Outputs
  public navigateTab = output<NavigateTabEvent>();
  public toggleSidebar = output<void>();
  public logout = output<void>();
  public openAppDownload = output<void>();

  // Internal Signals for Collapsible Sub-menus
  public isCatalogOpen = signal<boolean>(false);
  public isEmployeesOpen = signal<boolean>(false);
  public isSettingsOpen = signal<boolean>(false);

  public toggleCatalog() {
    this.isCatalogOpen.update(v => !v);
  }

  public toggleEmployees() {
    this.isEmployeesOpen.update(v => !v);
  }

  public toggleSettings() {
    this.isSettingsOpen.update(v => !v);
  }

  public isActive(role: 'admin' | 'manager' | 'accountant' | 'seller', tab: string): boolean {
    if (this.activeRole() !== role) return false;
    switch (role) {
      case 'admin':
        return this.adminActiveTab() === tab;
      case 'manager':
        return this.managerActiveTab() === tab;
      case 'seller':
        return this.sellerActiveTab() === tab;
      case 'accountant':
        return this.accountantActiveTab() === tab;
    }
  }

  public onNavigate(role: 'admin' | 'manager' | 'accountant' | 'seller', tab: string) {
    this.navigateTab.emit({ role, tab });
  }

  public onToggleSidebar() {
    this.toggleSidebar.emit();
  }

  public onLogout() {
    this.logout.emit();
  }

  public getUserRole(): 'admin' | 'manager' | 'accountant' | 'seller' {
    const u = this.loggedUser();
    if (!u || !u.role) return 'admin';
    const r = String(u.role).toLowerCase();
    if (r === 'admin' || r === 'ceo') return 'admin';
    if (r.includes('manager') || r.includes('operations')) return 'manager';
    if (r.includes('accountant') || r.includes('محاسب')) return 'accountant';
    return 'seller';
  }

  public getUserName(): string {
    const u = this.loggedUser();
    if (!u) return '';
    if (typeof u.name === 'string') return u.name;
    return u.name?.ar || u.name?.en || 'Vision Staff';
  }

  public getUserInitial(): string {
    const name = this.getUserName();
    return name ? name.charAt(0).toUpperCase() : 'U';
  }
}
