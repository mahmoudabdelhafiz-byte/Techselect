(()=>{
  const root=document.querySelector('[data-product-community]');if(!root)return;
  const slug=root.getAttribute('data-product-community');if(!slug)return;
  const endpoint='/api/product_community.php?slug='+encodeURIComponent(slug);
  const cookie=(name)=>document.cookie.split('; ').find(v=>v.startsWith(name+'='))?.split('=').slice(1).join('=')||'';
  const state={authenticated:false,sort:'recent',posts:[]};
  const list=root.querySelector('[data-community-list]'),composer=root.querySelector('[data-community-composer]'),status=root.querySelector('[data-community-status]');
  const make=(tag,cls,text)=>{const n=document.createElement(tag);if(cls)n.className=cls;if(text!==undefined)n.textContent=text;return n;};
  const when=(value)=>{const d=new Date(String(value).replace(' ','T')+'Z');if(Number.isNaN(d.getTime()))return value;return d.toLocaleDateString(undefined,{year:'numeric',month:'short',day:'numeric'});};
  const postRequest=async(payload)=>{const r=await fetch(endpoint,{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json','X-CSRF-Token':decodeURIComponent(cookie('techselect_csrf'))},body:JSON.stringify(payload)});const data=await r.json().catch(()=>({}));if(!r.ok)throw new Error(data.error||'request_failed');return data;};
  const login=()=>{location.href='/login?return_to='+encodeURIComponent(location.pathname+'#community');};
  const actionButton=(label,handler)=>{const b=make('button','community-action',label);b.type='button';b.addEventListener('click',handler);return b;};
  const renderPost=(post,isReply=false)=>{
    const card=make('article',isReply?'community-post community-reply':'community-post');card.dataset.postId=post.id;
    const meta=make('div','community-meta');meta.append(make('strong','',post.author_label),document.createTextNode(' · '+when(post.created_at)));
    if(!isReply){const badge=make('span','community-type',post.type==='question'?'Question':'Discussion');meta.prepend(badge);}
    card.append(meta,make('p','community-body',post.body));
    const actions=make('div','community-actions');
    const helpful=actionButton((post.viewer_helpful?'Helpful ✓':'Helpful')+' · '+post.helpful_count,async()=>{
      if(!state.authenticated)return login();helpful.disabled=true;
      try{const r=await postRequest({action:'helpful',post_id:post.id});post.viewer_helpful=!!r.helpful;post.helpful_count=r.helpful_count||0;helpful.textContent=(post.viewer_helpful?'Helpful ✓':'Helpful')+' · '+post.helpful_count;}catch(e){showStatus('Could not update Helpful. Please try again.',true);}finally{helpful.disabled=false;}
    });actions.append(helpful);
    if(!isReply)actions.append(actionButton('Reply',()=>state.authenticated?showReply(card,post.id):login()));
    if(!post.viewer_owns)actions.append(actionButton('Report',async()=>{
      if(!state.authenticated)return login();if(!confirm('Report this community post for moderator review?'))return;
      try{await postRequest({action:'report',post_id:post.id,reason:'other'});showStatus('Report submitted for moderator review.');}catch(e){showStatus('Could not submit report. Please try again.',true);}
    }));
    card.append(actions);
    if(post.replies?.length){const replies=make('div','community-replies');post.replies.forEach(r=>replies.append(renderPost(r,true)));card.append(replies);}
    return card;
  };
  const showReply=(card,parentId)=>{
    if(card.querySelector('.community-reply-form'))return;
    const form=make('form','community-reply-form'),ta=document.createElement('textarea');ta.maxLength=3000;ta.required=true;ta.placeholder='Write a helpful reply…';
    const submit=make('button','btn secondary','Post reply');submit.type='submit';form.append(ta,submit);
    form.addEventListener('submit',async e=>{e.preventDefault();const body=ta.value.trim();if(body.length<3)return;submit.disabled=true;try{await postRequest({action:'post',parent_id:parentId,body});await load();}catch(err){showStatus(err.message==='verified_email_required'?'Please verify your email before participating.':'Could not post reply. Please try again.',true);}finally{submit.disabled=false;}});
    card.append(form);ta.focus();
  };
  const showStatus=(msg,error=false)=>{if(!status)return;status.textContent=msg;status.classList.toggle('error',error);status.hidden=false;setTimeout(()=>{status.hidden=true;},5000);};
  const render=()=>{
    if(!list)return;list.replaceChildren();
    if(!state.posts.length){list.append(make('div','community-empty','No discussions yet. Be the first to ask a useful question about this product.'));return;}
    state.posts.forEach(p=>list.append(renderPost(p)));
  };
  const load=async()=>{
    if(list)list.setAttribute('aria-busy','true');
    try{const r=await fetch(endpoint+'&sort='+encodeURIComponent(state.sort),{credentials:'same-origin'});const data=await r.json();if(!r.ok)throw new Error(data.error||'community_unavailable');state.authenticated=!!data.authenticated;state.posts=Array.isArray(data.posts)?data.posts:[];render();}
    catch(e){if(list){list.replaceChildren(make('div','community-empty','Community discussions are temporarily unavailable.'));}}
    finally{if(list)list.removeAttribute('aria-busy');}
  };
  root.querySelectorAll('[data-community-sort]').forEach(b=>b.addEventListener('click',()=>{state.sort=b.dataset.communitySort==='helpful'?'helpful':'recent';root.querySelectorAll('[data-community-sort]').forEach(x=>x.classList.toggle('active',x===b));load();}));
  if(composer){composer.addEventListener('submit',async e=>{e.preventDefault();if(!state.authenticated)return login();const type=composer.querySelector('[name="type"]').value,ta=composer.querySelector('[name="body"]'),body=ta.value.trim(),submit=composer.querySelector('button[type="submit"]');if(body.length<3)return;submit.disabled=true;try{await postRequest({action:'post',type,body});ta.value='';showStatus('Posted to the community.');await load();}catch(err){showStatus(err.message==='verified_email_required'?'Please verify your email before participating.':'Could not publish your post. Please try again.',true);}finally{submit.disabled=false;}});}
  load();
})();
