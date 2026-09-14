const STYLE_ID='techselectai-software-logo-style';
let logoMap=null;
let loading=null;

function ensureStyles(){
  if(document.getElementById(STYLE_ID))return;
  const style=document.createElement('style');
  style.id=STYLE_ID;
  style.textContent=`
    .software-card-logo{width:58px;height:58px;border-radius:12px;border:1px solid #e2e8f0;background:#fff;display:flex;align-items:center;justify-content:center;margin-bottom:14px;overflow:hidden;flex:0 0 auto}
    .software-card-logo img{display:block;max-width:46px;max-height:46px;width:auto;height:auto;object-fit:contain}
    .software-card-logo__fallback{font-size:18px;font-weight:850;color:#173f5f;letter-spacing:.02em}
  `;
  document.head.appendChild(style);
}

function initials(name){
  const words=String(name||'').trim().split(/\s+/).filter(Boolean);
  return (words.slice(0,2).map(x=>x[0]).join('')||'?').toUpperCase();
}

async function getMap(){
  if(logoMap)return logoMap;
  if(loading)return loading;
  loading=fetch('/software_logo_map.php',{headers:{Accept:'application/json'}})
    .then(r=>r.ok?r.json():Promise.reject(new Error('logo_map_failed')))
    .then(data=>{
      logoMap=new Map((data.products||[]).map(p=>[p.slug,p]));
      return logoMap;
    })
    .catch(()=>new Map())
    .finally(()=>{loading=null});
  return loading;
}

function productSlug(card){
  const href=card.getAttribute('href')||'';
  const match=href.match(/^\/software\/([a-z0-9-]+)\/?$/i);
  return match?match[1].toLowerCase():'';
}

function decorate(card,product){
  if(card.querySelector('.software-card-logo'))return;
  const mark=document.createElement('div');
  mark.className='software-card-logo';
  mark.setAttribute('aria-hidden','true');
  if(product?.logo_path){
    const img=document.createElement('img');
    img.src=product.logo_path;
    img.alt='';
    img.loading='lazy';
    img.decoding='async';
    img.addEventListener('error',()=>{
      mark.textContent='';
      const fallback=document.createElement('span');
      fallback.className='software-card-logo__fallback';
      fallback.textContent=initials(product?.name);
      mark.appendChild(fallback);
    },{once:true});
    mark.appendChild(img);
  }else{
    const fallback=document.createElement('span');
    fallback.className='software-card-logo__fallback';
    fallback.textContent=initials(product?.name||card.querySelector('h3')?.textContent);
    mark.appendChild(fallback);
  }
  card.prepend(mark);
}

async function apply(){
  if(location.pathname.replace(/\/+$/,'')!=='/software')return;
  ensureStyles();
  const map=await getMap();
  document.querySelectorAll('a.card[href^="/software/"]').forEach(card=>{
    const slug=productSlug(card);
    if(slug)decorate(card,map.get(slug));
  });
}

const observer=new MutationObserver(()=>queueMicrotask(apply));
if(document.readyState==='loading'){
  document.addEventListener('DOMContentLoaded',()=>{
    observer.observe(document.body,{childList:true,subtree:true});
    apply();
  },{once:true});
}else{
  observer.observe(document.body,{childList:true,subtree:true});
  apply();
}
