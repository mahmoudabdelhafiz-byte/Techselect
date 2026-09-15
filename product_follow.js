(()=>{
  const box=document.querySelector('[data-product-follow]');
  if(!box)return;
  const slug=box.getAttribute('data-product-follow');
  const button=box.querySelector('button');
  const note=box.querySelector('[data-follow-note]');
  if(!slug||!button)return;
  const endpoint='/api/product-follows/'+encodeURIComponent(slug);
  const cookie=(name)=>document.cookie.split('; ').find(v=>v.startsWith(name+'='))?.split('=').slice(1).join('=')||'';
  let authenticated=false,followed=false,busy=false;
  const render=()=>{
    button.disabled=busy;
    button.textContent=busy?'Updating…':(followed?'Following ✓':'Follow product');
    button.setAttribute('aria-pressed',followed?'true':'false');
    if(note)note.textContent=followed?'You’ll receive email when TechSelectAI detects meaningful verified changes to this product.':'Get email updates when this researched product profile meaningfully changes.';
  };
  fetch(endpoint,{credentials:'same-origin'}).then(r=>r.json()).then(data=>{
    authenticated=!!data.authenticated;followed=!!data.followed;render();
  }).catch(()=>render());
  button.addEventListener('click',()=>{
    if(!authenticated){location.href='/login?return_to='+encodeURIComponent(location.pathname);return;}
    if(busy)return;busy=true;render();
    fetch(endpoint,{method:followed?'DELETE':'POST',credentials:'same-origin',headers:{'X-CSRF-Token':decodeURIComponent(cookie('techselect_csrf'))}})
      .then(async r=>({ok:r.ok,data:await r.json()})).then(({ok,data})=>{
        if(!ok)throw new Error(data.error||'request_failed');
        followed=!!data.followed;
      }).catch(()=>{if(note)note.textContent='Could not update follow preference. Please try again.';})
      .finally(()=>{busy=false;render();});
  });
})();
