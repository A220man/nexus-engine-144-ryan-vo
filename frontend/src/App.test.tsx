import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, cleanup } from '@testing-library/react';
import App from './App';
import { 
  useVersions, 
  useInstallVersion, 
  useUseVersion, 
  useConfigDetection, 
  useHealth, 
  useInstallScript,
  useRemoteVersions,
} from './hooks/useVersions';

// Mock the hooks
vi.mock('./hooks/useVersions', () => ({
  useVersions: vi.fn(),
  useInstallVersion: vi.fn(),
  useUseVersion: vi.fn(),
  useConfigDetection: vi.fn(),
  useHealth: vi.fn(),
  useInstallScript: vi.fn(),
  useRemoteVersions: vi.fn(),
}));

const mockUseVersions = useVersions as vi.Mock;
const mockUseInstallVersion = useInstallVersion as vi.Mock;
const mockUseUseVersion = useUseVersion as vi.Mock;
const mockUseConfigDetection = useConfigDetection as vi.Mock;
const mockUseHealth = useHealth as vi.Mock;
const mockUseInstallScript = useInstallScript as vi.Mock;
const mockUseRemoteVersions = useRemoteVersions as vi.Mock;

// Simple matcher for checking element existence
function toBeInTheDocument(element: HTMLElement | null) {
  return element !== null;
}

describe('App', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    
    mockUseVersions.mockReturnValue({
      versions: [
        { version: 'v20.10.0', status: 'active', is_default: false, is_current: true, lts_name: undefined },
        { version: 'v18.17.0', status: 'installed', is_default: true, is_current: false, lts_name: undefined },
      ],
      current: 'v20.10.0',
      defaultVersion: 'v18.17.0',
      loading: false,
      error: null,
      refetch: vi.fn(),
    });
    
    mockUseRemoteVersions.mockReturnValue({
      versions: [
        { version: 'v20.10.0', status: 'available', is_default: false, is_current: false, lts_name: 'hydrogen' },
        { version: 'v18.17.0', status: 'available', is_default: false, is_current: false, lts_name: undefined },
      ],
      loading: false,
      error: null,
      refetch: vi.fn(),
    });
    
    mockUseInstallVersion.mockReturnValue({
      install: vi.fn().mockResolvedValue({ success: true }),
      loading: false,
      error: null,
    });
    
    mockUseUseVersion.mockReturnValue({
      useVersion: vi.fn().mockResolvedValue({ success: true, version: 'v20.10.0' }),
      loading: false,
      error: null,
    });
    
    mockUseConfigDetection.mockReturnValue({
      config: {
        nvmrc: '20.10.0',
        node_version: undefined,
        package_json: undefined,
        detected_version: '20.10.0',
      },
      loading: false,
      error: null,
      detect: vi.fn(),
    });
    
    mockUseHealth.mockReturnValue({
      health: {
        status: 'healthy',
        service: 'nexus-engine-nvm-api',
        nvm_available: true,
        nvm_version: 'Nexus Engine NVM v1.0.0',
      },
      loading: false,
      error: null,
      check: vi.fn(),
    });
    
    mockUseInstallScript.mockReturnValue({
      script: {
        script_url: 'https://example.com/install.sh',
        install_command_curl: 'curl -o- https://example.com/install.sh | bash',
        install_command_wget: 'wget -qO- https://example.com/install.sh | bash',
        manual_steps: [],
      },
      loading: false,
      error: null,
    });
  });

  afterEach(() => {
    cleanup();
  });

  it('renders the main heading', () => {
    render(<App />);
    expect(toBeInTheDocument(screen.getByText('Nexus Engine NVM'))).toBe(true);
  });

  it('renders all navigation tabs', () => {
    render(<App />);
    expect(toBeInTheDocument(screen.getByRole('tab', { name: 'Installed Versions' }))).toBe(true);
    expect(toBeInTheDocument(screen.getByRole('tab', { name: 'Install Version' }))).toBe(true);
    expect(toBeInTheDocument(screen.getByRole('tab', { name: 'Config Detection' }))).toBe(true);
    expect(toBeInTheDocument(screen.getByRole('tab', { name: 'System Status' }))).toBe(true);
  });

  it('shows installed versions by default', () => {
    render(<App />);
    const versions = screen.getAllByText('v20.10.0');
    expect(versions.length).toBeGreaterThanOrEqual(1);
    expect(toBeInTheDocument(screen.getByText('CURRENT'))).toBe(true);
    expect(toBeInTheDocument(screen.getByText('DEFAULT'))).toBe(true);
  });

  it('switches tabs when clicked', () => {
    render(<App />);
    
    fireEvent.click(screen.getByRole('tab', { name: 'Install Version' }));
    expect(toBeInTheDocument(screen.getByText('Install Node.js Version'))).toBe(true);
    
    fireEvent.click(screen.getByRole('tab', { name: 'Config Detection' }));
    expect(toBeInTheDocument(screen.getByText('.nvmrc'))).toBe(true);
    expect(toBeInTheDocument(screen.getAllByText('20.10.0')[0])).toBe(true);
    fireEvent.click(screen.getByRole('tab', { name: 'System Status' }));
    // Use getByRole to find the card heading since there are multiple "System Status" texts
    expect(toBeInTheDocument(screen.getByRole('heading', { name: 'System Status' }))).toBe(true);
    expect(toBeInTheDocument(screen.getByText('Available'))).toBe(true);
  });

  it('displays config detection info', () => {
    render(<App />);
    fireEvent.click(screen.getByRole('tab', { name: 'Config Detection' }));
    expect(toBeInTheDocument(screen.getByText('Detected version:'))).toBe(true);
    expect(toBeInTheDocument(screen.getAllByText('20.10.0')[0])).toBe(true);
  });

  it('displays health status', () => {
    render(<App />);
    fireEvent.click(screen.getByRole('tab', { name: 'System Status' }));
    expect(toBeInTheDocument(screen.getByText('Nexus Engine NVM v1.0.0'))).toBe(true);
    expect(toBeInTheDocument(screen.getByText('curl -o- https://example.com/install.sh | bash'))).toBe(true);
  });
});