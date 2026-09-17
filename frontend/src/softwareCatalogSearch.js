const STYLE_ID='techselectai-software-catalog-search-style';

function addStyles(){
  if(document.getElementById(STYLE_ID))return;
  const s=document.createElement('style');s.id=STYLE_ID;
  s.textContent=`.ts-catalog-search{position:relative;max-width:720px;margin:20px 0 26px}.ts-catalog-search label{display:block;font-weight:750;margin-bottom:7px}.ts-catalog-search input{width:100%;box-sizing:border-box;padding:13px 44px 13px 14px;border:1px solid #cbd5e1;border-radius:12px;background:#fff;font:inherit;color:#172033;box-shadow:0 1px 2px rgba(15,23,42,.04)}.ts-catalog-search input:focus{outline:3px solid rgba(37,99,235,.14);border-color:#2563eb}.ts-catalog-search .clear{position:absolute;right:8px;top:31px;width:32px;height:32px;border:0;border-radius:8px;background:transparent;color:#64748b;font-size:20px;cursor:pointer}.ts-catalog-search .clear:hover{background:#f1f5f9}.ts-catalog-suggestions{position:absolute;z-index:100;width:100%;box-sizing:border-box;margin:6px 0 0;padding:6px;list-style:none;background:#fff;border:1px solid #dbe3ec;border-radius:12px;box-shadow:0 14px 34px rgba(15,23,42,.14);max-height:360px;overflow:auto}.ts-catalog-suggestions[hidden]{display:none}.ts-catalog-suggestion{display:block;width:100%;text-align:left;border:0;background:#fff;padding:10px 11px;border-radius:9px;cursor:pointer;color:#172033}.ts-catalog-suggestion:hover,.ts-catalog-suggestion[aria-selected="true"]{background:#eef6ff}.ts-catalog-suggestion strong{display:block;font-size:14px}.ts-catalog-suggestion span{display:block;color:#64748b;font-size:12px;margin-top:2px}.ts-catalog-search-meta{color:#64748b;font-size:13px;margin-top:8px}.ts-catalog-no-results{padding:24px;border:1px dashed #cbd5e1;border-radius:14px;color:#64748b;background:#fff}`;
  document.head.appendChild(s);
}

function norm(v){return String(v||'').toLowerCase().normalize('NFKD').replace(/[\u0300-\u036f]/g,'').trim()}

function init(){
  if(location.pathname.replace(/\/$/,'')!=='/software')return;
  const main=document.querySelector('main');if(!main||main.querySelector('[data-catalog-search]'))return false;
  const heading=main.querySelector('h1');const intro=heading?.nextElementSibling;const grid=main.querySelector('.grid');
  if(!heading||!grid)return false;
  addStyles();
  const wrap=document.createElement('div');wrap.className='ts-catalog-search';wrap.setAttribute('data-catalog-search','');
  wrap.innerHTML='<label for="software-catalog-search">Search software catalog</label><input id="software-catalog-search" type="search" autocomplete="off" spellcheck="false" placeholder="Start typing a software, vendor, or category…" role="combobox" aria-autocomplete="list" aria-expanded="false" aria-controls="software-catalog-suggestions"><button class="clear" type="button" aria-label="Clear search" hidden>×</button><ul id="software-catalog-suggestions" class="ts-catalog-suggestions" role="listbox" hidden></ul><div class="ts-catalog-search-meta" aria-live="polite"></div>';
  (intro||heading).insertAdjacentElement('afterend',wrap);
  const input=wrap.querySelector('input'),list=wrap.querySelector('ul'),meta=wrap.querySelector('.ts-catalog-search-meta'),clear=wrap.querySelector('.clear');
  const noResults=document.createElement('div');noResults.className='ts-catalog-no-results';noResults.textContent='No software matches your search.';noResults.hidden=true;grid.insertAdjacentElement('afterend',noResults);
  let products=[],active=-1;
  const cards=()=>Array.from(grid.querySelectorAll('a.card[href^="/software/"]'));
  const applyFilter=()=>{
    const q=norm(input.value);let shown=0;
    cards().forEach(card=>{const hay=norm(card.textContent);const visible=!q||hay.includes(q);card.hidden=!visible;if(visible)shown++});
    noResults.hidden=shown!==0;meta.textContent=q?`${shown} software result${shown===1?'':'s'}`:`${cards().length} software products`;clear.hidden=!input.value;
  };
  const matches=()=>{
    const q=norm(input.value);if(!q)return[];
    return products.filter(p=>norm(`${p.name} ${p.vendor||''} ${p.category||''}`).includes(q)).sort((a,b)=>{
      const an=norm(a.name),bn=norm(b.name);const ae=an===q?0:an.startsWith(q)?1:2;const be=bn===q?0:bn.startsWith(q)?1:2;return ae-be||a.name.localeCompare(b.name);
    }).slice(0,8);
  };
  const close=()=>{active=-1;list.hidden=true;input.setAttribute('aria-expanded','false');input.removeAttribute('aria-activedescendant')};
  const renderSuggestions=()=>{
    const rows=matches();active=-1;
    if(!rows.length){close();return}
    list.innerHTML=rows.map((p,i)=>`<li role="option" id="software-suggestion-${i}" aria-selected="false"><button type="button" class="ts-catalog-suggestion" data-slug="${String(p.slug).replace(/"/g,'&quot;')}"><strong>${String(p.name).replace(/[&<>]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[m]))}</strong><span>${String([p.vendor,p.category].filter(Boolean).join(' · ')).replace(/[&<>]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[m]))}</span></button></li>`).join('');
    list.hidden=false;input.setAttribute('aria-expanded','true');
    list.querySelectorAll('button').forEach(btn=>btn.addEventListener('click',()=>{location.href='/software/'+encodeURIComponent(btn.dataset.slug)}));
  };
  const setActive=index=>{
    const opts=Array.from(list.querySelectorAll('[role="option"]'));if(!opts.length)return;
    active=Math.max(0,Math.min(index,opts.length-1));opts.forEach((o,i)=>o.setAttribute('aria-selected',i===active?'true':'false'));input.setAttribute('aria-activedescendant',opts[active].id);opts[active].scrollIntoView({block:'nearest'});
  };
  input.addEventListener('input',()=>{applyFilter();renderSuggestions()});
  input.addEventListener('focus',renderSuggestions);
  input.addEventListener('keydown',e=>{
    const opts=list.querySelectorAll('[role="option"]');
    if(e.key==='ArrowDown'&&opts.length){e.preventDefault();setActive(active+1)}
    else if(e.key==='ArrowUp'&&opts.length){e.preventDefault();setActive(active<0?opts.length-1:active-1)}
    else if(e.key==='Enter'&&active>=0&&opts[active]){e.preventDefault();opts[active].querySelector('button')?.click()}
    else if(e.key==='Escape')close();
  });
  clear.addEventListener('click',()=>{input.value='';applyFilter();close();input.focus()});
  document.addEventListener('click',e=>{if(!wrap.contains(e.target))close()});
  fetch('/api/software',{credentials:'same-origin'}).then(r=>r.ok?r.json():Promise.reject()).then(d=>{products=Array.isArray(d.products)?d.products:[];applyFilter()}).catch(()=>{products=[];applyFilter()});
  applyFilter();
  return true;
}

function boot(){if(init())return;const o=new MutationObserver(()=>{if(init())o.disconnect()});o.observe(document.documentElement,{childList:true,subtree:true});setTimeout(()=>o.disconnect(),10000)}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
