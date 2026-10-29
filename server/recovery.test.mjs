import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import {handle,digest} from './worker.mjs';
function fixture(){
 const db=new DatabaseSync(':memory:');db.exec(readFileSync(new URL('./schema.sql',import.meta.url),'utf8'));
 const binding={prepare(sql){return {bind(...values){const stmt=db.prepare(sql);return {async first(){return stmt.get(...values)||null;},async run(){return {meta:{changes:Number(stmt.run(...values).changes)}};}};}};},async batch(statements){db.exec('BEGIN');try{const result=[];for(const s of statements)result.push(await s.run());db.exec('COMMIT');return result;}catch(e){db.exec('ROLLBACK');throw e;}}};
 const env={DB:binding,STRIPE_SECRET_KEY:'fixture',STRIPE_PRICE_ID:'price_fixture',PUBLIC_URL:'https://fixture.test',LICENSE_PRIVATE_JWK:'test-only'};
 const send=(path,data)=>handle(new Request('https://fixture.test/v1/'+path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}),env);
 return {db,env,send};
}
test('recovery kit rotates both secrets, prevents replay and retains subscription',async()=>{
 const {db,send}=fixture();const original=globalThis.fetch;
 globalThis.fetch=async(url,options)=>{
  if(String(url).includes('/prices/'))return Response.json({currency:'usd',unit_amount:200,recurring:{interval:'month',interval_count:1}});
  if(String(url).includes('billing_portal')){assert.equal(new URLSearchParams(options.body).get('customer'),'cus_fixture');return Response.json({url:'https://billing.stripe.test/fixture'});}
  return Response.json({url:'https://checkout.stripe.test/fixture'});
 };
 try {
  const created=await (await send('checkout',{})).json();assert.equal(created.recovery.length,43);
  const row=db.prepare('SELECT * FROM licenses').get();assert.notEqual(row.key_hash,created.key);
  assert.notEqual(db.prepare('SELECT * FROM license_recovery').get().recovery_hash,created.recovery);
  db.prepare("UPDATE licenses SET status='active',customer='cus_fixture',expires=?").run(Math.floor(Date.now()/1000)+86400);
  assert.equal((await send('recover',{recovery:'wrong'})).status,403);
  const response=await send('recover',{recovery:created.recovery});assert.equal(response.status,200);const recovered=await response.json();
  assert.notEqual(recovered.key,created.key);assert.notEqual(recovered.recovery,created.recovery);
  assert.equal((await send('recover',{recovery:created.recovery})).status,403);
  assert.equal((await send('billing-portal',{key:created.key})).status,403);
  assert.equal((await send('billing-portal',{key:recovered.key})).status,200);
  assert.equal(db.prepare('SELECT * FROM licenses').get().status,'active');
  assert.equal((await send('recover',{recovery:recovered.recovery})).status,200);
 } finally {globalThis.fetch=original;db.close();}
});
test('recovery transaction failure keeps both original credentials',async()=>{
 const {db,send}=fixture();const key='A'.repeat(43),recovery='B'.repeat(43);
 db.prepare("INSERT INTO licenses(id,key_hash,status,expires,updated) VALUES ('one',?,'pending',0,0)").run(await digest(key));
 db.prepare('INSERT INTO license_recovery VALUES (?,?)').run('one',await digest(recovery));
 db.exec("CREATE TRIGGER fail_recovery BEFORE UPDATE ON license_recovery BEGIN SELECT RAISE(ABORT,'fixture fault'); END;");
 await assert.rejects(send('recover',{recovery}));
 assert.equal(db.prepare('SELECT key_hash FROM licenses').get().key_hash,await digest(key));
 assert.equal(db.prepare('SELECT recovery_hash FROM license_recovery').get().recovery_hash,await digest(recovery));db.close();
});
test('rate limit blocks recovery before database work',async()=>{
 const response=await handle(new Request('https://fixture.test/v1/recover',{method:'POST',body:'{}'}),{DB:{},STRIPE_SECRET_KEY:'fixture',RATE_LIMITER:{limit:async()=>({success:false})}});assert.equal(response.status,429);
});
