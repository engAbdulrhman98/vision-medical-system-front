import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';

export interface User {
  id: number;
  name: string;
  email: string;
  role?: string;
  all_permissions?: string[];
  avatar?: string;
  created_at?: string;
}

export interface ChatUser {
  id: number;
  name: string;
  email?: string;
  role?: string;
  avatar?: string;
}

export interface ChatMessage {
  id: number;
  conversation_id: number;
  sender_id?: number;
  user_id?: number;
  message?: string;
  body?: string;
  read_at?: string | null;
  sender?: ChatUser;
  created_at: string;
}

export interface Conversation {
  id: number;
  participants: ChatUser[];
  last_message?: ChatMessage;
  latest_message?: ChatMessage;
  unread_count?: number;
  updated_at: string;
}

export interface Product {
  id: number;
  slug: string;
  name: any;
  description?: any;
  details?: any;
  price: number;
  in_stock?: boolean;
  image?: string;
  image_url?: string;
  image_file?: string;
  category_id?: number;
  brand_id?: number;
  category?: any;
  brand?: any;
  reviews?: any[];
  average_rating?: number;
  reviews_count?: number;
}

export interface Category {
  id: number;
  slug: string;
  name: any;
  description?: any;
  image?: string;
  image_url?: string;
  products_count?: number;
}

export interface Brand {
  id: number;
  slug: string;
  name: any;
  logo?: string;
  image?: string;
  image_url?: string;
  products_count?: number;
}

export interface Area {
  id: number;
  name: string;
  type: string;
  parent_id?: number | null;
  parent?: Area;
}

export interface Client {
  id: number;
  name: string;
  type?: string;
  phone?: string;
  governorate?: string;
  city?: string;
  area_id?: number;
  detailed_address?: string;
  notes?: string;
  contacts?: any[];
}

export interface Quotation {
  id: number;
  quotation_number: string;
  client_id: number;
  client?: Client;
  total: number;
  status: string;
  created_at: string;
  items?: any[];
}

export interface Invoice {
  id: number;
  invoice_number: string;
  client_id: number;
  client?: Client;
  total: number;
  status: string;
  created_at: string;
}

export interface Task {
  id: number;
  title: string;
  description?: string;
  status: string;
  priority: string;
  progress: number;
  type: string;
  action_type?: string;
  rejection_reason?: string;
  accountant_note?: string;
  invoice_id?: number;
  client_id: number;
  client?: Client;
  user_id: number;
  user?: User;
  governorate_id?: number;
  city_id?: number;
  device_id?: number;
  scheduled_at?: string;
  otp_verified_at?: string;
  updates?: any[];
}

export interface Review {
  id: number;
  product_id: number;
  user_name?: string;
  reviewer_name: string;
  rating: number;
  comment: string;
  approved: boolean;
  created_at: string;
}

export interface ContactMessage {
  id: number;
  name: string;
  email: string;
  phone?: string;
  subject?: string;
  message: string;
  read: boolean;
  created_at: string;
}

export interface ActivityLog {
  id: number;
  user_id?: number;
  user?: User;
  action: string;
  description?: string;
  created_at: string;
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private http = inject(HttpClient);
  private apiUrl = (typeof window !== 'undefined' && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1')
    ? ((window as any).API_URL || 'https://vision-medical-system-back-production.up.railway.app/api')
    : 'http://localhost:8000/api';

  private getHeaders(): HttpHeaders {
    let headers = new HttpHeaders({
      'Accept': 'application/json'
    });
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('vm_auth_token');
      if (token) {
        headers = headers.set('Authorization', `Bearer ${token}`);
      }
    }
    return headers;
  }

  // ── Auth ─────────────────────────────────────────────────────────────
  login(login: string, password: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/login`, { login, email: login, username: login, password }, { headers: this.getHeaders() });
  }

  logout(): Observable<any> {
    return this.http.post(`${this.apiUrl}/logout`, {}, { headers: this.getHeaders() });
  }

  changePassword(currentPassword: string, newPassword: string, newPasswordConfirmation: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/change-password`, {
      current_password: currentPassword,
      new_password: newPassword,
      new_password_confirmation: newPasswordConfirmation
    }, { headers: this.getHeaders() });
  }

  getMe(): Observable<any> {
    return this.http.get(`${this.apiUrl}/me`, { headers: this.getHeaders() });
  }

  getCurrentUser(): Observable<User> {
    return this.getMe();
  }

  private extractArray<T>(res: any): T[] {
    if (Array.isArray(res)) return res;
    if (res && Array.isArray(res.data)) return res.data;
    return [];
  }

  private extractSingle<T>(res: any): T {
    if (res && res.data && typeof res.data === 'object' && !Array.isArray(res.data)) {
      return res.data;
    }
    return res;
  }

  // ── Products ─────────────────────────────────────────────────────────
  getProducts(search?: string, categorySlug?: string, brandSlug?: string): Observable<Product[]> {
    let params = new HttpParams();
    if (search) params = params.set('search', search);
    if (categorySlug) params = params.set('category', categorySlug);
    if (brandSlug) params = params.set('brand', brandSlug);
    return this.http.get<any>(`${this.apiUrl}/products`, { headers: this.getHeaders(), params }).pipe(
      map(res => this.extractArray<Product>(res)),
      catchError(() => of([]))
    );
  }

  getProductBySlug(slug: string): Observable<Product> {
    return this.http.get<any>(`${this.apiUrl}/products/${slug}`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractSingle<Product>(res)),
      catchError(() => of({} as Product))
    );
  }

  createProduct(payload: FormData | any): Observable<any> {
    return this.http.post(`${this.apiUrl}/products`, payload, { headers: this.getHeaders() });
  }

  updateProduct(id: number, payload: FormData | any): Observable<any> {
    return this.http.post(`${this.apiUrl}/products/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteProduct(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/products/${id}`, { headers: this.getHeaders() });
  }

  exportProducts(): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/products/export`, { headers: this.getHeaders(), responseType: 'blob' });
  }

  importProducts(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${this.apiUrl}/products/import`, formData, { headers: this.getHeaders() });
  }

  // ── Categories ───────────────────────────────────────────────────────
  getCategories(): Observable<Category[]> {
    return this.http.get<any>(`${this.apiUrl}/categories`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<Category>(res)),
      catchError(() => of([]))
    );
  }

  getCategoryBySlug(slug: string): Observable<Category> {
    return this.http.get<any>(`${this.apiUrl}/categories/${slug}`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractSingle<Category>(res))
    );
  }

  createCategory(payload: FormData | any): Observable<any> {
    return this.http.post(`${this.apiUrl}/categories`, payload, { headers: this.getHeaders() });
  }

  updateCategory(id: number, payload: FormData | any): Observable<any> {
    return this.http.post(`${this.apiUrl}/categories/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteCategory(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/categories/${id}`, { headers: this.getHeaders() });
  }

  exportCategories(): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/categories/export`, { headers: this.getHeaders(), responseType: 'blob' });
  }

  importCategories(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${this.apiUrl}/categories/import`, formData, { headers: this.getHeaders() });
  }

  // ── Brands ───────────────────────────────────────────────────────────
  getBrands(): Observable<Brand[]> {
    return this.http.get<any>(`${this.apiUrl}/brands`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<Brand>(res))
    );
  }

  getBrandBySlug(slug: string): Observable<Brand> {
    return this.http.get<any>(`${this.apiUrl}/brands/${slug}`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractSingle<Brand>(res))
    );
  }

  createBrand(payload: FormData | any): Observable<any> {
    return this.http.post(`${this.apiUrl}/brands`, payload, { headers: this.getHeaders() });
  }

  updateBrand(id: number, payload: FormData | any): Observable<any> {
    return this.http.post(`${this.apiUrl}/brands/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteBrand(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/brands/${id}`, { headers: this.getHeaders() });
  }

  exportBrands(): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/brands/export`, { headers: this.getHeaders(), responseType: 'blob' });
  }

  importBrands(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${this.apiUrl}/brands/import`, formData, { headers: this.getHeaders() });
  }

  // ── Areas ────────────────────────────────────────────────────────────
  getAreas(page = 1, limit = 1000): Observable<any> {
    const params = new HttpParams().set('page', String(page)).set('limit', String(limit));
    return this.http.get(`${this.apiUrl}/areas`, { headers: this.getHeaders(), params });
  }

  createArea(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/areas`, payload, { headers: this.getHeaders() });
  }

  updateArea(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/areas/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteArea(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/areas/${id}`, { headers: this.getHeaders() });
  }

  exportAreas(): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/areas/export`, { headers: this.getHeaders(), responseType: 'blob' });
  }

  importAreas(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${this.apiUrl}/areas/import`, formData, { headers: this.getHeaders() });
  }

  // ── Clients ──────────────────────────────────────────────────────────
  getClients(page = 1, limit = 1000): Observable<any> {
    const params = new HttpParams().set('page', String(page)).set('limit', String(limit));
    return this.http.get(`${this.apiUrl}/clients`, { headers: this.getHeaders(), params });
  }

  createClient(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/clients`, payload, { headers: this.getHeaders() });
  }

  updateClient(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/clients/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteClient(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/clients/${id}`, { headers: this.getHeaders() });
  }

  exportClients(): Observable<Blob> {
    const headers = this.getHeaders().set('Accept', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, */*');
    return this.http.get(`${this.apiUrl}/clients/export`, { headers, responseType: 'blob' });
  }

  importClients(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${this.apiUrl}/clients/import`, formData, { headers: this.getHeaders() });
  }

  getClientContacts(clientId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/clients/${clientId}/contacts`, { headers: this.getHeaders() });
  }

  createClientContact(clientId: number, payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/clients/${clientId}/contacts`, payload, { headers: this.getHeaders() });
  }

  updateClientContact(contactId: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/client-contacts/${contactId}`, payload, { headers: this.getHeaders() });
  }

  deleteClientContact(contactId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/client-contacts/${contactId}`, { headers: this.getHeaders() });
  }

  // ── Quotations ───────────────────────────────────────────────────────
  getQuotations(search?: string, status?: string): Observable<Quotation[]> {
    let params = new HttpParams();
    if (search) params = params.set('search', search);
    if (status) params = params.set('status', status);
    return this.http.get<Quotation[]>(`${this.apiUrl}/quotations`, { headers: this.getHeaders(), params });
  }

  createQuotation(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/quotations`, payload, { headers: this.getHeaders() });
  }

  updateQuotation(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/quotations/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteQuotation(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/quotations/${id}`, { headers: this.getHeaders() });
  }

  // ── Invoices ─────────────────────────────────────────────────────────
  getInvoices(search?: string, status?: string): Observable<Invoice[]> {
    let params = new HttpParams();
    if (search) params = params.set('search', search);
    if (status) params = params.set('status', status);
    return this.http.get<Invoice[]>(`${this.apiUrl}/invoices`, { headers: this.getHeaders(), params });
  }

  createInvoice(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/invoices`, payload, { headers: this.getHeaders() });
  }

  updateInvoice(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/invoices/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteInvoice(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/invoices/${id}`, { headers: this.getHeaders() });
  }

  // ── Invoice Requests Workflow ───────────────────────────────────────
  getInvoiceRequests(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/invoice-requests`, { headers: this.getHeaders() });
  }

  createInvoiceRequest(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/invoice-requests`, payload, { headers: this.getHeaders() });
  }

  issueInvoices(requestId: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/invoice-requests/${requestId}/issue`, {}, { headers: this.getHeaders() });
  }

  respondByClient(requestId: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/invoice-requests/${requestId}/client-response`, payload, { headers: this.getHeaders() });
  }

  markCollected(requestId: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/invoice-requests/${requestId}/collect`, payload, { headers: this.getHeaders() });
  }

  // ── Tasks ────────────────────────────────────────────────────────────
  getTasks(filters?: { type?: string; governorate_id?: number; city_id?: number; client_id?: number }): Observable<Task[]> {
    let params = new HttpParams();
    if (filters) {
      if (filters.type) params = params.set('type', filters.type);
      if (filters.governorate_id) params = params.set('governorate_id', String(filters.governorate_id));
      if (filters.city_id) params = params.set('city_id', String(filters.city_id));
      if (filters.client_id) params = params.set('client_id', String(filters.client_id));
    }
    return this.http.get<Task[]>(`${this.apiUrl}/tasks`, { headers: this.getHeaders(), params });
  }

  createTask(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/tasks`, payload, { headers: this.getHeaders() });
  }

  updateTask(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/tasks/${id}`, payload, { headers: this.getHeaders() });
  }

  updateTaskStatus(id: number, status: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/tasks/${id}/status`, { status }, { headers: this.getHeaders() });
  }

  addTaskUpdate(id: number, payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/tasks/${id}/updates`, payload, { headers: this.getHeaders() });
  }

  generateTaskOtp(id: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/tasks/${id}/generate-otp`, {}, { headers: this.getHeaders() });
  }

  verifyTaskOtp(id: number, otpCode: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/tasks/${id}/verify-otp`, { otp_code: otpCode }, { headers: this.getHeaders() });
  }

  submitTaskOutcome(id: number, payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/tasks/${id}/outcome`, payload, { headers: this.getHeaders() });
  }

  processTaskAccountantAction(id: number, payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/tasks/${id}/accountant-action`, payload, { headers: this.getHeaders() });
  }

  getDevices(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/devices`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<any>(res)),
      catchError(() => of([]))
    );
  }

  // ── Employees & Roles ────────────────────────────────────────────────
  getEmployees(): Observable<User[]> {
    return this.http.get<any>(`${this.apiUrl}/employees`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<User>(res)),
      catchError(() => of([]))
    );
  }

  createEmployee(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/employees`, payload, { headers: this.getHeaders() });
  }

  updateEmployee(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/employees/${id}`, payload, { headers: this.getHeaders() });
  }

  deleteEmployee(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/employees/${id}`, { headers: this.getHeaders() });
  }

  getEmployeePermissions(id: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/employees/${id}/permissions`, { headers: this.getHeaders() }).pipe(
      catchError(() => of({}))
    );
  }

  syncEmployeePermissions(id: number, permissions: string[]): Observable<any> {
    return this.http.post(`${this.apiUrl}/employees/${id}/permissions`, { permissions }, { headers: this.getHeaders() });
  }

  getUsers(): Observable<User[]> {
    return this.http.get<any>(`${this.apiUrl}/users`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<User>(res)),
      catchError(() => of([]))
    );
  }

  getRoles(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/roles`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<any>(res)),
      catchError(() => of([]))
    );
  }

  assignRole(email: string, role: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/users/assign-role`, { email, role }, { headers: this.getHeaders() });
  }

  togglePermission(roleName: string, permission: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/roles/toggle-permission`, { role: roleName, permission }, { headers: this.getHeaders() });
  }

  // ── Settings ─────────────────────────────────────────────────────────
  getSettings(): Observable<any> {
    return this.http.get(`${this.apiUrl}/settings`, { headers: this.getHeaders() }).pipe(
      catchError(() => of({}))
    );
  }

  updateSettings(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/settings`, payload, { headers: this.getHeaders() });
  }

  // ── Notifications ────────────────────────────────────────────────────
  getNotifications(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/notifications`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<any>(res)),
      catchError(() => of([]))
    );
  }

  markNotificationAsRead(id: number): Observable<any> {
    return this.http.patch(`${this.apiUrl}/notifications/${id}/read`, {}, { headers: this.getHeaders() });
  }

  markAllNotificationsAsRead(): Observable<any> {
    return this.http.post(`${this.apiUrl}/notifications/read-all`, {}, { headers: this.getHeaders() });
  }

  deleteNotification(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/notifications/${id}`, { headers: this.getHeaders() });
  }

  // ── Maintenance Reports ──────────────────────────────────────────────
  getMaintenanceReports(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/maintenance-reports`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<any>(res)),
      catchError(() => of([]))
    );
  }

  createMaintenanceReport(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/maintenance-reports`, payload, { headers: this.getHeaders() });
  }

  // ── Conversations ────────────────────────────────────────────────────
  getConversations(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/conversations`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<any>(res)),
      catchError(() => of([]))
    );
  }

  getConversationMessages(id: number): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/conversations/${id}/messages`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<any>(res)),
      catchError(() => of([]))
    );
  }

  sendMessage(id: number, message: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/conversations/${id}/messages`, { message }, { headers: this.getHeaders() });
  }

  startConversation(userIds: number[]): Observable<any> {
    return this.http.post(`${this.apiUrl}/conversations`, { user_ids: userIds }, { headers: this.getHeaders() });
  }

  markConversationAsRead(id: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/conversations/${id}/read`, {}, { headers: this.getHeaders() });
  }

  // ── Reviews & Messages & Activity Logs ───────────────────────────────
  getReviews(): Observable<Review[]> {
    return this.http.get<any>(`${this.apiUrl}/reviews`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<Review>(res)),
      catchError(() => of([]))
    );
  }

  getPendingReviews(): Observable<Review[]> {
    return this.getReviews().pipe(map(reviews => (reviews || []).filter(r => !r.approved)));
  }

  getReviewsForProduct(productId: number, approvedOnly = true): Review[] {
    return [];
  }

  getAverageRating(productId: number): number {
    return 5.0;
  }

  approveReview(id: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/reviews/${id}/approve`, {}, { headers: this.getHeaders() });
  }

  deleteReview(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/reviews/${id}`, { headers: this.getHeaders() });
  }

  submitReview(productIdOrPayload: any, reviewerName?: string, rating?: number, comment?: string): Observable<any> {
    const payload = typeof productIdOrPayload === 'object' ? productIdOrPayload : {
      product_id: productIdOrPayload,
      user_name: reviewerName,
      rating,
      comment
    };
    return this.http.post(`${this.apiUrl}/reviews`, payload, { headers: this.getHeaders() });
  }

  getMessages(): Observable<ContactMessage[]> {
    return this.http.get<any>(`${this.apiUrl}/contacts`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<ContactMessage>(res)),
      catchError(() => of([]))
    );
  }

  readMessage(id: number): Observable<any> {
    return this.http.patch(`${this.apiUrl}/contacts/${id}/read`, {}, { headers: this.getHeaders() });
  }

  deleteMessage(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/contacts/${id}`, { headers: this.getHeaders() });
  }

  submitContact(nameOrPayload: any, email?: string, phone?: string, subject?: string, message?: string): Observable<any> {
    const payload = typeof nameOrPayload === 'object' ? nameOrPayload : {
      name: nameOrPayload,
      email,
      phone,
      subject,
      message
    };
    return this.http.post(`${this.apiUrl}/contacts`, payload, { headers: this.getHeaders() });
  }

  getDashboardStats(): Observable<any> {
    return this.http.get(`${this.apiUrl}/dashboard/stats`, { headers: this.getHeaders() }).pipe(
      catchError(() => of({}))
    );
  }

  getActivityLogs(): Observable<ActivityLog[]> {
    return this.http.get<any>(`${this.apiUrl}/activity-logs`, { headers: this.getHeaders() }).pipe(
      map(res => this.extractArray<ActivityLog>(res)),
      catchError(() => of([]))
    );
  }

  addActivity(actionOrRole: string, description?: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/activity-logs`, { action: actionOrRole, description }, { headers: this.getHeaders() });
  }

  getAppDownloadInfo(): Observable<any> {
    return this.http.get(`${this.apiUrl}/app-download`).pipe(
      catchError(() => of({}))
    );
  }
}
