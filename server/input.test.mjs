import {test} from 'node:test';
import assert from 'node:assert/strict';
import worker,{limitedText} from './worker.mjs';
test('bounded request reader rejects oversized and chunked bodies',async()=>{
 await assert.rejects(limitedText(new Request('https://fixture.test',{method:'POST',body:'x'.repeat(9000)}),8192),/large/);
 const stream=new ReadableStream({start(c){c.enqueue(new Uint8Array(4096));c.enqueue(new Uint8Array(4097));c.close();}});
 await assert.rejects(limitedText(new Request('https://fixture.test',{method:'POST',body:stream,duplex:'half'}),8192),/large/);
 assert.equal(await limitedText(new Request('https://fixture.test',{method:'POST',body:'{"a":1}'}),8192),'{"a":1}');
});
test('malformed API input has an actionable response without database queries',async()=>{
 for(const body of ['{','null','[]','1']){
  const response=await worker.fetch(new Request('https://fixture.test/v1/recover',{method:'POST',body}),{DB:{},STRIPE_SECRET_KEY:'fixture'});
  assert.equal(response.status,400);assert.equal(response.headers.get('Cache-Control'),'no-store');
 }
 const response=await worker.fetch(new Request('https://fixture.test/v1/recover',{method:'POST',body:'x'.repeat(9000)}),{DB:{},STRIPE_SECRET_KEY:'fixture'});assert.equal(response.status,413);
});
