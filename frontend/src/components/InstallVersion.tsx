import React, { useState } from 'react';
import { useRemoteVersions, useInstallVersion } from '../hooks/useVersions';

export function InstallVersion({ onSuccess }: { onSuccess?: () => void }) {
  const [version, setVersion] = useState('');
  const [showLts, setShowLts] = useState(false);
  const { versions, loading: versionsLoading, refetch: refetchVersions } = useRemoteVersions(showLts);
  const { install, loading, error } = useInstallVersion();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!version.trim()) return;
    
    try {
      await install({ version: version.trim() });
      setVersion('');
      refetchVersions();
      onSuccess?.();
    } catch {
      // Error handled by hook
    }
  };

  const handleQuickInstall = async (ver: string) => {
    try {
      await install({ version: ver });
      refetchVersions();
      onSuccess?.();
    } catch {
      // Error handled by hook
    }
  };

  return (
    <div className="card">
      <h2>Install Node.js Version</h2>
      
      <form onSubmit={handleSubmit} className="form-group">
        <div className="form-row">
          <div className="form-group">
            <label className="form-label" htmlFor="version">Version</label>
            <input
              id="version"
              type="text"
              className="input"
              placeholder="e.g., 20.10.0, lts/hydrogen, --lts"
              value={version}
              onChange={(e) => setVersion(e.target.value)}
              disabled={loading}
            />
          </div>
        </div>
        
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', marginBottom: '16px' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
            <input
              type="checkbox"
              checked={showLts}
              onChange={(e) => setShowLts(e.target.checked)}
            />
            Show LTS only
          </label>
        </div>

        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '16px' }}>
          <span style={{ fontSize: '0.875rem', color: '#666', alignSelf: 'center' }}>Quick install:</span>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => handleQuickInstall('--lts')}
            disabled={loading}
          >
            Latest LTS
          </button>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => handleQuickInstall('node')}
            disabled={loading}
          >
            Latest Stable
          </button>
        </div>

        <button 
          type="submit" 
          className="btn btn-primary"
          disabled={loading || !version.trim()}
        >
          {loading ? 'Installing...' : 'Install Version'}
        </button>
      </form>

      {error && <div className="error-message">{error}</div>}

      <div className="card" style={{ marginTop: '24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <h2>Available Versions</h2>
          <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '0.875rem' }}>
            <input
              type="checkbox"
              checked={showLts}
              onChange={(e) => setShowLts(e.target.checked)}
            />
            LTS only
          </label>
        </div>

        {versionsLoading ? (
          <div className="loading">
            <div className="spinner" />
            <span>Loading available versions...</span>
          </div>
        ) : (
          <div style={{ maxHeight: '400px', overflow: 'auto' }}>
            <ul className="version-list">
              {versions.slice(0, 50).map((v) => (
                <li key={v.version} className="version-item">
                  <div className="version-info">
                    <span className={`version-badge ${v.status === 'lts' ? 'lts' : 'available'}`}>
                      {v.status === 'lts' ? 'LTS' : 'Available'}
                    </span>
                    <span className="version-number">{v.version}</span>
                    {v.lts_name && <span className="version-badge lts">{v.lts_name}</span>}
                  </div>
                  <button
                    className="btn btn-primary"
                    onClick={() => handleQuickInstall(v.version)}
                    disabled={loading}
                    style={{ padding: '6px 12px', fontSize: '0.8125rem' }}
                  >
                    Install
                  </button>
                </li>
              ))}
              {versions.length > 50 && (
                <li className="version-item">
                  <span style={{ color: '#666' }}>... and {versions.length - 50} more versions</span>
                </li>
              )}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}