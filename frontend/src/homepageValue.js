const MARKER='techselectai-homepage-value-v1';

function ensureStyle(){
 if(document.getElementById(MARKER+'-style'))return;
 const s=document.createElement('style');s.id=MARKER+'-style';
 s.textContent=`.ts-home-outcome{font-size:20px!important;max-width:820px!important}.ts-home-support{max-width:820px;margin:12px auto 0;color:#64748b;font-size:14px;line-height:1.6}.ts-home-trust{display:flex;justify-content:center;gap:10px;flex-wrap:wrap;margin:18px auto 0}.ts-home-trust a{display:inline-flex;align-items:center;gap:6px;padding:8px 11px;border:1px solid #dbe5ec;border-radius:999px;background:#fff;color:#33506d;text-decoration:none;font-size:13px;font-weight:700}.ts-home-trust a:hover{background:#f8fbfd}.ts-home-micro{margin:12px auto 0!important;font-size:13px!important;color:#64748b!important;max-width:760px!important}@media(max-width:600px){.ts-home-trust{gap:8px}.ts-home-trust a{font-size:12px;padding:7px 9px}.ts-home-support{font-size:13px}}`;
 document.head.appendChild(s);
}

function enhance(){
 if(location.pathname!=='/'&&location.pathname!=='')return;
 const hero=document.querySelector('main .hero');if(!hero||!hero.querySelector('textarea'))return;
 ensureStyle();
 const eyebrow=hero.querySelector('.eyebrow');if(eyebrow)eyebrow.textContent='AI-powered software & technology advisory';
 const h1=hero.querySelector('h1');if(h1)h1.textContent='Decide what technology to buy — and why.';
 const p=hero.querySelector('h1 + p');if(p){p.classList.add('ts-home-outcome');p.textContent='Tell us what your business needs. TechSelectAI turns your requirements into explainable, evidence-backed technology recommendations — not just another list of tools.';}
 const textarea=hero.querySelector('textarea');if(textarea)textarea.placeholder='Example: We need a CRM for 60 users in Saudi Arabia with Arabic, WhatsApp, strong reporting and a budget under $1,000/month';
 const button=hero.querySelector('textarea + button');if(button&&!button.disabled&&button.textContent.trim()==='Start free consultation')button.textContent='Get My Recommendations';
 if(!hero.querySelector('.ts-home-support')){
   const support=document.createElement('div');support.className='ts-home-support';support.textContent='Evaluate SaaS, on-premise, self-hosted, private cloud, open-source, AI platforms, industry software, custom development — or whether keeping and extending your current system is the better choice.';
   textarea?.insertAdjacentElement('beforebegin',support);
 }
 if(!hero.querySelector('.ts-home-trust')){
   const trust=document.createElement('div');trust.className='ts-home-trust';trust.innerHTML='<a href="/methodology">Explainable scoring</a><a href="/trust">Trust & commercial disclosure</a><a href="/software">Evidence-backed software profiles</a>';
   (button||textarea)?.insertAdjacentElement('afterend',trust);
   const micro=document.createElement('p');micro.className='ts-home-micro';micro.textContent='No signup required to get recommendations. Commercial relationships never determine TechSelectAI recommendation scores or rankings.';
   trust.insertAdjacentElement('afterend',micro);
 }
}

let queued=false;function schedule(){if(queued)return;queued=true;requestAnimationFrame(()=>{queued=false;enhance()})}
const observer=new MutationObserver(schedule);
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>{enhance();observer.observe(document.getElementById('root')||document.body,{childList:true,subtree:true})},{once:true});else{enhance();observer.observe(document.getElementById('root')||document.body,{childList:true,subtree:true})}
