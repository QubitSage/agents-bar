const enc=new TextEncoder();
const json=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
export const hex=bytes=>Array.from(new Uint8Array(bytes),b=>b.toString(16).padStart(2,'0')).join('');
export const digest=async value=>hex(await crypto.subtle.digest('SHA-256',enc.encode(value)));
const b64=bytes=>btoa(String.fromCharCode(...new Uint8Array(bytes))).replaceAll('+','-').replaceAll('/','_').replace(/=+$/,'');
const secret=()=>b64(crypto.getRandomValues(new Uint8Array(32)));
const same=(a,b)=>{if(a.length!==b.length)return false;let different=0;for(let i=0;i<a.length;i++)different|=a.charCodeAt(i)^b.charCodeAt(i);return different===0;};

export async function verifyWebhook(body,header,secret,now=Math.floor(Date.now()/1000)){
  const fields=String(header).split(',').map(x=>x.split('='));
  const timestamp=Number(fields.find(([k])=>k==='t')?.[1]);
  if(!Number.isFinite(timestamp)||Math.abs(now-timestamp)>300)return false;
  const key=await crypto.subtle.importKey('raw',enc.encode(secret),{name:'HMAC',hash:'SHA-256'},false,['sign']);
  const signature=hex(await crypto.subtle.sign('HMAC',key,enc.encode(`${timestamp}.${body}`)));
  return fields.some(([k,v])=>k==='v1'&&same(signature,v||''));
}

export function entitlement(license,now=Math.floor(Date.now()/1000)){
  if(!license||license.status!=='active'||license.expires<=now)return null;
  return {aud:'agents-bar',sub:license.id,plan:'pro',sessions:12,historyDays:90,iat:now,exp:Math.min(now+86400,license.expires)};
}

export async function signClaim(claim,jwk){
  const key=await crypto.subtle.importKey('jwk',JSON.parse(jwk),{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['sign']);
  const input=b64(enc.encode(JSON.stringify({alg:'RS256',typ:'JWT'})))+'.'+b64(enc.encode(JSON.stringify(claim)));
  return input+'.'+b64(await crypto.subtle.sign('RSASSA-PKCS1-v1_5',key,enc.encode(input)));
}

async function stripe(env,path,params){
  const response=await fetch('https://api.stripe.com/v1/'+path,{method:params?'POST':'GET',headers:{Authorization:'Bearer '+env.STRIPE_SECRET_KEY,...(params?{'Content-Type':'application/x-www-form-urlencoded'}:{})},body:params?new URLSearchParams(params):undefined});
  if(!response.ok)throw new Error('Billing provider unavailable');
  return response.json();
}

class InputError extends Error {constructor(message,status=400){super(message);this.status=status;}}
export async function limitedText(request,limit){
  const length=Number(request.headers.get('Content-Length')||0);
  if(!Number.isFinite(length)||length<0)throw new InputError('Invalid body size');
  if(length>limit)throw new InputError('Body too large',413);
  if(!request.body)return '';
  const reader=request.body.getReader();const decoder=new TextDecoder('utf-8',{fatal:true});let size=0,text='';
  try{while(true){const {value,done}=await reader.read();if(done)break;size+=value.byteLength;if(size>limit){await reader.cancel();throw new InputError('Body too large',413);}text+=decoder.decode(value,{stream:true});}return text+decoder.decode();}
  finally{reader.releaseLock();}
}
async function body(request){
  try{const result=JSON.parse(await limitedText(request,8192));if(!result||Array.isArray(result)||typeof result!=='object')throw new InputError('Expected object');return result;}
  catch(error){if(error instanceof InputError)throw error;throw new InputError('Invalid JSON');}
}

async function licenseFor(env,input){
  if(typeof input.key!=='string'||!/^[A-Za-z0-9_-]{43}$/.test(input.key))return null;
  return env.DB.prepare('SELECT * FROM licenses WHERE key_hash=?').bind(await digest(input.key)).first();
}

async function webhook(request,env){
  const raw=await limitedText(request,262144);
  if(!await verifyWebhook(raw,request.headers.get('Stripe-Signature'),env.STRIPE_WEBHOOK_SECRET))return json({error:'Invalid signature'},400);
  const event=JSON.parse(raw);
  if(!event.id||typeof event.type!=='string')return json({error:'Invalid event'},400);
  if(await env.DB.prepare('SELECT id FROM billing_events WHERE id=?').bind(event.id).first())return json({received:true});
  const object=event.data?.object;
  let subscription=event.type.startsWith('customer.subscription.')?object?.id:object?.subscription;
  if(!subscription && event.type.startsWith('invoice.'))subscription=object?.parent?.subscription_details?.subscription;
  if(typeof subscription!=='string')return json({received:true,ignored:true});
  // Fetch current state rather than trust webhook arrival order.
  const current=await stripe(env,'subscriptions/'+encodeURIComponent(subscription));
  const id=current.metadata?.agents_bar_license;
  const existing=id?await env.DB.prepare('SELECT id FROM licenses WHERE id=?').bind(id).first():null;
  if(!existing)return json({received:true,ignored:true});
  const period=Number(current.current_period_end||current.items?.data?.[0]?.current_period_end||0);
  const status=current.status==='active'?'active':'inactive';
  await env.DB.batch([
    env.DB.prepare('UPDATE licenses SET customer=?,subscription=?,status=?,expires=?,updated=? WHERE id=?').bind(current.customer,subscription,status,period,Math.floor(Date.now()/1000),id),
    env.DB.prepare('INSERT OR IGNORE INTO billing_events(id,created) VALUES (?,?)').bind(event.id,Math.floor(Date.now()/1000))
  ]);
  return json({received:true});
}

export async function handle(request,env){
  const url=new URL(request.url),path=url.pathname;
  if(path==='/health')return json({ok:true,version:'0.9.9'});
  if(path==='/'&&request.method==='GET')return new Response(PORTAL,{headers:{'Content-Type':'text/html; charset=utf-8','Content-Security-Policy':"default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'",'Referrer-Policy':'no-referrer'}});
  if(request.method!=='POST')return json({error:'Not found'},404);
  if(!env.DB||!env.STRIPE_SECRET_KEY)return json({error:'Billing not configured'},503);
  if(path==='/v1/webhook')return env.STRIPE_WEBHOOK_SECRET?webhook(request,env):json({error:'Webhook not configured'},503);
  const origin=request.headers.get('Origin');
  if(origin&&origin!==url.origin)return json({error:'Origin rejected'},403);
  // Configure a binding per route in production; never collect usage or prompts here.
  if(env.RATE_LIMITER){const {success}=await env.RATE_LIMITER.limit({key:request.headers.get('CF-Connecting-IP')||'unknown'});if(!success)return json({error:'Try later'},429);}
  if(path==='/v1/checkout'){
    await body(request);
    if(!env.STRIPE_PRICE_ID||!env.PUBLIC_URL||!env.LICENSE_PRIVATE_JWK)return json({error:'Billing not fully configured'},503);
    const price=await stripe(env,'prices/'+encodeURIComponent(env.STRIPE_PRICE_ID));
    if(price.currency!=='usd'||price.unit_amount!==200||price.recurring?.interval!=='month'||price.recurring?.interval_count!==1)return json({error:'Expected USD 2 per month price'},503);
    const id=crypto.randomUUID(),key=secret(),recovery=secret();
    await env.DB.prepare('INSERT INTO licenses(id,key_hash,status,expires,updated) VALUES (?,?,?,?,?)').bind(id,await digest(key),'pending',0,Math.floor(Date.now()/1000)).run();
    const checkout=await stripe(env,'checkout/sessions',{'mode':'subscription','line_items[0][price]':env.STRIPE_PRICE_ID,'line_items[0][quantity]':'1','subscription_data[metadata][agents_bar_license]':id,'success_url':env.PUBLIC_URL+'/?checkout=success','cancel_url':env.PUBLIC_URL+'/?checkout=cancelled'});
    await env.DB.prepare('INSERT INTO license_recovery(license_id,recovery_hash) VALUES (?,?)').bind(id,await digest(recovery)).run();
    return json({url:checkout.url,key,recovery});
  }
  const input=await body(request);
  if(path==='/v1/recover'){
    if(typeof input.recovery!=='string'||!/^[A-Za-z0-9_-]{43}$/.test(input.recovery))return json({error:'Invalid recovery code'},403);
    const oldHash=await digest(input.recovery);
    const owner=await env.DB.prepare('SELECT license_id FROM license_recovery WHERE recovery_hash=?').bind(oldHash).first();
    if(!owner)return json({error:'Invalid or already used recovery code'},403);
    const key=secret(),recovery=secret();
    // A single transaction consumes the old code and replaces both secrets.
    const result=await env.DB.batch([
      env.DB.prepare('UPDATE licenses SET key_hash=? WHERE id=? AND EXISTS (SELECT 1 FROM license_recovery WHERE license_id=? AND recovery_hash=?)').bind(await digest(key),owner.license_id,owner.license_id,oldHash),
      env.DB.prepare('UPDATE license_recovery SET recovery_hash=? WHERE license_id=? AND recovery_hash=?').bind(await digest(recovery),owner.license_id,oldHash)
    ]);
    if(result.some(r=>r.meta?.changes!==1))return json({error:'Recovery was already used; use the newest kit'},409);
    return json({key,recovery});
  }
  const license=await licenseFor(env,input);
  if(path==='/v1/license'){
    const claim=entitlement(license);
    if(!claim)return json({error:'No active subscription'},403);
    if(!env.LICENSE_PRIVATE_JWK)return json({error:'Signing not configured'},503);
    return json({token:await signClaim(claim,env.LICENSE_PRIVATE_JWK),plan:'pro'});
  }
  if(path==='/v1/billing-portal'){
    if(!license?.customer)return json({error:'Unknown subscription'},403);
    const portal=await stripe(env,'billing_portal/sessions',{'customer':license.customer,'return_url':env.PUBLIC_URL+'/'});
    return json({url:portal.url});
  }
  return json({error:'Not found'},404);
}

export default {async fetch(request,env){try{return await handle(request,env);}catch(error){return error instanceof InputError?json({error:error.message},error.status):json({error:'Service temporarily unavailable'},503);}}};

const PORTAL=`<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Agents Bar Pro</title><style>body{font:16px system-ui;background:#151c29;color:#eee5d5;max-width:640px;margin:7vh auto;padding:24px}h1{color:#ddba77}button,input{font:inherit;padding:12px;margin:8px 0;max-width:100%;box-sizing:border-box}input{width:100%}button{cursor:pointer}small{color:#bac6d4}#key{overflow-wrap:anywhere}section{border:1px solid #58647b;padding:16px;margin-top:24px}a{color:#e4c383}</style><h1>Agents Bar Pro</h1><h2>US$ 2 / mês</h2><p>Até 12 sessões simultâneas e 90 dias de histórico local de uso. Gratuito: 3 sessões e 24 horas.</p><p>O Pro não muda o poder dos personagens. A assinatura é recorrente; gerencie ou cancele pelo portal de cobrança.</p><button id="subscribe">Preparar assinatura</button><p id="status" role="status"></p><section id="kit" hidden><h3>Guarde o acesso antes de continuar</h3><p>Este arquivo contém sua chave e um código para recuperá-la. Armazene em local privado.</p><button id="download">Baixar kit de recuperação</button><button id="payment" hidden>Ir para pagamento</button></section><p id="key"></p><label>Chave da assinatura<input id="license" type="password" autocomplete="off"></label><button id="manage">Gerenciar assinatura</button><section><h3>Recuperar minha chave</h3><label>Código do kit de recuperação<input id="recovery" type="password" autocomplete="off"></label><button id="recover">Gerar novo acesso</button><small>O código é usado uma vez. Depois da recuperação, baixe o novo kit. Sem chave e sem kit, a recuperação exige suporte; não há recuperação automática por e-mail nesta versão.</small></section><p><small>Nenhum prompt, código, conversa ou histórico de uso é enviado ao servidor de cobrança.</small></p><script>
const s=document.getElementById('status'),k=document.getElementById('license');let latest=null;k.value=localStorage.getItem('agents-bar-key')||'';
if(location.search.includes('success'))s.textContent='Pagamento em processamento. A chave funciona após a confirmação da assinatura.';
async function send(path,data){const r=await fetch(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});const v=await r.json();if(!r.ok)throw Error(v.error||'Tente novamente');return v;}
function show(v){latest=v;k.value=v.key;localStorage.setItem('agents-bar-key',v.key);document.getElementById('key').textContent='Chave: '+v.key;document.getElementById('kit').hidden=false;document.getElementById('payment').hidden=true;}
document.getElementById('download').onclick=()=>{if(!latest)return;const blob=new Blob([JSON.stringify({product:'Agents Bar',key:latest.key,recovery:latest.recovery},null,2)],{type:'application/json'});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='agents-bar-recuperacao.json';a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000);document.getElementById('payment').hidden=!latest.url;};
document.getElementById('payment').onclick=()=>{if(latest?.url)location.assign(latest.url);};
document.getElementById('subscribe').onclick=async function(){this.disabled=true;try{show(await send('/v1/checkout',{}));s.textContent='Baixe o kit e depois siga para o pagamento.';}catch(e){s.textContent=e.message;this.disabled=false;}};
document.getElementById('recover').onclick=async function(){this.disabled=true;try{show(await send('/v1/recover',{recovery:document.getElementById('recovery').value.trim()}));document.getElementById('recovery').value='';s.textContent='Acesso renovado. Baixe o novo kit e use a nova chave no jogo.';}catch(e){s.textContent=e.message;}finally{this.disabled=false;}};
document.getElementById('manage').onclick=async()=>{try{const v=await send('/v1/billing-portal',{key:k.value.trim()});location.assign(v.url);}catch(e){s.textContent=e.message;}};
</script></html>`;
