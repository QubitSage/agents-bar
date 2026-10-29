import {test} from 'node:test';
import assert from 'node:assert/strict';
import {webcrypto} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {verifyWebhook,hex,entitlement,signClaim,handle} from './worker.mjs';
test('webhook signature and replay window',async()=>{
 const secret='test-secret',body='{"id":"evt_1"}';
 const key=await webcrypto.subtle.importKey('raw',new TextEncoder().encode(secret),{name:'HMAC',hash:'SHA-256'},false,['sign']);
 const sig=hex(await webcrypto.subtle.sign('HMAC',key,new TextEncoder().encode('1000.'+body)));
 assert.equal(await verifyWebhook(body,'t=1000,v1='+sig,secret,1001),true);
 assert.equal(await verifyWebhook(body+'x','t=1000,v1='+sig,secret,1001),false);
 assert.equal(await verifyWebhook(body,'t=1000,v1='+sig,secret,2000),false);
});
test('expired and pending subscriptions never unlock Pro',()=>{
 assert.equal(entitlement({status:'pending',expires:9999},1000),null);
 assert.equal(entitlement({status:'active',expires:999},1000),null);
 assert.equal(entitlement({id:'a',status:'active',expires:999999},1000).sessions,12);
});
test('RSA signature can be verified with the public key',async()=>{
 const keys=await webcrypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
 const token=await signClaim(entitlement({id:'a',status:'active',expires:999999},1000),JSON.stringify(await webcrypto.subtle.exportKey('jwk',keys.privateKey)));
 const [h,p,s]=token.split('.');assert.equal(await webcrypto.subtle.verify('RSASSA-PKCS1-v1_5',keys.publicKey,Buffer.from(s,'base64url'),Buffer.from(h+'.'+p)),true);
});
test('unconfigured service fails closed',async()=>{
 const response=await handle(new Request('https://example.test/v1/license',{method:'POST',body:'{}'}),{});
 assert.equal(response.status,503);
});
test('cross-origin checkout is rejected',async()=>{
 const response=await handle(new Request('https://example.test/v1/checkout',{method:'POST',headers:{Origin:'https://other.test'}}),{DB:{},STRIPE_SECRET_KEY:'test'});
 assert.equal(response.status,403);
});
test('Python client verifies server tokens, expiry and tampering',async()=>{
 const keys=await webcrypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
 const jwk=await webcrypto.subtle.exportKey('jwk',keys.publicKey);
 const token=await signClaim(entitlement({id:'fixture',status:'active',expires:999999},1000),JSON.stringify(await webcrypto.subtle.exportKey('jwk',keys.privateKey)));
 const python=process.env.AGENTS_BAR_PYTHON||fileURLToPath(new URL('../tools/python/python.exe',import.meta.url));
 const script="import json,sys; from license import verify; d=json.load(sys.stdin); assert verify(d['token'],d['jwk'],1001)['sessions']==12; assert verify(d['token'],d['jwk'],100000) is None; assert verify(d['token'][:-8]+'AAAAAAAA',d['jwk'],1001) is None; print('Verified')";
 const result=spawnSync(python,['-c',script],{input:JSON.stringify({token,jwk}),encoding:'utf8'});
 assert.equal(result.status,0,result.stderr||String(result.error));
});
test('checkout, signed webhook, duplicate and cancellation use fixture Stripe only',async()=>{
 const rows=new Map(),events=new Set();let stripeCalls=0,subscriptionStatus='active';
 const db={prepare(sql){return {bind(...args){return {async first(){if(sql.includes('billing_events'))return events.has(args[0])?{id:args[0]}:null;if(sql.includes('key_hash'))return [...rows.values()].find(r=>r.key_hash===args[0])||null;return rows.get(args[0])||null;},async run(){if(sql.startsWith('INSERT INTO licenses'))rows.set(args[0],{id:args[0],key_hash:args[1],status:args[2],expires:args[3]});if(sql.startsWith('UPDATE'))Object.assign(rows.get(args[5]),{customer:args[0],subscription:args[1],status:args[2],expires:args[3]});if(sql.includes('INSERT OR IGNORE'))events.add(args[0]);}};}};},async batch(statements){for(const statement of statements)await statement.run();}};
 const env={DB:db,STRIPE_SECRET_KEY:'fixture',STRIPE_WEBHOOK_SECRET:'fixture-signature',STRIPE_PRICE_ID:'price_fixture',PUBLIC_URL:'https://game.test',LICENSE_PRIVATE_JWK:'fixture-not-used-by-this-test'};
 const originalFetch=globalThis.fetch;
 globalThis.fetch=async(url,options)=>{stripeCalls++;assert.ok(String(url).startsWith('https://api.stripe.com/v1/'));if(String(url).includes('/prices/'))return Response.json({currency:'usd',unit_amount:200,recurring:{interval:'month',interval_count:1}});if(String(url).endsWith('/checkout/sessions')){assert.equal(new URLSearchParams(options.body).get('mode'),'subscription');return Response.json({url:'https://checkout.stripe.test/fixture'});}return Response.json({id:'sub_fixture',customer:'cus_fixture',status:subscriptionStatus,metadata:{agents_bar_license:[...rows.keys()][0]},items:{data:[{current_period_end:Math.floor(Date.now()/1000)+86400}]}});};
 try{
  const checkout=await handle(new Request('https://game.test/v1/checkout',{method:'POST',body:'{}'}),env);
  assert.equal(checkout.status,200);const result=await checkout.json();assert.equal(result.key.length,43);assert.equal([...rows.values()][0].status,'pending');
  const notify=async(id)=>{const timestamp=Math.floor(Date.now()/1000),body=JSON.stringify({id,type:'customer.subscription.updated',data:{object:{id:'sub_fixture'}}});const key=await webcrypto.subtle.importKey('raw',new TextEncoder().encode(env.STRIPE_WEBHOOK_SECRET),{name:'HMAC',hash:'SHA-256'},false,['sign']);const sig=hex(await webcrypto.subtle.sign('HMAC',key,new TextEncoder().encode(timestamp+'.'+body)));return handle(new Request('https://game.test/v1/webhook',{method:'POST',headers:{'Stripe-Signature':`t=${timestamp},v1=${sig}`},body}),env);};
  assert.equal((await notify('evt_1')).status,200);assert.equal([...rows.values()][0].status,'active');const calls=stripeCalls;await notify('evt_1');assert.equal(stripeCalls,calls);
  subscriptionStatus='canceled';await notify('evt_2');assert.equal(entitlement([...rows.values()][0]),null);
 }finally{globalThis.fetch=originalFetch;}
});
