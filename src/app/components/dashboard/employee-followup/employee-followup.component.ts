import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../services/api.service';
import { LanguageService } from '../../../services/language.service';

interface EmployeeStats {
  id: number;
  name: string;
  email: string;
  role: string;
  totalTasks: number;
  completedTasks: number;
  inProgressTasks: number;
  pendingTasks: number;
  completionRate: number;
  averageProgress: number;
  tasks: any[];
}

@Component({
  selector: 'app-employee-followup',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './employee-followup.component.html',
  styleUrl: './employee-followup.component.css'
})
export class EmployeeFollowupComponent implements OnInit {
  public apiService = inject(ApiService);
  public langService = inject(LanguageService);

  // States
  public employeeStatsList = signal<EmployeeStats[]>([]);
  public selectedEmployee = signal<EmployeeStats | null>(null);
  public isLoading = signal<boolean>(false);
  public activityFeed = signal<any[]>([]);
  
  // Overall Averages
  public totalTasksCount = signal<number>(0);
  public overallAverageProgress = signal<number>(0);

  // Filter States
  public empSearchQuery = signal<string>('');
  public empPerformanceFilter = signal<'all' | 'high' | 'avg' | 'low'>('all');
  public feedSearchQuery = signal<string>('');
  public feedDateRangeFilter = signal<'all' | 'today' | 'week' | 'month'>('all');

  ngOnInit() {
    this.loadData();
  }

  public getLocale(): 'ar' | 'en' {
    return this.langService.currentLang();
  }

  public getFilteredEmployees(): EmployeeStats[] {
    let list = this.employeeStatsList();

    // Filter by performance level
    const perf = this.empPerformanceFilter();
    if (perf === 'high') {
      list = list.filter(e => e.averageProgress >= 70);
    } else if (perf === 'avg') {
      list = list.filter(e => e.averageProgress >= 40 && e.averageProgress < 70);
    } else if (perf === 'low') {
      list = list.filter(e => e.averageProgress < 40);
    }

    // Filter by search query
    const q = this.empSearchQuery().toLowerCase().trim();
    if (q) {
      list = list.filter(e => 
        e.name.toLowerCase().includes(q) ||
        e.role.toLowerCase().includes(q) ||
        e.email.toLowerCase().includes(q)
      );
    }

    return list;
  }

  public getFilteredActivityFeed(): any[] {
    let feed = this.activityFeed();

    // Filter by selected employee if active
    if (this.selectedEmployee()) {
      const selectedName = this.selectedEmployee()!.name.toLowerCase();
      feed = feed.filter(item => item.employeeName.toLowerCase().includes(selectedName));
    }

    // Filter by date range
    const dateFilter = this.feedDateRangeFilter();
    if (dateFilter !== 'all') {
      const now = new Date();
      feed = feed.filter(item => {
        const itemDate = new Date(item.created_at);
        if (isNaN(itemDate.getTime())) return true;

        if (dateFilter === 'today') {
          return itemDate.toDateString() === now.toDateString();
        } else if (dateFilter === 'week') {
          const diffDays = (now.getTime() - itemDate.getTime()) / (1000 * 3600 * 24);
          return diffDays <= 7;
        } else if (dateFilter === 'month') {
          return itemDate.getMonth() === now.getMonth() && itemDate.getFullYear() === now.getFullYear();
        }
        return true;
      });
    }

    // Filter by search query (task title, employee name, note, client name)
    const q = this.feedSearchQuery().toLowerCase().trim();
    if (q) {
      feed = feed.filter(item => {
        const emp = (item.employeeName || '').toLowerCase();
        const note = (item.note || '').toLowerCase();
        const client = typeof item.clientName === 'object' ? (item.clientName?.ar || item.clientName?.en || '').toLowerCase() : (item.clientName || '').toLowerCase();
        const taskTitle = typeof item.taskTitle === 'object' ? (item.taskTitle?.ar || item.taskTitle?.en || '').toLowerCase() : (item.taskTitle || '').toLowerCase();

        return emp.includes(q) || note.includes(q) || client.includes(q) || taskTitle.includes(q);
      });
    }

    return feed;
  }

  public resetEmpFilters() {
    this.empSearchQuery.set('');
    this.empPerformanceFilter.set('all');
  }

  public resetFeedFilters() {
    this.feedSearchQuery.set('');
    this.feedDateRangeFilter.set('all');
  }

  public loadData() {
    this.isLoading.set(true);
    // 1. Fetch Users
    this.apiService.getUsers().subscribe({
      next: (resUsers: any) => {
        const users = resUsers.data || resUsers || [];
        // Include all active employee roles
        const techStaff = users.filter((u: any) => 
          u.role === 'Field Engineer' ||
          u.role === 'Sales Representative' ||
          u.role === 'Maintenance Engineer' ||
          u.role === 'Accountant' ||
          u.role === 'Operations Manager' ||
          u.role === 'Admin' ||
          u.role === 'CEO' ||
          u.role === 'Service Engineer outdoor' ||
          u.role === 'Service Engineer indoor'
        );

        // 2. Fetch Tasks
        this.apiService.getTasks().subscribe({
          next: (tasks: any[]) => {
            const allTasks = tasks || [];
            this.totalTasksCount.set(allTasks.length);

            // Calculate overall progress average
            const sumProgress = allTasks.reduce((sum, t) => sum + (t.progress || 0), 0);
            this.overallAverageProgress.set(allTasks.length > 0 ? Math.round(sumProgress / allTasks.length) : 0);

            // 3. Build Stats per employee
            const stats: EmployeeStats[] = techStaff.map((u: any) => {
              const empTasks = allTasks.filter(t => t.user_id === u.id);
              const completed = empTasks.filter(t => t.status === 'completed').length;
              const inProgress = empTasks.filter(t => t.status === 'in_progress').length;
              const pending = empTasks.filter(t => t.status === 'pending').length;
              
              const rate = empTasks.length > 0 ? Math.round((completed / empTasks.length) * 100) : 0;
              const avgProgress = empTasks.length > 0 ? Math.round(empTasks.reduce((sum, t) => sum + (t.progress || 0), 0) / empTasks.length) : 0;

              return {
                id: u.id,
                name: u.name,
                email: u.email,
                role: u.role,
                totalTasks: empTasks.length,
                completedTasks: completed,
                inProgressTasks: inProgress,
                pendingTasks: pending,
                completionRate: rate,
                averageProgress: avgProgress,
                tasks: empTasks
              };
            });

            // Sort by average progress descending
            stats.sort((a, b) => b.averageProgress - a.averageProgress);

            this.employeeStatsList.set(stats);

            // Extract all task updates for unified activity feed (Facebook style)
            const feedList: any[] = [];
            allTasks.forEach((task: any) => {
              const updates = task.updates || [];
              updates.forEach((up: any) => {
                feedList.push({
                  id: up.id,
                  taskTitle: task.title,
                  taskId: task.id,
                  employeeName: up.user_name || task.engineer_name || 'Staff',
                  note: up.note,
                  progress: up.progress,
                  created_at: up.created_at,
                  clientName: task.client_name,
                });
              });
            });

            // Sort by newest first
            feedList.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
            this.activityFeed.set(feedList);

            // Keep selected employee reference sync'd if selected
            if (this.selectedEmployee()) {
              const found = stats.find(s => s.id === this.selectedEmployee()!.id);
              this.selectedEmployee.set(found || null);
            }

            this.isLoading.set(false);
          },
          error: (err) => {
            console.error('Failed to load tasks', err);
            this.isLoading.set(false);
          }
        });
      },
      error: (err) => {
        console.error('Failed to load users', err);
        this.isLoading.set(false);
      }
    });
  }

  public selectEmployee(emp: EmployeeStats) {
    if (this.selectedEmployee()?.id === emp.id) {
      this.selectedEmployee.set(null);
    } else {
      this.selectedEmployee.set(emp);
    }
  }

  // Helpers
  public getStatusClass(status: string): string {
    switch (status) {
      case 'pending': return 'bg-amber-50 text-amber-800 border-amber-200';
      case 'in_progress': return 'bg-blue-50 text-blue-800 border-blue-200';
      case 'completed': return 'bg-emerald-50 text-emerald-800 border-emerald-200';
      case 'cancelled': return 'bg-rose-50 text-rose-800 border-rose-200';
      default: return 'bg-slate-50 text-slate-800 border-slate-200';
    }
  }

  public translateStatus(status: string): string {
    if (this.getLocale() === 'ar') {
      switch (status) {
        case 'pending': return 'قيد الانتظار';
        case 'in_progress': return 'قيد التنفيذ';
        case 'completed': return 'مكتملة';
        case 'cancelled': return 'ملغاة';
        default: return status;
      }
    }
    return status.replace('_', ' ');
  }
}
