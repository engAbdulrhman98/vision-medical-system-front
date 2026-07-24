import { Component, inject, signal, OnInit, OnDestroy, ElementRef, ViewChild, effect } from '@angular/core';
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

  // Signals for state management
  public isOpen = signal<boolean>(false);
  public activeView = signal<'list' | 'chat'>('list');
  public conversations = signal<Conversation[]>([]);
  public activeConversation = signal<Conversation | null>(null);
  public messages = signal<ChatMessage[]>([]);
  public allUsers = signal<ChatUser[]>([]);
  public searchQuery = signal<string>('');
  
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
      if (msgs.length > 0 && this.activeView() === 'chat') {
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
    
    // Poll conversation list every 30 seconds only when chat is open
    this.listPollInterval = setInterval(() => {
      if (this.isOpen() && this.activeView() === 'list') {
        this.loadConversations();
      }
    }, 30000);
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
        // Handle standard Laravel paginated response resource structure
        const data = res.data || res || [];
        this.conversations.set(data);
      },
      error: (err) => console.error('Failed to load conversations', err)
    });
  }

  // Load all system employees for starting a new chat
  public loadAllUsers() {
    this.apiService.getUsers().subscribe({
      next: (res: any) => {
        // Exclude the current user
        const list = res.data || res || [];
        const filtered = list.filter((u: any) => u.id !== this.currentUser?.id);
        this.allUsers.set(filtered);
      },
      error: (err) => console.error('Failed to load users', err)
    });
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
        // Laravel paginate latest messages comes in descending order, we want ascending
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
      if (this.isOpen() && this.activeView() === 'chat' && this.activeConversation()?.id === convId) {
        this.loadMessages(convId);
      }
    }, 15000);
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

    // Add message locally for instant responsiveness (optimistic UI update)
    const tempMsg: ChatMessage = {
      id: Date.now(), // Temp ID
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
    this.isNewChatDropdownOpen = false;
    this.searchQuery.set('');

    // Call API to start or get direct conversation
    this.apiService.startConversation([user.id]).subscribe({
      next: (res: any) => {
        // If already exists, return object contains it
        const conv = res.conversation || res.data || res;
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
    return p ? p.name : 'Unknown User';
  }

  public getParticipantRole(conv: Conversation): string {
    const p = this.getParticipant(conv);
    if (!p) return '';
    // Look up role in all users list or return a localized version if available
    const systemUser = this.allUsers().find(u => u.id === p.id);
    return systemUser?.role || 'Staff';
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
      this.messageContainer.nativeElement.scrollTop = this.messageContainer.nativeElement.scrollHeight;
    } catch (err) {
      // Container not ready or not visible
    }
  }
}
