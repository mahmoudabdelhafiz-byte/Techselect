(()=>{
  const box=document.querySelector('[data-product-follow]');if(!box)return;
  const slug=box.getAttribute('data-product-follow'),button=box.querySelector('button'),note=box.querySelector('[data-follow-note]');if(!slug||!button)return;
  const endpoint='/api/product_follows.php?slug='+encodeURIComponent(slug);
  const cookie=(name)=>document.cookie.split('; ').find(v=>v.startsWith(name+'='))?.split('=').slice(1).join('=')||'';
  let authenticated=false,followed=false,community=false,busy=false;
  const preference=document.createElement('label');
  preference.className='ts-follow-community-pref';
  preference.hidden=true;
  preference.innerHTML='<input type="checkbox" data-community-follow-notifications> <span>Email me about new community questions and replies</span>';
  box.appendChild(preference);
  const communityInput=preference.querySelector('input');
  const render=()=>{
    button.disabled=busy;button.textContent=busy?'Updating…':(followed?'Following ✓':'Follow product');button.setAttribute('aria-pressed',followed?'true':'false');
    preference.hidden=!authenticated||!followed;communityInput.disabled=busy;communityInput.checked=community;
    if(note)note.textContent=followed?'You’ll receive email when TechSelectAI detects meaningful verified changes to this product.':'Get email updates when this researched product profile meaningfully changes.';
  };
  fetch(endpoint,{credentials:'same-origin'}).then(r=>r.json()).then(data=>{authenticated=!!data.authenticated;followed=!!data.followed;community=!!data.community_notifications;render();}).catch(()=>render());
  button.addEventListener('click',()=>{if(!authenticated){location.href='/login?return_to='+encodeURIComponent(location.pathname);return;}if(busy)return;busy=true;render();fetch(endpoint,{method:followed?'DELETE':'POST',credentials:'same-origin',headers:{'X-CSRF-Token':decodeURIComponent(cookie('techselect_csrf'))}}).then(async r=>({ok:r.ok,data:await r.json()})).then(({ok,data})=>{if(!ok)throw new Error(data.error||'request_failed');followed=!!data.followed;community=!!data.community_notifications;}).catch(()=>{if(note)note.textContent='Could not update follow preference. Please try again.';}).finally(()=>{busy=false;render();});});
  communityInput.addEventListener('change',()=>{
    if(!authenticated||!followed||busy){render();return;}
    const desired=communityInput.checked;busy=true;render();
    fetch(endpoint,{method:'PATCH',credentials:'same-origin',headers:{'Content-Type':'application/json','X-CSRF-Token':decodeURIComponent(cookie('techselect_csrf'))},body:JSON.stringify({community_notifications:desired})})
      .then(async r=>({ok:r.ok,data:await r.json()})).then(({ok,data})=>{if(!ok)throw new Error(data.error||'request_failed');community=!!data.community_notifications;})
      .catch(()=>{community=!desired;if(note)note.textContent='Could not update community notification preference. Please try again.';})
      .finally(()=>{busy=false;render();});
  });
})();
