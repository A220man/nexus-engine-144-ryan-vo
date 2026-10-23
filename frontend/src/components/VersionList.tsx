import type { NodeVersion } from '../types/api';

interface VersionListProps {
  versions: NodeVersion[];
  currentVersion?: string;
  defaultVersion?: string;
  onUse: (version: string) => void;
  onUninstall: (version: string) => void;
  onSetDefault: (version: string) => void;
  loading?: boolean;
}

export function VersionList({
  versions,
  currentVersion,
  defaultVersion,
  onUse,
  onUninstall,
  onSetDefault,
  loading = false,
}: VersionListProps) {
  if (loading) {
    return (
      <div className="loading">
        <div className="spinner" />
        <span>Loading versions...</span>
      </div>
    );
  }

  if (versions.length === 0) {
    return (
      <div className="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
          <path d="M12 2L2 7l10 5 10-5-10-5z" />
          <path d="M2 17l10 5 10-5" />
          <path d="M2 12l10 5 10-5" />
        </svg>
        <p>No Node.js versions installed</p>
        <p className="empty-state-hint">Install a version to get started</p>
      </div>
    );
  }

  return (
    <ul className="version-list">
      {versions.map((version) => {
        const isCurrent = version.is_current || version.version === currentVersion;
        const isDefault = version.is_default || version.version === defaultVersion;
        
        let badgeClass = 'version-badge';
        if (version.status === 'active' || isCurrent) badgeClass += ' active';
        else if (version.status === 'installed') badgeClass += ' installed';
        else if (version.status === 'lts') badgeClass += ' lts';
        else badgeClass += ' available';

        return (
          <li key={version.version} className={`version-item ${isCurrent ? 'current' : ''}`}>
            <div className="version-info">
              <span className={badgeClass}>
                {version.status === 'active' ? 'Active' : 
                 version.status === 'installed' ? 'Installed' :
                 version.status === 'lts' ? 'LTS' : 'Available'}
              </span>
              <span className="version-number">{version.version}</span>
              {version.lts_name && (
                <span className="version-badge lts">{version.lts_name}</span>
              )}
              {isCurrent && <span className="current-indicator">CURRENT</span>}
              {isDefault && <span className="current-indicator">DEFAULT</span>}
            </div>
            <div style={{ display: 'flex', gap: '8px' }}>
              {!isCurrent && (
                <button 
                  className="btn btn-secondary"
                  onClick={() => onUse(version.version)}
                  disabled={loading}
                >
                  Use
                </button>
              )}
              {version.status === 'installed' || version.status === 'active' ? (
                <>
                  <button 
                    className="btn btn-secondary"
                    onClick={() => onSetDefault(version.version)}
                    disabled={loading || isDefault}
                  >
                    {isDefault ? 'Default' : 'Set Default'}
                  </button>
                  <button 
                    className="btn btn-danger"
                    onClick={() => {
                      if (window.confirm(`Uninstall ${version.version}?`)) {
                        onUninstall(version.version);
                      }
                    }}
                    disabled={loading || isCurrent}
                  >
                    Uninstall
                  </button>
                </>
              ) : null}
            </div>
          </li>
        );
      })}
    </ul>
  );
}