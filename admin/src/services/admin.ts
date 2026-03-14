import { api } from './api';

export interface InviteCode {
  id: number;
  code: string;
  status: string;
  usage_limit: number;
  used_count: number;
  created_at: string;
  used_at?: string;
  expires_at?: string;
}

export interface Role {
  id: number;
  name: string;
  description?: string;
  permissions: string[];
}

export interface Permission {
  id: number;
  code: string;
  name: string;
}

export interface AdminUser {
  id: number;
  account?: string;
  display_name: string;
  role: string;
  status: string;
  roles: { id: number; name: string }[];
  created_at: string;
}

export interface OverviewStats {
  range: string;
  since: string;
  users: { total: number; new: number; active: number };
  tasks: { created: number; completed: number; completion_rate: number };
  points: { issued: number; spent: number; net: number };
  store: { products: number; exchanges: number };
  invites: { created: number; used: number; conversion_rate: number };
  updated_at: string;
}

export interface SeriesStats {
  range: string;
  series: Array<{
    date: string;
    users_new: number;
    tasks_created: number;
    tasks_completed: number;
    points_issued: number;
    points_spent: number;
    store_exchanges: number;
  }>;
}

export interface TaskStats {
  range: string;
  created: number;
  completed: number;
  completion_rate: number;
  quadrant: Array<{ quadrant: number; count: number }>;
  repeat: { count: number; ratio: number };
}

export interface PointStats {
  range: string;
  issued: number;
  spent: number;
  net: number;
  balance_total: number;
  balance_avg: number;
  top_reasons: Array<{ reason: string; issued: number; spent: number; count: number }>;
}

export interface StoreStats {
  range: string;
  products_published: number;
  products_total: number;
  stock_total: number;
  exchanges: number;
  top_products: Array<{
    product_id: number;
    name: string;
    exchanges: number;
    points_spent: number;
    stock: number;
  }>;
}

export interface InviteStats {
  range: string;
  created: number;
  used: number;
  status: { active: number; disabled: number; exhausted: number };
}

export interface SecurityEvent {
  id: number;
  action: string;
  phone?: string;
  email?: string;
  client_key: string;
  success: number;
  detail?: string;
  created_at: string;
}

export interface SecurityStats {
  range: string;
  total: number;
  failed: number;
  locked_users: number;
  events: SecurityEvent[];
}

export interface FeedbackItem {
  id: number;
  owner: string;
  category: string;
  title: string;
  detail: string;
  contact?: string | null;
  created_at: string;
}

export interface FeedbackStats {
  range: string;
  total: number;
  by_category: Array<{ category: string; count: number }>;
  by_owner: Array<{ owner: string; count: number }>;
}

export interface AdminSettings {
  sms_provider: string;
  email_provider: string;
  admin_account?: string | null;
  admin_display_name?: string | null;
  server_time: string;
  db_path: string;
  node_env: string;
}

export interface BootstrapStatus {
  initialized: boolean;
}

export async function fetchInvites(status?: string) {
  const { data } = await api.get('/admin/invite-codes', { params: { status } });
  return data.result as InviteCode[];
}

export async function createInvites(count: number, usageLimit: number, expiresAt?: string) {
  const { data } = await api.post('/admin/invite-codes', {
    count,
    usage_limit: usageLimit,
    expires_at: expiresAt
  });
  return data.result as { codes: string[] };
}

export async function disableInvite(code: string) {
  const { data } = await api.post('/admin/invite-codes/disable', { code });
  return data.result as { code: string };
}

export async function fetchPermissions() {
  const { data } = await api.get('/admin/permissions');
  return data.result as Permission[];
}

export async function fetchRoles() {
  const { data } = await api.get('/admin/roles');
  return data.result as Role[];
}

export async function createRole(payload: {
  name: string;
  description?: string;
  permission_codes: string[];
}) {
  const { data } = await api.post('/admin/roles', payload);
  return data.result as { id: number };
}

export async function updateRole(id: number, payload: {
  name?: string;
  description?: string;
  permission_codes: string[];
}) {
  const { data } = await api.put(`/admin/roles/${id}`, payload);
  return data.result as { id: number };
}

export async function fetchUsers() {
  const { data } = await api.get('/admin/users');
  return data.result as AdminUser[];
}

export async function updateUserRoles(id: number, roleIds: number[]) {
  const { data } = await api.post(`/admin/users/${id}/roles`, { role_ids: roleIds });
  return data.result as { user_id: number };
}

export async function fetchOverview(range: string) {
  const { data } = await api.get('/admin/stats/overview', { params: { range } });
  return data.result as OverviewStats;
}

export async function fetchSeries(range: string) {
  const { data } = await api.get('/admin/stats/series', { params: { range } });
  return data.result as SeriesStats;
}

export async function fetchTaskStats(range: string) {
  const { data } = await api.get('/admin/stats/tasks', { params: { range } });
  return data.result as TaskStats;
}

export async function fetchPointStats(range: string) {
  const { data } = await api.get('/admin/stats/points', { params: { range } });
  return data.result as PointStats;
}

export async function fetchStoreStats(range: string) {
  const { data } = await api.get('/admin/stats/store', { params: { range } });
  return data.result as StoreStats;
}

export async function fetchInviteStats(range: string) {
  const { data } = await api.get('/admin/stats/invite', { params: { range } });
  return data.result as InviteStats;
}

export async function fetchSecurityEvents(range: string, limit = 50) {
  const { data } = await api.get('/admin/security/events', { params: { range, limit } });
  return data.result as SecurityStats;
}

export async function fetchFeedback(range: string, params: {
  owner?: string;
  category?: string;
  q?: string;
  limit?: number;
}) {
  const { data } = await api.get('/admin/feedback', { params: { range, ...params } });
  return data.result as { list: FeedbackItem[]; total: number };
}

export async function fetchFeedbackStats(range: string) {
  const { data } = await api.get('/admin/feedback/stats', { params: { range } });
  return data.result as FeedbackStats;
}

export async function fetchAdminSettings() {
  const { data } = await api.get('/admin/settings');
  return data.result as AdminSettings;
}

export async function fetchBootstrapStatus() {
  const { data } = await api.get('/admin/bootstrap/status');
  return data.result as BootstrapStatus;
}

export async function bootstrapAdmin(payload: {
  account: string;
  password: string;
  display_name: string;
}) {
  const { data } = await api.post('/admin/bootstrap', payload);
  return data.result as { account: string; display_name: string };
}
