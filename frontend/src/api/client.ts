import axios, { AxiosInstance } from 'axios';
import type { 
  InstallRequest, 
  InstallResponse, 
  UseRequest, 
  UseResponse, 
  ListResponse, 
  ConfigFileResponse, 
  HealthResponse,
  InstallScriptResponse 
} from '../types/api';

const API_BASE_URL = '/api/v1';

class ApiClient {
  public client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    });

    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        const message = error.response?.data?.detail || error.message || 'An error occurred';
        return Promise.reject(new Error(message));
      }
    );
  }

  // Version endpoints
  async listVersions(lts: boolean = false): Promise<ListResponse> {
    const response = await this.client.get<ListResponse>('/versions', { params: { lts } });
    return response.data;
  }

  async listRemoteVersions(lts: boolean = false): Promise<ListResponse> {
    const response = await this.client.get<ListResponse>('/versions/remote', { params: { lts } });
    return response.data;
  }

  async getCurrentVersion(): Promise<{ version: string }> {
    const response = await this.client.get<{ version: string }>('/versions/current');
    return response.data;
  }

  async installVersion(request: InstallRequest): Promise<InstallResponse> {
    const response = await this.client.post<InstallResponse>('/versions/install', request);
    return response.data;
  }

  async useVersion(request: UseRequest): Promise<UseResponse> {
    const response = await this.client.post<UseResponse>('/versions/use', request);
    return response.data;
  }

  async setDefaultVersion(version: string): Promise<{ success: boolean; message: string; version: string }> {
    const response = await this.client.post(`/versions/alias/default/${version}`);
    return response.data;
  }

  async uninstallVersion(version: string): Promise<{ success: boolean; message: string }> {
    const response = await this.client.delete(`/versions/${version}`);
    return response.data;
  }

  // Config endpoints
  async detectConfig(cwd?: string): Promise<ConfigFileResponse> {
    const response = await this.client.get<ConfigFileResponse>('/config', { params: { cwd } });
    return response.data;
  }

  async checkHealth(): Promise<HealthResponse> {
    const response = await this.client.get<HealthResponse>('/config/health');
    return response.data;
  }

  // Install endpoints
  async getInstallScript(): Promise<InstallScriptResponse> {
    const response = await this.client.get<InstallScriptResponse>('/install/script');
    return response.data;
  }
}

export const api = new ApiClient();