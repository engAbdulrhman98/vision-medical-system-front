import { Component, signal, inject } from '@angular/core';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';
import { ToastContainerComponent } from './components/toast-container/toast-container.component';
import { LoadingComponent } from './components/loading/loading.component';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, ToastContainerComponent, LoadingComponent, CommonModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  public title = 'vision-medical-system-front';
  public isInitialLoading = signal<boolean>(true);
  private router = inject(Router);

  constructor() {
    if (typeof window !== 'undefined') {
      // Hold initial loading screen until route resolution completes smoothly
      setTimeout(() => {
        this.isInitialLoading.set(false);
      }, 450);
    } else {
      this.isInitialLoading.set(false);
    }

    this.router.events.subscribe((event) => {
      if (event instanceof NavigationEnd) {
        if (this.isInitialLoading()) {
          setTimeout(() => {
            this.isInitialLoading.set(false);
          }, 200);
        }
      }
    });
  }
}
