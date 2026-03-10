import { api } from './api';

export interface AuthUser {
  id: number;
  account?: string;
  display_name: string;
  role: string;
  permissions?: string[];
}

export interface AuthSession {
  token: string;
  provider: string;
  expires_at: string;
  user: AuthUser;
}

export async function login(account: string, password: string): Promise<AuthSession> {
  const { data } = await api.post('/auth/login/account', { account, password });
  return data.result as AuthSession;
}

export async function getSession(token: string): Promise<AuthSession> {
  const { data } = await api.get('/auth/session', { params: { token } });
  return data.result as AuthSession;
}
