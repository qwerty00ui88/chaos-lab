import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import './App.css';

const API_BASE = '';

async function httpPost(path, payload) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
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
  const [stackEnabled, setStackEnabled] = useState(false);
  const [pendingState, setPendingState] = useState(null);

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

  const syncStackStatus = useCallback(async () => {
    try {
      const status = await httpGet('/api/terraform/status');
      if (status && typeof status.enabled === 'boolean') {
        setStackEnabled(status.enabled);
        if (pendingState !== null && status.enabled === pendingState) {
          setPendingState(null);
          setActionMessage(`Target stack ${status.enabled ? 'ON' : 'OFF'} is ready.`);
        }
      }
    } catch (err) {
      console.error('Failed to synchronise stack status', err);
    }
  }, [pendingState]);

  const podCrashDefaults = useMemo(
    () => ({ namespace: '', labelSelector: 'app=svc-order', maxPods: 1 }),
    []
  );
  const cpuStressSeconds = 30;

  const sortedTasks = useMemo(
    () => [...tasks].sort((a, b) => (b.createdAt ? new Date(b.createdAt) - new Date(a.createdAt) : 0)),
    [tasks]
  );

  const latestTask = sortedTasks[0] ?? null;

  useEffect(() => {
    syncStackStatus();
  }, [syncStackStatus]);

  const lastSyncedTaskIdRef = useRef(null);

  useEffect(() => {
    if (!latestTask) {
      return;
    }
    if (!['SUCCEEDED', 'FAILED'].includes(latestTask.state)) {
      if (['terraform-apply', 'terraform-destroy'].includes(latestTask.name)) {
        setPendingState(latestTask.name === 'terraform-apply');
      }
      return;
    }
    if (latestTask.name !== 'terraform-apply' && latestTask.name !== 'terraform-destroy') {
      return;
    }
    if (latestTask.state === 'FAILED') {
      setPendingState(null);
    }
    if (lastSyncedTaskIdRef.current === latestTask.id) {
      return;
    }
    lastSyncedTaskIdRef.current = latestTask.id;
    syncStackStatus();
  }, [latestTask, syncStackStatus]);

  const kpiStats = useMemo(
    () => ({
      p95: '210 ms',
      rps: '125 /s',
      rpsChange: '+3%',
      errorRate: '0.3%'
    }),
    []
  );

  const heroKpis = useMemo(
    () => [
      { label: 'p95 latency', value: kpiStats.p95 },
      { label: 'Requests / s', value: kpiStats.rps, sub: kpiStats.rpsChange },
      { label: '5xx error rate', value: kpiStats.errorRate }
    ],
    [kpiStats]
  );

  const environmentName = import.meta.env.VITE_ENVIRONMENT || import.meta.env.VITE_CHAOS_ENV || 'dev';
  const targetAppUrl = import.meta.env.VITE_TARGET_URL;
  const targetAppHost = useMemo(() => targetAppUrl.replace(/^https?:\/\//, ''), [targetAppUrl]);

  const handleToggleStack = useCallback(
    async (nextEnabled) => {
      setIsSubmitting(true);
      setPendingState(nextEnabled);
      setActionError(null);
      setActionMessage(null);
      try {
        const path = nextEnabled ? '/api/terraform/apply' : '/api/terraform/destroy';
        const response = await httpPost(path, {});
        setActionMessage(`Target stack ${nextEnabled ? 'ON' : 'OFF'} triggered (task ${response.taskId ?? 'unknown'})`);
        await refreshTasks();
        if (response.taskId) {
          await loadTaskDetails(response.taskId);
        }
      } catch (err) {
        setActionError(`Toggle failed: ${err.message}`);
        setPendingState(null);
      } finally {
        setIsSubmitting(false);
        await syncStackStatus();
      }
    },
    [loadTaskDetails, refreshTasks, syncStackStatus]
  );

  const handleChaosButton = useCallback(
    async (path, description, body) => {
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
    },
    []
  );

  const triggerPodCrash = useCallback(() => {
    handleChaosButton('/api/chaos/pod-crash', 'Crash pods', {
      labelSelector: podCrashDefaults.labelSelector,
      namespace: podCrashDefaults.namespace || undefined,
      maxPods: podCrashDefaults.maxPods
    });
  }, [handleChaosButton, podCrashDefaults]);

  const resetActionState = () => {
    setActionMessage(null);
    setActionError(null);
  };

  const [liveLogs, setLiveLogs] = useState([]);
  const eventSourceRef = useRef(null);

  const logStreamUrl = import.meta.env.VITE_LOG_STREAM_URL;

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

  const selectedSummary = selectedTask?.summary ?? null;
  const selectedSteps = selectedTask?.steps ?? [];
  const selectedLogs = selectedTask?.logs ?? selectedTask?.output ?? [];

  const handleOpenTarget = () => {
    window.open(targetAppUrl, '_blank', 'noopener');
  };

  const handleCopyTarget = async () => {
    try {
      await navigator.clipboard.writeText(targetAppUrl);
      setActionMessage('Target URL copied to clipboard');
      setTimeout(() => setActionMessage(null), 2000);
    } catch (err) {
      setActionError('Copy failed');
      setTimeout(() => setActionError(null), 2000);
    }
  };

  const scenarioCatalog = [
    {
      id: 'order-latency',
      name: 'Order latency',
      description: 'Inject a 5s delay into the `/order` path to mimic slow upstreams.',
      tone: 'secondary',
      actionLabel: 'Trigger latency',
      action: () => handleChaosButton('/api/chaos/order-latency', 'Order latency')
    },
    {
      id: 'pod-crash',
      name: 'Crash pods',
      description: 'Kill one `svc-order` replica and observe ReplicaSet self-healing.',
      tone: 'secondary',
      actionLabel: 'Crash pods',
      action: triggerPodCrash
    },
    {
      id: 'cpu-spike',
      name: 'CPU spike',
      description: `Run a ${cpuStressSeconds}s CPU burner to provoke HPA activity.`,
      tone: 'secondary',
      actionLabel: 'Spike CPU',
      action: () => handleChaosButton('/api/chaos/cpu-high', 'CPU stress', { seconds: cpuStressSeconds })
    },
    {
      id: 'oom',
      name: 'Force OOM',
      description: 'Allocate excessive memory to force an OOMKilled restart.',
      tone: 'danger',
      actionLabel: 'Force OOM',
      action: () => handleChaosButton('/api/chaos/oom', 'OOM fault')
    },
    {
      id: 'db-failover',
      name: 'RDS failover',
      description: 'Promote the standby instance to validate database failover handling.',
      tone: 'danger',
      actionLabel: 'Trigger failover',
      action: () => handleChaosButton('/api/chaos/db-failover', 'DB failover')
    }
  ];

  const stackStatusLabel =
    pendingState !== null ? (pendingState ? 'Turning ON…' : 'Turning OFF…') : stackEnabled ? 'Online' : 'Offline';
  const statusClass = pendingState !== null ? (pendingState ? 'pending-on' : 'pending-off') : stackEnabled ? 'online' : 'offline';
  const stackButtonLabel =
    pendingState === null
      ? stackEnabled
        ? 'Turn OFF stack'
        : 'Turn ON stack'
      : pendingState
      ? 'Turning ON…'
      : 'Turning OFF…';
  const latestTaskStateClass = latestTask?.state ? latestTask.state.toLowerCase() : '';
  const latestTaskTimestamp = latestTask?.createdAt ? new Date(latestTask.createdAt).toLocaleString() : '—';

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar__brand">
          <div className="logo-dot">CL</div>
          <div className="sidebar__brand-text">
            <span className="eyebrow">Chaos Lab</span>
            <h1>Control Center</h1>
            <p>Launch, disrupt, observe, and reset your target environment.</p>
          </div>
        </div>

        <div className="sidebar__section">
          <span className="eyebrow">Environment</span>
          <div className="chip-group">
            <span className="chip chip--primary">{environmentName}</span>
            <span className="chip">{targetAppHost}</span>
          </div>
          <div className="sidebar__state">
            <span className="sidebar__label">Stack status</span>
            <span className={`status-pill ${statusClass}`}>{stackStatusLabel}</span>
            {pendingState !== null && (
              <span className="status-note">{pendingState ? 'Provisioning resources… this can take several minutes.' : 'Destroying resources… hang tight.'}</span>
            )}
          </div>
          <button
            type="button"
            className="btn secondary full"
            onClick={() => handleToggleStack(!stackEnabled)}
            disabled={isSubmitting || pendingState !== null}
          >
            {stackButtonLabel}
          </button>
        </div>

        {latestTask && (
          <div className="sidebar__section">
            <span className="eyebrow">Latest run</span>
            <div className="sidebar__task">
              <strong>{latestTask.name}</strong>
              <span className={`badge ${latestTaskStateClass}`}>{latestTask.state}</span>
            </div>
            <span className="sidebar__meta muted">{latestTaskTimestamp}</span>
          </div>
        )}

        <div className="sidebar__section">
          <span className="eyebrow">Automation</span>
          <label className="toggle">
            <input type="checkbox" checked={autoRefresh} onChange={() => setAutoRefresh((prev) => !prev)} />
            <span className="slider" aria-hidden="true"></span>
            <span className="toggle-label">Auto refresh</span>
          </label>
          <button type="button" className="btn outline small" onClick={refreshTasks} disabled={taskLoading}>
            Refresh now
          </button>
        </div>

        <div className="sidebar__foot">
          <p>Target app served via CloudFront → ALB → EKS with RDS & DynamoDB backing services.</p>
        </div>
      </aside>

      <div className="workspace">
        <div className="main-stage">
          <header className={`panel hero ${stackEnabled ? 'online' : 'offline'}`}>
            <div className="hero__head">
              <div>
                <span className="eyebrow">Target environment</span>
                <h2>{targetAppHost}</h2>
                <p>
                  Keep the dashboard always-on while spinning the target stack on demand. Launch experiments to showcase
                  resilience and recovery stories.
                </p>
              </div>
              <div className="hero__status">
                <span className={`status-pill ${stackEnabled ? 'online' : 'offline'}`}>{stackStatusLabel}</span>
              </div>
            </div>

            <div className="hero__meta">
              <dl>
                <div>
                  <dt>Region</dt>
                  <dd>ap-northeast-2</dd>
                </div>
                <div>
                  <dt>Services</dt>
                  <dd>EKS (svc-user/order/catalog), RDS, DynamoDB</dd>
                </div>
                <div>
                  <dt>Observability</dt>
                  <dd>CloudWatch Logs via log-streamer SSE</dd>
                </div>
              </dl>
              <div className="hero__actions">
                <button type="button" className="btn primary" onClick={handleOpenTarget} disabled={!stackEnabled}>
                  Visit target site
                </button>
                <button type="button" className="btn outline" onClick={handleCopyTarget}>
                  Copy link
                </button>
              </div>
            </div>

            <div className="hero__metrics">
              {heroKpis.map((metric) => (
                <div className="metric-card" key={metric.label}>
                  <span>{metric.label}</span>
                  <strong>{metric.value}</strong>
                  {metric.sub && <em className="positive">{metric.sub}</em>}
                </div>
              ))}
            </div>
          </header>

          <section className="panel scenario-panel">
            <div className="panel-head">
              <div>
                <span className="eyebrow">Chaos experiments</span>
                <h2>Failure drill catalog</h2>
              </div>
              <p>Curated scenarios to highlight latency, availability, and durability responses in the stack.</p>
            </div>
            <ul className="scenario-grid">
              {scenarioCatalog.map((item) => (
                <li className="scenario-card" key={item.id}>
                  <div>
                    <strong>{item.name}</strong>
                    <p>{item.description}</p>
                  </div>
                  <button
                    type="button"
                    className={`btn ${item.tone === 'danger' ? 'danger' : 'secondary'}`}
                    onClick={item.action}
                    disabled={isSubmitting}
                  >
                    {item.actionLabel}
                  </button>
                </li>
              ))}
            </ul>
          </section>

          <div className="panel-grid">
            <section className="panel tasks-panel">
              <div className="panel-head">
                <div>
                  <span className="eyebrow">Automation runs</span>
                  <h2>Terraform · Helm history</h2>
                </div>
                <span className="muted">{taskLoading ? 'Loading…' : `${tasks.length} historical runs`}</span>
              </div>
              {taskError && <p className="alert error">{taskError}</p>}
              <div className="table-wrapper">
                <table className="data-table">
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
                          <span className={`badge ${task.state ? task.state.toLowerCase() : ''}`}>{task.state}</span>
                        </td>
                        <td>{task.createdAt ? new Date(task.createdAt).toLocaleString() : '—'}</td>
                        <td>{task.exitCode ?? '—'}</td>
                      </tr>
                    ))}
                    {sortedTasks.length === 0 && (
                      <tr>
                        <td colSpan={4}>No tasks yet. Toggle the stack to create one.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </section>

            <section className="panel detail-panel">
              <div className="panel-head">
                <div>
                  <span className="eyebrow">Task detail</span>
                  <h2>Execution timeline</h2>
                </div>
                <span className="muted">
                  {selectedSummary ? selectedSummary.name ?? selectedSummary.id : 'Select a task to inspect details.'}
                </span>
              </div>
              {selectedSummary ? (
                <div className="detail-body">
                  <div className="detail-grid">
                    <div>
                      <span className="label">State</span>
                      <span className={`badge ${selectedSummary.state ? selectedSummary.state.toLowerCase() : ''}`}>
                        {selectedSummary.state ?? 'UNKNOWN'}
                      </span>
                    </div>
                    <div>
                      <span className="label">Created</span>
                      <strong>
                        {selectedSummary.createdAt ? new Date(selectedSummary.createdAt).toLocaleString() : '—'}
                      </strong>
                    </div>
                    <div>
                      <span className="label">Exit code</span>
                      <strong>{selectedSummary.exitCode ?? '—'}</strong>
                    </div>
                    <div>
                      <span className="label">Triggered by</span>
                      <strong>{selectedSummary.trigger ?? 'dashboard'}</strong>
                    </div>
                  </div>
                  {selectedSteps.length > 0 && (
                    <div className="detail-steps">
                      <h3>Steps</h3>
                      <ol>
                        {selectedSteps.map((step) => (
                          <li key={step.id || step.name}>
                            <span>{step.name ?? step.id}</span>
                            <span className={`badge ${step.state ? step.state.toLowerCase() : ''}`}>
                              {step.state ?? 'UNKNOWN'}
                            </span>
                          </li>
                        ))}
                      </ol>
                    </div>
                  )}
                  {selectedLogs.length > 0 && (
                    <div className="detail-logs">
                      <h3>Recent output</h3>
                      <div className="log-scroll">
                        {selectedLogs.map((entry, index) => {
                          const displayValue =
                            typeof entry === 'string'
                              ? entry
                              : entry?.line ?? entry?.message ?? JSON.stringify(entry);
                          return <code key={`${displayValue}-${index}`}>{displayValue}</code>;
                        })}
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                <div className="empty-state">Select a task to view its timeline, execution steps, and output.</div>
              )}
            </section>
          </div>

          <section className="panel logs-panel">
            <div className="panel-head">
              <div>
                <span className="eyebrow">Live telemetry</span>
                <h2>Log stream</h2>
              </div>
              <span className="muted">Server-Sent Events exposed by the log-streamer service.</span>
            </div>
            <div className="logs-wrapper">
              <table className="data-table logs-table">
                <thead>
                  <tr>
                    <th>Time</th>
                    <th>Source</th>
                    <th>Level</th>
                    <th>Message</th>
                  </tr>
                </thead>
                <tbody>
                  {logs.length > 0 ? (
                    logs.map((entry) => (
                      <tr key={`${entry.timestamp}-${entry.traceId || entry.message}`}>
                        <td>{new Date(entry.timestamp).toLocaleTimeString()}</td>
                        <td>{entry.source ?? 'n/a'}</td>
                        <td>
                          <span className={`badge ${entry.level ? entry.level.toLowerCase() : ''}`}>
                            {entry.level ?? 'INFO'}
                          </span>
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
            </div>
          </section>
        </div>

        <footer className="status-bar" onClick={resetActionState}>
          <span className="status-label">Status</span>
          {actionMessage && <span className="status success">{actionMessage}</span>}
          {actionError && <span className="status error">{actionError}</span>}
          {!actionMessage && !actionError && <span className="status muted">Ready.</span>}
        </footer>
      </div>
    </div>
  );
}
