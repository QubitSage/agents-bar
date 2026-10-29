const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'preview.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
new vm.Script(script);
const references = [...html.matchAll(/(?:src|href)="([^"]+)"/g)].map(m => m[1]);
for (const reference of references) {
  if (!fs.existsSync(path.join(root, reference))) throw new Error(`Missing: ${reference}`);
}
console.log(`Preview JavaScript syntax OK; ${references.length} local references OK.`);
