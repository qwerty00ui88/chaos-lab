import { useState } from 'react';

function App() {
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const callApi = async (svc) => {
    setLoading(true);
    setMessage('');
    try {
      const res = await fetch(`/api/${svc}/hello`); // 프록시 덕분에 포트 안 써도 됨
      const text = await res.text();
      setMessage(`[${svc}] 응답: ${text}`);
    } catch (err) {
      setMessage(`[${svc}] 실패: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: 20 }}>
      <h1>Chaos Lab Target App</h1>
      <button onClick={() => callApi('user')} disabled={loading}>User</button>
      <button onClick={() => callApi('catalog')} disabled={loading}>Catalog</button>
      <button onClick={() => callApi('order')} disabled={loading}>Order</button>
      <p>{loading ? '요청 중…' : message}</p>
    </div>
  );
}

export default App;
