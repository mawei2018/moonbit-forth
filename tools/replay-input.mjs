import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {report} from '../web/engine.mjs';
const record=JSON.parse(fs.readFileSync(new URL('../evidence/input-comparison.json',import.meta.url)));
const cases=fs.readFileSync(new URL('./input-cases.json',import.meta.url));
assert.equal(createHash('sha256').update(cases).digest('hex'),record.casesSHA256,'case inputs changed; capture the official oracle again');
let passed=0;
for(const row of record.rows){
 const actual=JSON.parse(report(row.source)),expected=row.reference;
 assert.equal(actual.ok,expected.code===0,row.name);
 if(expected.code===0){assert.deepEqual(actual.stack,expected.stack,row.name);assert.equal(Buffer.from(actual.bytes).toString('hex'),expected.outputHex,row.name)}
 else assert.equal(actual.code,expected.code,row.name);
 passed++;
}
console.log(JSON.stringify({reference:record.reference,offlineReplay:passed,failed:0}));
