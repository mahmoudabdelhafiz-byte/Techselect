const ACTIVE_KEY='techselectai.activeConsultation.v1';
const CARD_ID='consultation-cardiq-promotion';
const STYLE_ID='consultation-cardiq-promotion-style';
let evaluatingToken='';
let renderedToken='';

function activeConsultation(){
  try{return JSON.parse(sessionStorage.getItem(ACTIVE_KEY)||'null')?.c||null}catch{return null}
}
function csrfHeaders(){
  const token=localStorage.getItem('csrf')||'';
  return token?{'Content-Type':'application/json','X-CSRF-Token':token}:{'Content-Type':'application/json'};
}
function recommendationSection(){
  return Array.from(document.querySelectorAll('main section')).find(section=>{
    const h2=section.querySelector(':scope > h2');
    return h2&&h2.textContent.trim()==='Recommendations';
  })||null;
}
function ensureStyles(){
  if(document.getElementById(STYLE_ID))return;
  const style=document.createElement('style');style.id=STYLE_ID;
  style.textContent=`.consultation-cardiq-promo{margin:22px 0;padding:22px;border:1px solid #b9d8df;border-radius:18px;background:linear-gradient(135deg,#f6fbfc,#fff);box-shadow:0 10px 28px rgba(15,59,77,.08)}.consultation-cardiq-promo__label{display:inline-block;margin-bottom:10px;padding:5px 9px;border-radius:999px;background:#e8f3f5;color:#214e59;font-size:12px;font-weight:800;letter-spacing:.02em}.consultation-cardiq-promo h2{margin:0 0 8px;font-size:clamp(21px,3vw,28px);color:#17364a}.consultation-cardiq-promo p{margin:8px 0;line-height:1.6}.consultation-cardiq-promo__disclosure{display:block;margin-top:12px;color:#64748b;font-size:12px;line-height:1.5}.consultation-cardiq-promo__cta{display:inline-flex;margin-top:15px;padding:11px 15px;border-radius:10px;background:#173f5f;color:#fff!important;text-decoration:none;font-weight:800}.consultation-cardiq-promo__why{margin-top:10px;color:#526678;font-size:13px}@media(max-width:640px){.consultation-cardiq-promo{padding:18px;border-radius:14px}.consultation-cardiq-promo__cta{display:flex;justify-content:center;width:100%;box-sizing:border-box}}`;
  document.head.appendChild(style);
}
async function record(token,type,promotion){
  try{
    await fetch(`/api/consultations/${token}/promotion/${type}`,{method:'POST',headers:csrfHeaders(),body:JSON.stringify({trigger_group:promotion.trigger_group,relevance_score:promotion.relevance_score})});
  }catch{}
}
function render(section,token,promotion){
  document.getElementById(CARD_ID)?.remove();
  ensureStyles();
  const aside=document.createElement('aside');
  aside.id=CARD_ID;aside.className='consultation-cardiq-promo';aside.setAttribute('aria-label','Sponsored CardIQ recommendation');
  const label=document.createElement('div');label.className='consultation-cardiq-promo__label';label.textContent=promotion.label||'Sponsored · Barmageyat product';
  const title=document.createElement('h2');title.textContent=promotion.headline||'Corporate identity control and anti-impersonation protection';
  const message=document.createElement('p');message.textContent=promotion.message||'';
  const why=document.createElement('div');why.className='consultation-cardiq-promo__why';why.textContent='Related solution — shown separately from your ranked software recommendations.';
  const disclosure=document.createElement('small');disclosure.className='consultation-cardiq-promo__disclosure';disclosure.textContent=promotion.disclosure||'CardIQ is a Barmageyat product. Sponsorship does not affect TechSelectAI rankings.';
  const cta=document.createElement('a');cta.className='consultation-cardiq-promo__cta';cta.href=promotion.url||'/software/cardiq';cta.textContent=promotion.cta||'Explore CardIQ identity protection';
  cta.addEventListener('click',()=>{record(token,'click',promotion)});
  aside.append(label,title,message,why,disclosure,cta);
  section.insertAdjacentElement('afterend',aside);
  renderedToken=token;
  const impressionKey=`techselectai.promo.impression.${token}`;
  if(!sessionStorage.getItem(impressionKey)){
    sessionStorage.setItem(impressionKey,'1');
    record(token,'impression',promotion);
  }
}
async function evaluate(){
  const section=recommendationSection();
  const c=activeConsultation();
  const token=c?.public_token||'';
  if(!section||!token){document.getElementById(CARD_ID)?.remove();renderedToken='';return;}
  if(renderedToken===token&&document.getElementById(CARD_ID))return;
  if(evaluatingToken===token)return;
  evaluatingToken=token;
  try{
    const r=await fetch(`/api/consultations/${token}/promotion`,{headers:{Accept:'application/json'}});
    if(!r.ok)return;
    const data=await r.json();
    if(data.promotion)render(section,token,data.promotion);else{document.getElementById(CARD_ID)?.remove();renderedToken='';}
  }catch{}finally{if(evaluatingToken===token)evaluatingToken='';}
}

const observer=new MutationObserver(()=>queueMicrotask(evaluate));
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>{observer.observe(document.body,{childList:true,subtree:true});evaluate()},{once:true});
else{observer.observe(document.body,{childList:true,subtree:true});evaluate();}
