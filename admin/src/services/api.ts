import axios, { AxiosError } from 'axios';

import { env } from '../config/env';
import { log } from '../utils/logger';

export const api = axios.create({
  baseURL: env.apiBaseUrl,
  timeout: 10000
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    const status = error.response?.status;
    const data = error.response?.data as { message?: string } | undefined;
    log('error', 'api_error', {
      status,
      message: data?.message || error.message,
      url: error.config?.url
    });
    return Promise.reject(error);
  }
);
