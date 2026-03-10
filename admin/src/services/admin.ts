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
