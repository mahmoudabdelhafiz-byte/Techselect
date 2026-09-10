(()=>{
  const seen=new Set();
  const originalFetch=window.fetch.bind(window);
  const esc=v=>String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));
  const csrfHeaders=()=>{const token=localStorage.getItem('csrf');return token?{'Content-Type':'application/json','X-CSRF-Token':token}:{'Content-Type':'application/json'};};
  const eventBody=p=>JSON.stringify({trigger_group:p.trigger_group,relevance_score:p.relevance_score});
  async function record(token,type,p){try{await originalFetch(`/api/consultations/${token}/promotion/${type}`,{method:'POST',headers:csrfHeaders(),body:eventBody(p)});}catch{}}
  function findRecommendationsSection(){return [...document.querySelectorAll('section')].find(s=>s.querySelector(':scope > h2')?.textContent?.trim()==='Recommendations');}
  function render(token,p){
    if(!p||seen.has(token)||document.querySelector(`[data-cardiq-promotion-for="${token}"]`))return;
    const section=findRecommendationsSection();
    if(!section){setTimeout(()=>render(token,p),120);return;}
    const aside=document.createElement('aside');
    aside.className='ts-contextual-promo';aside.dataset.cardiqPromotionFor=token;
    aside.innerHTML=`<div class="ts-contextual-promo__label">${esc(p.label||'Sponsored · Barmageyat product')}</div><div class="ts-contextual-promo__body"><div><div class="ts-contextual-promo__eyebrow">Related identity protection</div><h3>${esc(p.headline)}</h3><p>${esc(p.message)}</p><p class="ts-contextual-promo__disclosure">${esc(p.disclosure)}</p></div><a class="ts-contextual-promo__cta" href="${esc(p.url||'/software/cardiq')}">${esc(p.cta||'Explore CardIQ identity protection')}</a></div>`;
    section.insertAdjacentElement('afterend',aside);seen.add(token);record(token,'impression',p);
    const link=aside.querySelector('a');if(link)link.addEventListener('click',()=>record(token,'click',p),{once:true});
  }
  async function evaluate(token){
    try{const r=await originalFetch(`/api/consultations/${token}/promotion`,{credentials:'same-origin'});if(!r.ok)return;const d=await r.json();if(d?.promotion)render(token,d.promotion);}catch{}
  }
  window.fetch=async(input,init)=>{
    const response=await originalFetch(input,init);
    try{
      const url=typeof input==='string'?input:input?.url||'';
      const m=url.match(/\/api\/consultations\/([a-f0-9]{48})\/recommendations(?:\?|$)/i);
      if(m&&response.ok)setTimeout(()=>evaluate(m[1]),0);
    }catch{}
    return response;
  };
  const style=document.createElement('style');style.textContent=`
  .ts-contextual-promo{margin:24px 0;padding:20px;border:1px solid #cbd5e1;border-radius:16px;background:#f8fbfd;box-shadow:0 8px 28px rgba(15,23,42,.05)}
  .ts-contextual-promo__label{display:inline-flex;padding:5px 9px;border-radius:999px;background:#e2e8f0;color:#334155;font-size:12px;font-weight:700;letter-spacing:.01em}
  .ts-contextual-promo__body{display:flex;justify-content:space-between;align-items:center;gap:24px;margin-top:12px}
  .ts-contextual-promo__eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.08em;color:#0f766e;font-weight:700}
  .ts-contextual-promo h3{margin:6px 0 8px;font-size:22px;color:#0f172a}.ts-contextual-promo p{margin:0 0 8px;line-height:1.55;color:#334155}
  .ts-contextual-promo__disclosure{font-size:12px!important;color:#64748b!important;max-width:760px}
  .ts-contextual-promo__cta{display:inline-flex;align-items:center;justify-content:center;white-space:nowrap;text-decoration:none;font-weight:700;border-radius:10px;padding:11px 14px;background:#0f766e;color:#fff}
  @media(max-width:720px){.ts-contextual-promo__body{display:block}.ts-contextual-promo__cta{margin-top:10px;white-space:normal;width:100%;box-sizing:border-box}}
  `;document.head.appendChild(style);
})();
