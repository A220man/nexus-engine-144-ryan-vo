import { useConfigDetection } from '../hooks/useVersions';

export function ConfigDetection() {
  const { config, loading, error, detect } = useConfigDetection();

  if (loading) {
    return (
      <div className="card">
        <h2>Config File Detection</h2>
        <div className="loading">
          <div className="spinner" />
          <span>Detecting config files...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card">
        <h2>Config File Detection</h2>
        <div className="error-message">{error}</div>
        <button className="btn btn-primary" onClick={() => detect()}>Retry</button>
      </div>
    );
  }

  if (!config) {
    return (
      <div className="card">
        <h2>Config File Detection</h2>
        <div className="empty-state">
          <p>No config detected</p>
        </div>
      </div>
    );
  }

  return (
    <div className="card">
      <h2>Config File Detection</h2>
      <p style={{ marginBottom: '16px', color: '#666', fontSize: '0.875rem' }}>
        NVM reads version from these files in order of precedence:
      </p>
      
      {config.nvmrc && (
        <div className="config-file">
          <span className="config-file-label">.nvmrc</span>
          <span className="config-file-value">{config.nvmrc}</span>
        </div>
      )}
      
      {config.node_version && (
        <div className="config-file">
          <span className="config-file-label">.node-version</span>
          <span className="config-file-value">{config.node_version}</span>
        </div>
      )}
      
      {config.package_json && (
        <div className="config-file">
          <span className="config-file-label">package.json (engines.node)</span>
          <span className="config-file-value">{config.package_json}</span>
        </div>
      )}
      
      {config.detected_version && (
        <div style={{ marginTop: '16px', padding: '16px', background: '#e8f0fe', borderRadius: '8px' }}>
          <strong>Detected version: </strong>
          <code>{config.detected_version}</code>
          <p style={{ marginTop: '8px', fontSize: '0.875rem', color: '#666' }}>
            Run <code>nvm use</code> (no arguments) to auto-switch to this version.
          </p>
        </div>
      )}
      
      {!config.nvmrc && !config.node_version && !config.package_json && (
        <div className="empty-state">
          <p>No .nvmrc, .node-version, or package.json with engines.node found in current directory.</p>
        </div>
      )}
    </div>
  );
}