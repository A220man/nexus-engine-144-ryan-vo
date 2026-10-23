export interface NodeVersion {
  version: string;
  status: 'installed' | 'active' | 'available' | 'lts';
  lts_name?: string;
  is_default: boolean;
  is_current: boolean;
}

export interface InstallRequest {
  version: string;
  force?: boolean;
}

export interface InstallResponse {
  success: boolean;
  version?: string;
  message: string;
  output?: string;
}

export interface UseRequest {
  version?: string;
}

export interface UseResponse {
  success: boolean;
  version?: string;
  message: string;
  output?: string;
}

export interface ListResponse {
  versions: NodeVersion[];
  current?: string;
  default?: string;
}

export interface ConfigFileResponse {
  nvmrc?: string;
  node_version?: string;
  package_json?: string;
  detected_version?: string;
}

export interface HealthResponse {
  status: string;
  service: string;
  nvm_available: boolean;
  nvm_version?: string;
}

export interface InstallScriptResponse {
  script_url: string;
  install_command_curl: string;
  install_command_wget: string;
  manual_steps: string[];
}