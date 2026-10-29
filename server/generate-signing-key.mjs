// Explicit operator action. Writes private key only to a chosen, new output directory.
import {mkdir,writeFile} from 'node:fs/promises';
import {webcrypto} from 'node:crypto';
import {resolve} from 'node:path';
if(!process.argv[2])throw Error('Usage: node generate-signing-key.mjs <new-secret-directory>');
const folder=resolve(process.argv[2]);await mkdir(folder,{recursive:false});
const pair=await webcrypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
await writeFile(resolve(folder,'private.jwk'),JSON.stringify(await webcrypto.subtle.exportKey('jwk',pair.privateKey)),{mode:0o600});
await writeFile(resolve(folder,'public.jwk'),JSON.stringify(await webcrypto.subtle.exportKey('jwk',pair.publicKey)));
console.log('Signing keys written. Keep private.jwk outside version control and distribution.');
