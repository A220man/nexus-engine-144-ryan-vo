import { useState, useCallback } from 'react';
import { useVersions, useUseVersion } from './hooks/useVersions';
import { VersionList } from './components/VersionList';
import { InstallVersion } from './components/InstallVersion';
import { ConfigDetection } from './components/ConfigDetection';
import { HealthStatus } from './components/HealthStatus';
import { AliasManager } from './components/AliasManager';

function App() {
  const [activeTab, setActiveTab] = useState<'installed' | 'install' | 'config' | 'health' | 'aliases'>('installed');
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const { versions, current, defaultVersion, loading, error, refetch } = useVersions();
  const { useVersion, loading: useLoading } = useUseVersion();

  const handleUse = useCallback(async (version: string) => {
    try {
      await useVersion({ version });
      setSuccessMessage(`Switched to ${version}`);
      refetch();
    } catch {
      // Error handled by hook
    }
  }, [useVersion, refetch]);

  const handleUninstall = useCallback(async (version: string) => {
    try {
      const response = await fetch(`/api/v1/versions/${version}`, { method: 'DELETE' });
      if (response.ok) {
        setSuccessMessage(`Uninstalled ${version}`);
        refetch();
      }
    } catch {
      // Error handled
    }
  }, [refetch]);

  const handleSetDefault = useCallback(async (version: string) => {
    try {
      const response = await fetch(`/api/v1/versions/alias/default/${version}`, { method: 'POST' });
      if (response.ok) {
        setSuccessMessage(`Set ${version} as default`);
        refetch();
      }
    } catch {
      // Error handled
    }
  }, [refetch]);

  const handleInstallSuccess = useCallback(() => {
    setSuccessMessage('Version installed successfully');
    refetch();
  }, [refetch]);

  return (
    <div className="container">
      <header style={{ marginBottom: '32px' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 700, color: '#1a1a2e', marginBottom: '8px' }}>
          Nexus Engine NVM
        </h1>
        <p style={{ color: '#666', fontSize: '1rem' }}>
          Node Version Manager — Manage multiple Node.js versions
        </p>
      </header>

      {successMessage && (
        <div className="success-message" style={{ marginBottom: '24px' }}>
          {successMessage}
          <button 
            onClick={() => setSuccessMessage(null)}
            style={{ marginLeft: '16px', background: 'none', border: 'none', color: 'inherit', cursor: 'pointer', fontWeight: 600 }}
          >
            ✕
          </button>
        </div>
      )}

      {error && (
        <div className="error-message" style={{ marginBottom: '24px' }}>
          {error}
        </div>
      )}

      <nav className="tabs" role="tablist" aria-label="Main navigation">
        <button
          role="tab"
          aria-selected={activeTab === 'installed'}
          className={`tab ${activeTab === 'installed' ? 'active' : ''}`}
          onClick={() => setActiveTab('installed')}
        >
          Installed Versions
        </button>
        <button
          role="tab"
          aria-selected={activeTab === 'install'}
          className={`tab ${activeTab === 'install' ? 'active' : ''}`}
          onClick={() => setActiveTab('install')}
        >
          Install Version
        </button>
        <button
          role="tab"
          aria-selected={activeTab === 'config'}
          className={`tab ${activeTab === 'config' ? 'active' : ''}`}
          onClick={() => setActiveTab('config')}
        >
          Config Detection
        </button>
        <button
          role="tab"
          aria-selected={activeTab === 'health'}
          className={`tab ${activeTab === 'health' ? 'active' : ''}`}
          onClick={() => setActiveTab('health')}
        >
          System Status
        </button>
        <button
          role="tab"
          aria-selected={activeTab === 'aliases'}
          className={`tab ${activeTab === 'aliases' ? 'active' : ''}`}
          onClick={() => setActiveTab('aliases')}
        >
          Aliases
        </button>
      </nav>

      {activeTab === 'installed' && (
        <VersionList
          versions={versions}
          currentVersion={current}
          defaultVersion={defaultVersion}
          onUse={handleUse}
          onUninstall={handleUninstall}
          onSetDefault={handleSetDefault}
          loading={loading || useLoading}
        />
      )}

      {activeTab === 'install' && (
        <InstallVersion onSuccess={handleInstallSuccess} />
      )}

      {activeTab === 'config' && (
        <ConfigDetection />
      )}

      {activeTab === 'health' && (
        <HealthStatus />
      )}

      {activeTab === 'aliases' && (
        <AliasManager />
      )}

      <footer style={{ marginTop: '48px', paddingTop: '24px', borderTop: '1px solid #e8e8ed', textAlign: 'center', color: '#666', fontSize: '0.875rem' }}>
        <p>Nexus Engine NVM | Ryan Vo | AI & Machine Learning</p>
      </footer>
    </div>
  );
}

export default App;