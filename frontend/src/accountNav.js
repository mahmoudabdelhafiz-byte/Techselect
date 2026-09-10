const NAV_ID='techselectai-account-nav';

function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));}

function ensureStyles(){
 if(document.getElementById('techselectai-account-nav-style'))return;
 const s=document.createElement('style');s.id='techselectai-account-nav-style';
 s.textContent=`.ts-account-nav{position:fixed;top:14px;right:16px;z-index:1200;display:flex;align-items:center;gap:8px;padding:7px 9px;border:1px solid rgba(148,163,184,.35);border-radius:999px;background:rgba(255,255,255,.94);box-shadow:0 8px 28px rgba(15,23,42,.12);backdrop-filter:blur(10px);font:600 13px/1.2 Inter,Arial,sans-serif}.ts-account-nav a,.ts-account-nav button{border:0;background:transparent;color:#123b67;text-decoration:none;font:inherit;cursor:pointer;padding:7px 9px;border-radius:999px}.ts-account-nav a:hover,.ts-account-nav button:hover{background:#eef6fa}.ts-account-nav .primary{background:#123b67;color:#fff}.ts-account-nav .primary:hover{background:#0f3156}.ts-account-nav .name{max-width:150px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:#475569;padding:0 5px}@media(max-width:640px){.ts-account-nav{top:auto;right:10px;left:10px;bottom:10px;justify-content:center;flex-wrap:wrap;border-radius:16px}.ts-account-nav .name{max-width:110px}}`;
 document.head.appendChild(s);
}

function mount(){
 ensureStyles();let nav=document.getElementById(NAV_ID);if(nav)return nav;
 nav=document.createElement('nav');nav.id=NAV_ID;nav.className='ts-account-nav';nav.setAttribute('aria-label','Account');document.body.appendChild(nav);return nav;
}

function signedOut(nav){nav.innerHTML='<a href="/trust">Trust & Methodology</a><a href="/login">Log in</a><a class="primary" href="/register">Create account</a>';}

function signedIn(nav,user,csrf){
 const label=user?.name||user?.email||'Account';
 nav.innerHTML=`<span class="name" title="${esc(label)}">${esc(label)}</span><a href="/trust">Trust</a><a href="/my-consultations">My Consultations</a><a href="/my-reviews">My Reviews</a><a href="/account-settings">Settings</a><button type="button" data-logout>Log out</button>`;
 nav.querySelector('[data-logout]')?.addEventListener('click',async e=>{const btn=e.currentTarget;btn.disabled=true;try{const r=await fetch('/api/auth/logout',{method:'POST',headers:{'X-CSRF-Token':csrf||''}});if(!r.ok)throw new Error('logout_failed');signedOut(nav);}catch{btn.disabled=false;}});
}

async function init(){
 if(location.pathname.startsWith('/login')||location.pathname.startsWith('/register')||location.pathname.startsWith('/verify-email')||location.pathname.startsWith('/reset-password'))return;
 const nav=mount();signedOut(nav);
 try{const r=await fetch('/api/auth/csrf',{credentials:'same-origin'});if(!r.ok)return;const d=await r.json();if(d?.user)signedIn(nav,d.user,d.csrf_token);}catch{}
}

if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init,{once:true});else init();
