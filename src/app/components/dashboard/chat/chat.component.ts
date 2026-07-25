import { Component, inject, signal, OnInit, OnDestroy, ElementRef, ViewChild, Input, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService, Conversation, ChatMessage, ChatUser } from '../../../services/api.service';
import { LanguageService } from '../../../services/language.service';

@Component({
  selector: 'app-chat',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './chat.component.html',
  styleUrl: './chat.component.css'
})
export class ChatComponent implements OnInit, OnDestroy {
  public apiService = inject(ApiService);
  public langService = inject(LanguageService);

  @ViewChild('messageContainer') private messageContainer!: ElementRef;

  @Input() isFullPage: boolean = true;

  // Signals for state management
  public isOpen = signal<boolean>(true);
  public activeView = signal<'list' | 'chat'>('list');
  public conversations = signal<Conversation[]>([]);
  public activeConversation = signal<Conversation | null>(null);
  public messages = signal<ChatMessage[]>([]);
  public allUsers = signal<ChatUser[]>([]);
  public searchQuery = signal<string>('');
  public isNewChatModalOpen = signal<boolean>(false);
  
  // Normal state
  public currentUser: any = null;
  public newMessageText: string = '';
  public isNewChatDropdownOpen: boolean = false;
  
  // Polling intervals
  private listPollInterval: any;
  private messagePollInterval: any;

  constructor() {
    // Scroll to bottom when messages list changes and we are in active chat
    effect(() => {
      const msgs = this.messages();
      if (msgs.length > 0) {
        setTimeout(() => this.scrollToBottom(), 100);
      }
    });
  }

  ngOnInit() {
    if (typeof window !== 'undefined') {
      const userStr = localStorage.getItem('vm_logged_user');
      if (userStr) {
        try {
          this.currentUser = JSON.parse(userStr);
        } catch (e) {
          console.error('Failed to parse logged user in chat', e);
        }
      }
    }

    if (this.currentUser) {
      if (!this.currentUser.id) {
        this.apiService.getCurrentUser().subscribe({
          next: (user: any) => {
            this.currentUser.id = user.id;
            localStorage.setItem('vm_logged_user', JSON.stringify(this.currentUser));
            this.initializeChat();
          },
          error: (err) => {
            console.error('Failed to fetch current user details', err);
            this.initializeChat();
          }
        });
      } else {
        this.initializeChat();
      }
    }
  }

  private initializeChat() {
    this.loadConversations();
    this.loadAllUsers();
    
    // Poll conversation list every 15 seconds
    this.listPollInterval = setInterval(() => {
      this.loadConversations();
    }, 15000);
  }

  ngOnDestroy() {
    this.clearMessagePolling();
    if (this.listPollInterval) {
      clearInterval(this.listPollInterval);
    }
  }

  // Load conversation list
  public loadConversations() {
    this.apiService.getConversations().subscribe({
      next: (res: any) => {
        const data = res.data || res || [];
        this.conversations.set(data);
        // Auto select first conversation if none selected in desktop/fullPage view
        if (this.isFullPage && !this.activeConversation() && data.length > 0) {
          this.selectConversation(data[0]);
        }
      },
      error: (err) => console.error('Failed to load conversations', err)
    });
  }

  // Load all system employees for starting a new chat
  public loadAllUsers() {
    this.apiService.getUsers().subscribe({
      next: (res: any) => {
        const list = res.data || res || [];
        const filtered = list.filter((u: any) => u.id !== this.currentUser?.id);
        if (filtered.length > 0) {
          this.allUsers.set(filtered);
        } else {
          this.setFallbackUsers();
        }
      },
      error: (err) => {
        console.error('Failed to load users', err);
        this.setFallbackUsers();
      }
    });
  }

  private setFallbackUsers() {
    const defaultEmployees: ChatUser[] = [
      { id: 1, name: 'م. حسام الدين', email: 'tech@example.com', role: 'Service Engineer indoor' },
      { id: 2, name: 'م. طارق المحمودي', email: 'engineer@example.com', role: 'Service Engineer outdoor' },
      { id: 3, name: 'أحمد العلي', email: 'seller@example.com', role: 'Sale' },
      { id: 4, name: 'محمد خالد', email: 'accountant@example.com', role: 'Accountant' },
      { id: 5, name: 'د. محمود سعيد', email: 'manager@example.com', role: 'Operations Manager' },
      { id: 6, name: 'المدير العام', email: 'ceo@example.com', role: 'CEO' },
      { id: 7, name: 'مدير النظام الفني', email: 'admin@example.com', role: 'Admin' }
    ];
    const filtered = defaultEmployees.filter(u => u.id !== this.currentUser?.id);
    this.allUsers.set(filtered);
  }

  public openNewChatModal() {
    this.loadAllUsers();
    this.searchQuery.set('');
    this.isNewChatModalOpen.set(true);
  }

  public closeNewChatModal() {
    this.isNewChatModalOpen.set(false);
  }

  // Toggle chat widget
  public toggleChat() {
    this.isOpen.update(val => !val);
    if (this.isOpen()) {
      this.loadConversations();
      if (this.activeConversation()) {
        this.startMessagePolling(this.activeConversation()!.id);
      }
    } else {
      this.clearMessagePolling();
    }
  }

  // Go to list view
  public backToList() {
    this.activeView.set('list');
    this.activeConversation.set(null);
    this.messages.set([]);
    this.clearMessagePolling();
    this.loadConversations();
  }

  // Select/Open a conversation
  public selectConversation(conv: Conversation) {
    this.activeConversation.set(conv);
    this.activeView.set('chat');
    this.loadMessages(conv.id);
    this.markAsRead(conv.id);
    this.startMessagePolling(conv.id);
  }

  // Load messages for a conversation
  public loadMessages(convId: number) {
    this.apiService.getConversationMessages(convId).subscribe({
      next: (res: any) => {
        const data = res.data || res || [];
        const ascMessages = [...data].reverse();
        this.messages.set(ascMessages);
      },
      error: (err) => console.error('Failed to load messages', err)
    });
  }

  // Start polling messages for current active conversation
  private startMessagePolling(convId: number) {
    this.clearMessagePolling();
    this.messagePollInterval = setInterval(() => {
      if (this.activeConversation()?.id === convId) {
        this.loadMessages(convId);
      }
    }, 10000);
  }

  private clearMessagePolling() {
    if (this.messagePollInterval) {
      clearInterval(this.messagePollInterval);
      this.messagePollInterval = null;
    }
  }

  // Send message
  public sendMessage() {
    if (!this.newMessageText.trim() || !this.activeConversation()) return;
    
    const convId = this.activeConversation()!.id;
    const bodyText = this.newMessageText.trim();
    this.newMessageText = '';

    const tempMsg: ChatMessage = {
      id: Date.now(),
      conversation_id: convId,
      user_id: this.currentUser.id,
      body: bodyText,
      read_at: null,
      created_at: new Date().toISOString()
    };
    this.messages.update(prev => [...prev, tempMsg]);

    this.apiService.sendMessage(convId, bodyText).subscribe({
      next: () => {
        this.loadMessages(convId);
      },
      error: (err) => console.error('Failed to send message', err)
    });
  }

  // Mark conversation as read
  public markAsRead(convId: number) {
    this.apiService.markConversationAsRead(convId).subscribe({
      error: (err) => console.error('Failed to mark read', err)
    });
  }

  // Start conversation with selected employee
  public startChatWithUser(user: ChatUser) {
    this.isNewChatModalOpen.set(false);
    this.isNewChatDropdownOpen = false;
    this.searchQuery.set('');

    this.apiService.startConversation([user.id]).subscribe({
      next: (res: any) => {
        const conv = res.conversation || res.data || res;
        this.loadConversations();
        this.selectConversation(conv);
      },
      error: (err) => console.error('Failed to start chat', err)
    });
  }

  // Search filtered users
  public filteredUsers() {
    const query = this.searchQuery().toLowerCase().trim();
    if (!query) return this.allUsers();
    return this.allUsers().filter(u => 
      u.name.toLowerCase().includes(query) || 
      (u.email ? u.email.toLowerCase().includes(query) : false)
    );
  }

  // Helpers
  public getParticipant(conv: Conversation): ChatUser | null {
    if (!conv || !conv.participants) return null;
    return conv.participants.find(p => p.id !== this.currentUser?.id) || null;
  }

  public getParticipantName(conv: Conversation): string {
    const p = this.getParticipant(conv);
    return p ? p.name : (this.langService.currentLang() === 'ar' ? 'مستخدم غير معروف' : 'Unknown User');
  }

  public getParticipantRole(conv: Conversation): string {
    const p = this.getParticipant(conv);
    if (!p) return '';
    const systemUser = this.allUsers().find(u => u.id === p.id);
    return this.getDisplayRoleLabel(systemUser || p);
  }

  public getDisplayRoleLabel(roleOrUser: any): string {
    const roleStr = typeof roleOrUser === 'string' ? roleOrUser : (roleOrUser?.role || roleOrUser?.rawRole || '');
    const r = String(roleStr).toLowerCase();
    const isAr = this.langService.currentLang() === 'ar';
    if (r.includes('engineer') || r.includes('outdoor') || r.includes('indoor') || r.includes('فني') || r.includes('مهندس')) {
      return isAr ? '👷‍♂️ مهندس صيانة' : 'Field Engineer';
    }
    if (r.includes('sale') || r.includes('مبيعات')) {
      return isAr ? '💼 مسؤول مبيعات' : 'Sales Rep';
    }
    if (r.includes('accountant') || r.includes('محاسب')) {
      return isAr ? '💰 محاسب مالي' : 'Accountant';
    }
    if (r.includes('manager') || r.includes('operations') || r.includes('صيانة')) {
      return isAr ? '📊 مدير الصيانة والعمليات' : 'Operations Manager';
    }
    if (r.includes('ceo') || r.includes('عام')) {
      return isAr ? '👔 المدير العام' : 'CEO / General Manager';
    }
    if (r.includes('admin') || r.includes('نظام')) {
      return isAr ? '👑 مدير النظام' : 'Admin';
    }
    return isAr ? 'موظف' : 'Staff';
  }

  public getRoleBadgeClass(roleOrUser: any): string {
    const roleStr = typeof roleOrUser === 'string' ? roleOrUser : (roleOrUser?.role || roleOrUser?.rawRole || '');
    const r = String(roleStr).toLowerCase();
    if (r.includes('engineer') || r.includes('outdoor') || r.includes('indoor')) return 'bg-amber-500/15 text-amber-300 border-amber-500/30';
    if (r.includes('sale') || r.includes('مبيعات')) return 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30';
    if (r.includes('accountant') || r.includes('محاسب')) return 'bg-rose-500/15 text-rose-300 border-rose-500/30';
    if (r.includes('manager') || r.includes('operations')) return 'bg-sky-500/15 text-sky-300 border-sky-500/30';
    if (r.includes('ceo')) return 'bg-cyan-500/15 text-cyan-300 border-cyan-500/30';
    return 'bg-purple-500/15 text-purple-300 border-purple-500/30';
  }

  public getInitials(name: string): string {
    if (!name) return 'U';
    return name.split(' ').map(n => n.charAt(0)).slice(0, 2).join('').toUpperCase();
  }

  public isMessageFromMe(msg: ChatMessage): boolean {
    return msg.user_id === this.currentUser?.id;
  }

  public formatTime(dateStr: string): string {
    if (!dateStr) return '';
    try {
      const date = new Date(dateStr);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
      return '';
    }
  }

  private scrollToBottom() {
    try {
      if (this.messageContainer) {
        this.messageContainer.nativeElement.scrollTop = this.messageContainer.nativeElement.scrollHeight;
      }
    } catch (err) {
      // Container not ready or not visible
    }
  }
}
