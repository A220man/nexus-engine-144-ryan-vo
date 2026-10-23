import { useState, useEffect, useCallback } from 'react';
import { api } from '../api/client';
import type { NodeVersion, InstallRequest, UseRequest, ConfigFileResponse, HealthResponse, InstallScriptResponse } from '../types/api';

export function useVersions(lts: boolean = false) {
  const [versions, setVersions] = useState<NodeVersion[]>([]);
  const [current, setCurrent] = useState<string | undefined>();
  const [defaultVersion, setDefaultVersion] = useState<string | undefined>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchVersions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listVersions(lts);
      setVersions(data.versions);
      setCurrent(data.current);
      setDefaultVersion(data.default);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch versions');
    } finally {
      setLoading(false);
    }
  }, [lts]);

  useEffect(() => {
    fetchVersions();
  }, [fetchVersions]);

  return { versions, current, defaultVersion, loading, error, refetch: fetchVersions };
}

export function useRemoteVersions(lts: boolean = false) {
  const [versions, setVersions] = useState<NodeVersion[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchVersions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listRemoteVersions(lts);
      setVersions(data.versions);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch remote versions');
    } finally {
      setLoading(false);
    }
  }, [lts]);

  useEffect(() => {
    fetchVersions();
  }, [fetchVersions]);

  return { versions, loading, error, refetch: fetchVersions };
}

export function useInstallVersion() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const install = async (request: InstallRequest) => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.installVersion(request);
      return result;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Installation failed';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { install, loading, error };
}

export function useUseVersion() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const useVersion = async (request: UseRequest) => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.useVersion(request);
      return result;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to switch version';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { useVersion, loading, error };
}

export function useConfigDetection() {
  const [config, setConfig] = useState<ConfigFileResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const detect = useCallback(async (cwd?: string) => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.detectConfig(cwd);
      setConfig(data);
      return data;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to detect config';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    detect();
  }, [detect]);

  return { config, loading, error, detect };
}

export function useHealth() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const check = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.checkHealth();
      setHealth(data);
      return data;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Health check failed';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    check();
  }, [check]);

  return { health, loading, error, check };
}

export function useInstallScript() {
  const [script, setScript] = useState<InstallScriptResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.getInstallScript();
      setScript(data);
      return data;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch install script';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { script, loading, error };
}