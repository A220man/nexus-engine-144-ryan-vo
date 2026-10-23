import { useState, useEffect } from 'react';
import { api } from '../api/client';

interface Alias {
  version: string;
  lts_name: string;
}

export function AliasManager() {
  const [aliases, setAliases] = useState<Alias[]>([]);
  const [defaultAlias, setDefaultAlias] = useState<string | null>(null);
  const [newDefault, setNewDefault] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const fetchAliases = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.client.get('/api/v1/aliases');
      setAliases(response.data.versions || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch aliases');
    } finally {
      setLoading(false);
    }
  };

  const fetchDefault = async () => {
    try {
      const response = await api.client.get('/api/v1/aliases/default');
      setDefaultAlias(response.data.version);
    } catch {
      setDefaultAlias(null);
    }
  };

  const handleSetDefault = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDefault.trim()) return;
    
    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      await api.client.post(`/api/v1/aliases/default/${newDefault.trim()}`);
      setSuccess(`Set ${newDefault} as default`);
      setNewDefault('');
      fetchDefault();
      fetchAliases();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to set default');
    } finally {
      setLoading(false);
    }
  };

  const handleRemoveDefault = async () => {
    if (!window.confirm('Remove default alias?')) return;
    
    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      await api.client.delete('/api/v1/aliases/default');
      setSuccess('Default alias removed');
      setDefaultAlias(null);
      fetchAliases();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to remove default');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAliases();
    fetchDefault();
  }, []);

  if (loading && aliases.length === 0) {
    return (
      <div className="loading">
        <div className="spinner" />
        <span>Loading aliases...</span>
      </div>
    );
  }

  return (
    <div className="card">
      <h2>Version Aliases</h2>
      
      <div style={{ marginBottom: '24px' }}>
        <h3 style={{ marginBottom: '12px', fontSize: '1rem' }}>Default Version</h3>
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
          {defaultAlias ? (
            <>
              <span className="config-file-value">{defaultAlias}</span>
              <button 
                className="btn btn-danger"
                onClick={handleRemoveDefault}
                disabled={loading}
              >
                Remove Default
              </button>
            </>
          ) : (
            <span style={{ color: '#666' }}>No default set</span>
          )}
        </div>
      </div>

      <form onSubmit={handleSetDefault} style={{ marginBottom: '24px' }}>
        <h3 style={{ marginBottom: '12px', fontSize: '1rem' }}>Set Default Version</h3>
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
          <input
            type="text"
            className="input"
            placeholder="e.g., v20.10.0, 18, lts/hydrogen"
            value={newDefault}
            onChange={(e) => setNewDefault(e.target.value)}
            style={{ flex: 1, minWidth: '200px' }}
            disabled={loading}
          />
          <button 
            type="submit" 
            className="btn btn-primary"
            disabled={loading || !newDefault.trim()}
          >
            {loading ? 'Setting...' : 'Set as Default'}
          </button>
        </div>
      </form>

      {error && <div className="error-message">{error}</div>}
      {success && <div className="success-message">{success}</div>}

      <h3 style={{ marginBottom: '12px', fontSize: '1rem' }}>All Aliases</h3>
      {aliases.length === 0 ? (
        <div className="empty-state">
          <p>No aliases configured</p>
        </div>
      ) : (
        <ul className="version-list">
          {aliases.map((alias) => (
            <li key={alias.version} className="version-item">
              <div className="version-info">
                <span className="version-badge installed">{alias.version}</span>
                <span className="version-number">→ {alias.lts_name}</span>
                {alias.lts_name === defaultAlias && (
                  <span className="current-indicator">DEFAULT</span>
                )}
              </div>
              <button
                className="btn btn-secondary"
                onClick={() => {
                  setNewDefault(alias.version);
                }}
                disabled={loading}
              >
                Set Default
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}