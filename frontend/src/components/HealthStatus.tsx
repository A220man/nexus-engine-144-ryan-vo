import { useHealth, useInstallScript } from '../hooks/useVersions';

export function HealthStatus() {
  const { health, loading, error, check } = useHealth();
  const { script } = useInstallScript();

  if (loading) {
    return (
      <div className="card">
        <h2>System Status</h2>
        <div className="loading">
          <div className="spinner" />
          <span>Checking system health...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card">
        <h2>System Status</h2>
        <div className="error-message">{error}</div>
        <button className="btn btn-primary" onClick={() => check()}>Retry</button>
      </div>
    );
  }

  return (
    <div className="card">
      <h2>System Status</h2>
      
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div style={{ padding: '16px', background: health?.nvm_available ? '#f0fdf4' : '#fef2f2', borderRadius: '8px' }}>
          <div style={{ fontSize: '0.75rem', color: '#666', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '4px' }}>
            NVM Status
          </div>
          <div style={{ fontSize: '1.25rem', fontWeight: 600, color: health?.nvm_available ? '#166534' : '#dc2626' }}>
            {health?.nvm_available ? 'Available' : 'Not Available'}
          </div>
        </div>
        
        <div style={{ padding: '16px', background: '#f5f5f7', borderRadius: '8px' }}>
          <div style={{ fontSize: '0.75rem', color: '#666', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '4px' }}>
            NVM Version
          </div>
          <div style={{ fontSize: '1.25rem', fontWeight: 600, fontFamily: 'monospace' }}>
            {health?.nvm_version || 'Unknown'}
          </div>
        </div>
        
        <div style={{ padding: '16px', background: '#f5f5f7', borderRadius: '8px' }}>
          <div style={{ fontSize: '0.75rem', color: '#666', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '4px' }}>
            Service
          </div>
          <div style={{ fontSize: '1.25rem', fontWeight: 600 }}>
            {health?.service || 'Unknown'}
          </div>
        </div>
      </div>

      {script && (
        <div style={{ padding: '16px', background: '#f5f5f7', borderRadius: '8px' }}>
          <h3 style={{ marginBottom: '12px', fontSize: '0.875rem' }}>Installation Commands</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <div>
              <label style={{ fontSize: '0.75rem', color: '#666', display: 'block', marginBottom: '4px' }}>curl</label>
              <code style={{ fontSize: '0.8125rem', wordBreak: 'break-all' }}>{script.install_command_curl}</code>
            </div>
            <div>
              <label style={{ fontSize: '0.75rem', color: '#666', display: 'block', marginBottom: '4px' }}>wget</label>
              <code style={{ fontSize: '0.8125rem', wordBreak: 'break-all' }}>{script.install_command_wget}</code>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}