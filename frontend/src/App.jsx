import React, { useState } from 'react';

const API = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

export default function App() {
  const [problem, setProblem] = useState('');
  const [consultation, setConsultation] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [readiness, setReadiness] = useState(null);
  const [recommendations, setRecommendations] = useState([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function start() {
    if (!problem.trim()) return;
    setBusy(true); setError('');
    try {
      const res = await fetch(`${API}/consultations`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({business_problem:problem})});
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || 'Could not start consultation');
      setConsultation(data);
      setMessages([{role:'assistant', text:"Tell me about your company, expected users, country, budget, and any must-have integrations or deployment constraints."}]);
    } catch (e) { setError(String(e.message || e)); }
    finally { setBusy(false); }
  }

  async function send() {
    if (!input.trim() || !consultation) return;
    const text = input; setInput(''); setMessages(m => [...m,{role:'user',text}]); setBusy(true); setError('');
    try {
      const res = await fetch(`${API}/consultations/${consultation.public_uuid}/messages`, {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({message:text})});
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || 'Chat request failed');
      setMessages(m => [...m,{role:'assistant',text:data.message}]);
      setReadiness(data.readiness);
    } catch(e) { setError(String(e.message || e)); }
    finally { setBusy(false); }
  }

  async function match() {
    if (!consultation) return;
    setBusy(true); setError('');
    try {
      const res = await fetch(`${API}/consultations/${consultation.public_uuid}/recommendations`, {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({scoring_version:'v1'})});
      const data = await res.json();
      if (!res.ok) {
        const d = data.detail;
        throw new Error(typeof d === 'string' ? d : `${d?.message || 'Not ready'}${d?.missing ? `: ${d.missing.join(', ')}` : ''}`);
      }
      setRecommendations(data.recommendations || []);
    } catch(e) { setError(String(e.message || e)); }
    finally { setBusy(false); }
  }

  return <div className="app-shell">
    <header><div className="brand">TechSelect <span>AI</span></div><div className="tag">Evidence-backed technology advisory</div></header>
    <main>
      {!consultation ? <section className="hero card">
        <p className="eyebrow">FREE AI CONSULTATION</p>
        <h1>Find the right technology for your business.</h1>
        <p className="lead">Describe the business problem. TechSelect AI will structure your requirements, ask only the important follow-up questions, and evaluate products using verified capability data.</p>
        <textarea value={problem} onChange={e=>setProblem(e.target.value)} placeholder="Example: We are a 300-person construction company in Egypt looking for a CRM for 35 users. We need Arabic, WhatsApp, quotation management and an API, under $15/user/month." />
        <button onClick={start} disabled={busy || problem.trim().length < 5}>{busy?'Starting…':'Start Free AI Consultation'}</button>
      </section> : <div className="consult-grid">
        <section className="chat card">
          <div className="chat-head"><div><p className="eyebrow">CONSULTATION</p><h2>Tell TechSelect AI what you need</h2></div>{readiness && <div className="readiness"><strong>{Number(readiness.readiness_score).toFixed(0)}%</strong><span>ready</span></div>}</div>
          <div className="messages">{messages.map((m,i)=><div key={i} className={`msg ${m.role}`}>{m.text}</div>)}</div>
          <div className="composer"><input value={input} onChange={e=>setInput(e.target.value)} onKeyDown={e=>e.key==='Enter'&&send()} placeholder="Add company details, budget, requirements…"/><button onClick={send} disabled={busy}>Send</button></div>
        </section>
        <aside className="card side">
          <p className="eyebrow">MATCHING STATUS</p>
          <h3>Structured recommendation engine</h3>
          <p>{readiness?.ready_for_matching ? 'Enough confirmed information is available to run matching.' : 'TechSelect AI is still collecting the critical information needed for a reliable match.'}</p>
          {readiness?.missing_critical_fields?.length>0 && <div className="missing"><strong>Still needed</strong>{readiness.missing_critical_fields.map(x=><span key={x}>{x.replaceAll('_',' ')}</span>)}</div>}
          <button onClick={match} disabled={busy || !readiness?.ready_for_matching}>Find Best Matches</button>
          <small>AI does not choose the winner. Product scores come from the deterministic database engine.</small>
        </aside>
      </div>}
      {error && <div className="error">{error}</div>}
      {recommendations.length>0 && <section className="results card"><p className="eyebrow">RECOMMENDATIONS</p><h2>Best-fit options</h2>{recommendations.map(r=><div className="result" key={r.product_name}><div><strong>#{r.recommendation_rank} {r.product_name}</strong><span>{r.recommendation_status.replaceAll('_',' ')}</span></div><div className="score">{Number(r.overall_score).toFixed(0)}%</div></div>)}</section>}
    </main>
  </div>;
}
