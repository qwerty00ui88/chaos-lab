import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import './App.css';

const API_BASE = '';

async function httpPost(path, payload) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: payload ? JSON.stringify(payload) : undefined
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }

  return res.json();
}

async function httpGet(path) {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  return res.json();
}

function useTasks(autoRefresh) {
  const [tasks, setTasks] = useState([]);
  const [selectedTask, setSelectedTask] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const refreshTasks = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await httpGet('/api/tasks');
      const normalized = response.map((item) => item.task ?? item);
      setTasks(normalized);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  const loadTaskDetails = useCallback(async (taskId) => {
    try {
      const details = await httpGet(`/api/tasks/${taskId}`);
      setSelectedTask(details);
    } catch (err) {
      setError(err.message);
    }
  }, []);

  useEffect(() => {
    refreshTasks();
  }, [refreshTasks]);

  useEffect(() => {
    if (!autoRefresh) {
      return undefined;
    }
    const interval = setInterval(refreshTasks, 5000);
    return () => clearInterval(interval);
  }, [autoRefresh, refreshTasks]);

  useEffect(() => {
    if (tasks.length > 0 && !selectedTask) {
      loadTaskDetails(tasks[0].id);
    }
  }, [tasks, selectedTask, loadTaskDetails]);

  return {
    tasks,
    selectedTask,
    loading,
    error,
    refreshTasks,
    loadTaskDetails,
    setSelectedTask
  };
}

export default function App() {
  const [autoRefresh, setAutoRefresh] = useState(true);

  const {
    tasks,
    selectedTask,
    loading: taskLoading,
    error: taskError,
    refreshTasks,
    loadTaskDetails,
    setSelectedTask
  } = useTasks(autoRefresh);

  const [actionMessage, setActionMessage] = useState(null);
  const [actionError, setActionError] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [podCrashForm, setPodCrashForm] = useState({
    namespace: '',
    labelSelector: 'app=svc-order',
    maxPods: 1
  });
  const [cpuStressSeconds, setCpuStressSeconds] = useState(30);

  const sortedTasks = useMemo(
    () => [...tasks].sort((a, b) => (b.createdAt ? new Date(b.createdAt) - new Date(a.createdAt) : 0)),
    [tasks]
  );

  const kpiStats = useMemo(
    () => ({
      p95: '210 ms',
      rps: '125 /s',
      rpsChange: '▲ 03%',
      errorRate: '0.3%'
    }),
    []
  );

  const handleTerraformAction = async (type) => {
    setIsSubmitting(true);
    setActionError(null);
    setActionMessage(null);
    try {
      const path =
        type === 'apply' ? '/api/terraform/apply' : type === 'destroy' ? '/api/terraform/destroy' : '/api/helm/rollout';

      const response = await httpPost(path, {});
      setActionMessage(`Triggered ${type} task ${response.taskId}`);
      await refreshTasks();
      if (response.taskId) {
        await loadTaskDetails(response.taskId);
      }
    } catch (err) {
      setActionError(`Terraform action failed: ${err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handlePodCrash = async (event) => {
    event.preventDefault();
    setIsSubmitting(true);
    setActionError(null);
    try {
      const body = {
        namespace: podCrashForm.namespace || undefined,
        labelSelector: podCrashForm.labelSelector,
        maxPods: Number(podCrashForm.maxPods) || 1
      };
      const response = await httpPost('/api/chaos/pod-crash', body);
      setActionMessage(`Pod crash triggered: ${response.status}`);
    } catch (err) {
      setActionError(`Pod crash failed: ${err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChaosButton = async (path, description, body) => {
    setIsSubmitting(true);
    setActionError(null);
    try {
      const response = await httpPost(path, body ?? {});
      setActionMessage(`${description} → ${response.status}`);
    } catch (err) {
      setActionError(`${description} failed: ${err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetActionState = () => {
    setActionMessage(null);
    setActionError(null);
  };

  const [liveLogs, setLiveLogs] = useState([]);
  const eventSourceRef = useRef(null);

  const logStreamUrl = import.meta.env.VITE_LOG_STREAM_URL || 'http://localhost:8090/api/logs/stream';

  useEffect(() => {
    const controller = new AbortController();
    const source = new EventSource(logStreamUrl);
    eventSourceRef.current = source;

    source.addEventListener('log', (event) => {
      try {
        const data = JSON.parse(event.data);
        setLiveLogs((prev) => {
          const next = [...prev, data];
          if (next.length > 200) {
            next.shift();
          }
          return next;
        });
      } catch (err) {
        console.error('Failed to parse log event', err);
      }
    });

    source.onerror = () => {
      source.close();
      setTimeout(() => {
        if (!controller.signal.aborted) {
          setLiveLogs((prev) => [
            ...prev,
            {
              message: 'Disconnected from log stream',
              level: 'WARN',
              timestamp: new Date().toISOString(),
              source: 'log-streamer',
              traceId: 'reconnect'
            }
          ]);
        }
      }, 0);
    };

    return () => {
      controller.abort();
      source.close();
    };
  }, [logStreamUrl]);

  const logs = liveLogs;

  return (
    <div className="dashboard">
      <div className="main">
        <header className="main-header">
          <div>
            <h1>Chaos Dashboard</h1>
            <p className="tagline">Track resilience metrics while running experiments on the target app.</p>
          </div>
          <div className="header-controls">
            <button className="ghost" onClick={refreshTasks} disabled={taskLoading}>
              ↻ Refresh
            </button>
            <button className={`ghost ${autoRefresh ? 'active' : ''}`} onClick={() => setAutoRefresh((prev) => !prev)}>
              {autoRefresh ? 'Auto · ON' : 'Auto · OFF'}
            </button>
          </div>
        </header>

        <main className="main-body">
          <section className="top-grid">
            <div className="card kpi-card">
              <h2>KPI</h2>
              <div className="kpi-metrics">
                <div>
                  <span className="kpi-label">p95</span>
                  <strong className="kpi-value">{kpiStats.p95}</strong>
                </div>
                <div>
                  <span className="kpi-label">RPS</span>
                  <strong className="kpi-value">{kpiStats.rps}</strong>
                  <span className="kpi-trend">{kpiStats.rpsChange}</span>
                </div>
                <div>
                  <span className="kpi-label">5xx</span>
                  <strong className="kpi-value">{kpiStats.errorRate}</strong>
                </div>
              </div>
              <div className="sparkline-placeholder">Shaded during experiment</div>
            </div>

            <div className="card preview-card">
              <h2>Target App Preview</h2>
              <div className="preview-body">
                <h3>app.example.com</h3>
                <p>User Catalog · Order</p>
                <small>
                  During experiments, observe latency spikes, error rates, and timeouts impacting customer journeys.
                </small>
              </div>
            </div>
          </section>

          <section className="card experiment-card">
            <header>
              <h2>Experiment Controls</h2>
              <span className="hint">Select a fault to inject while monitoring KPIs.</span>
            </header>

            <div className="experiment-buttons">
              <button onClick={() => handleChaosButton('/api/chaos/order-latency', 'Order latency')} disabled={isSubmitting}>
                Latency 5s
              </button>
              <button
                onClick={() => handleChaosButton('/api/chaos/pod-crash', 'Crash pods', {
                  labelSelector: podCrashForm.labelSelector,
                  namespace: podCrashForm.namespace || undefined,
                  maxPods: Number(podCrashForm.maxPods) || 1
                })}
                disabled={isSubmitting}
              >
                Crash Pods
              </button>
              <button
                onClick={() => handleChaosButton('/api/chaos/cpu-high', 'CPU stress', { seconds: Number(cpuStressSeconds) || 30 })}
                disabled={isSubmitting}
              >
                CPU {cpuStressSeconds}s
              </button>
              <button onClick={() => handleChaosButton('/api/chaos/oom', 'OOM fault')} disabled={isSubmitting}>
                OOM Fault
              </button>
              <button onClick={() => handleChaosButton('/api/chaos/db-failover', 'DB failover')} disabled={isSubmitting}>
                DB Failover
              </button>
            </div>

            <form className="crash-form" onSubmit={handlePodCrash}>
              <label>
                Namespace
                <input
                  type="text"
                  value={podCrashForm.namespace}
                  placeholder="target-app"
                  onChange={(e) => setPodCrashForm((prev) => ({ ...prev, namespace: e.target.value }))}
                />
              </label>
              <label>
                Label selector
                <input
                  type="text"
                  required
                  value={podCrashForm.labelSelector}
                  onChange={(e) => setPodCrashForm((prev) => ({ ...prev, labelSelector: e.target.value }))}
                />
              </label>
              <label>
                Max pods
                <input
                  type="number"
                  min="1"
                  value={podCrashForm.maxPods}
                  onChange={(e) => setPodCrashForm((prev) => ({ ...prev, maxPods: e.target.value }))}
                />
              </label>
              <button type="submit" className="ghost" disabled={isSubmitting}>
                Apply Pod Crash
              </button>
            </form>
          </section>

          <section className="card tasks-panel">
            <header className="tasks-head">
              <h2>Terraform Tasks</h2>
              <span className="tasks-meta">{taskLoading ? 'Loading…' : `${tasks.length} total`}</span>
            </header>
            {taskError && <p className="status error">{taskError}</p>}
            <table className="table">
              <thead>
                <tr>
                  <th>Task</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th>Exit</th>
                </tr>
              </thead>
              <tbody>
                {sortedTasks.map((task) => (
                  <tr
                    key={task.id}
                    className={selectedTask?.summary?.id === task.id ? 'active' : ''}
                    onClick={() => {
                      setSelectedTask(null);
                      loadTaskDetails(task.id);
                    }}
                  >
                    <td>{task.name}</td>
                    <td>
                      <span className={`badge ${task.state.toLowerCase()}`}>{task.state}</span>
                    </td>
                    <td>{task.createdAt ? new Date(task.createdAt).toLocaleString() : '—'}</td>
                    <td>{task.exitCode ?? '—'}</td>
                  </tr>
                ))}
                {sortedTasks.length === 0 && (
                  <tr>
                    <td colSpan={4}>No tasks yet. Trigger an action to begin.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </section>

          <section className="card logs-card">
            <header className="logs-head">
              <div>
                <h2>Live Logs</h2>
                <span className="logs-status">SSE connected to log-streamer (last {logs.length} entries)</span>
              </div>
              <div className="phase-indicator">
                <span>BEFORE</span>
                <span className="active">DEGRADED</span>
                <span>RECOVERING</span>
                <code>00.233</code>
              </div>
            </header>
            <table className="table logs-table">
              <thead>
                <tr>
                  <th>ts</th>
                  <th>source</th>
                  <th>level</th>
                  <th>message</th>
                </tr>
              </thead>
              <tbody>
                {logs.length > 0 ? (
                  logs.map((entry) => (
                    <tr key={`${entry.timestamp}-${entry.traceId || entry.message}`}>
                      <td>{new Date(entry.timestamp).toLocaleTimeString()}</td>
                      <td>{entry.source ?? 'n/a'}</td>
                      <td>
                        <span className={`badge ${entry.level ? entry.level.toLowerCase() : ''}`}>{entry.level ?? 'INFO'}</span>
                      </td>
                      <td className="mono">{entry.message ?? ''}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4}>No log output yet.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </section>
        </main>

        <footer className="main-footer">
          <strong>Status</strong>
          {actionMessage && (
            <span className="status success" onClick={resetActionState}>
              {actionMessage}
            </span>
          )}
          {actionError && (
            <span className="status error" onClick={resetActionState}>
              {actionError}
            </span>
          )}
          {!actionMessage && !actionError && <span className="status muted">Ready.</span>}
        </footer>
      </div>
    </div>
  );
}
