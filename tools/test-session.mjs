import assert from 'node:assert/strict';import fs from 'node:fs/promises';import path from 'node:path';import os from 'node:os';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';import {ForthSession} from './session-runtime.mjs';import {session} from '../web/engine.mjs';
const root=path.dirname(path.dirname(fileURLToPath(import.meta.url))),temporary=await fs.mkdtemp(path.join(os.tmpdir(),'forth-session-')),groups=[];
async function group(name,body){await body();groups.push(name)}
async function withSession(body,options){const value=await ForthSession.open(options);try{return await body(value)}finally{await value.close()}}
const cli=(args,input)=>spawnSync(process.execPath,[path.join(root,'tools/forth.mjs'),...args],{input,timeout:15000,maxBuffer:10000000,windowsHide:true});
let measured;
try{
 await group('Persistent compiler and dictionary survive chunks; failures abort only the unfinished definition',()=>withSession(async value=>{
  assert.equal((await value.feed(': square')).compiling,true);assert.equal((await value.feed('dup * ; 9 square')).compiling,false);
  assert.deepEqual((await value.state()).stack,[81]);assert.equal((await value.feed(': bad')).compiling,true);
  const failure=await value.feed('missing ;');assert.equal(failure.ok,false);assert.equal(failure.compiling,false);
  assert.deepEqual((await value.eval('4 square')).stack,[81,16]);
  const state=await value.state();state.stack[0]=999;assert.equal((await value.state()).stack[0],81);
  assert.deepEqual((await value.reset()).stack,[]);assert.equal((await value.eval('square')).ok,false);
 }));
 await group('UTF8 and arbitrary byte output are preserved; caught errors leave the session usable',()=>withSession(async value=>{
  const result=await value.eval('s" Hello 世界" type 255 emit 0 emit');assert.equal(result.ok,true);assert.deepEqual(Buffer.from(result.bytes),Buffer.concat([Buffer.from('Hello 世界'),Buffer.from([255,0])]));
  assert.deepEqual((await value.eval("' drop catch")).stack,[-4]);
  const second=await value.eval('7 .');assert.deepEqual(Buffer.from(second.bytes),Buffer.from('7 '));
 }));
 await group('Operation serialization, instruction budget and timeout reject boundedly',async()=>{
  await withSession(async value=>{const pending=value.eval('1 2 +');await assert.rejects(value.state(),/Concurrent/);assert.equal((await pending).ok,true)});
  await withSession(async value=>{assert.equal((await value.eval('begin again')).ok,false);assert.deepEqual((await value.eval('7')).stack,[7])},{budget:50});
  await assert.rejects(ForthSession.open({timeoutMs:1}),/timeout/);
  await assert.rejects(ForthSession.open({signal:{}}),/AbortSignal/);
  const cancelled=new AbortController();cancelled.abort(Error('already cancelled'));
  await assert.rejects(ForthSession.open({signal:cancelled.signal}),/already cancelled/);
 });
 await group('Abort terminates an in-flight worker and a new session can recover',async()=>{
  const controller=new AbortController();const value=await ForthSession.open({signal:controller.signal,budget:10000000});
  try{const pending=value.eval('begin again');const timer=setTimeout(()=>controller.abort(Error('test cancellation')),10);await assert.rejects(pending,/cancellation/);clearTimeout(timer);await assert.rejects(value.state(),/closed/)}finally{await value.close()}
  await withSession(async replacement=>assert.equal((await replacement.eval('1 2 +')).stack[0],3));
 });
 await group('Compiled bridge validates options, caps handles and closes them',async()=>{
  const handles=[];for(let i=0;i<8;i++){const value=JSON.parse(session('{"op":"open"}'));assert.equal(value.ok,true);handles.push(value.id)}
  try{assert.equal(JSON.parse(session('{"op":"open"}')).ok,false);assert.equal(JSON.parse(session(JSON.stringify({op:'eval',id:handles[0],source:'1',extra:1}))).host_error,true);assert.deepEqual(JSON.parse(session(JSON.stringify({op:'state',id:handles[0]}))).stack,[])}
  finally{for(const id of handles)assert.equal(JSON.parse(session(JSON.stringify({op:'close',id}))).ok,true)}
  assert.equal(JSON.parse(session(JSON.stringify({op:'state',id:handles[0]}))).ok,false);
 });
 await group('Actual CLI runs multiple files in one machine and emits unchanged bytes',async()=>{
  const first=path.join(temporary,'defs.fs'),second=path.join(temporary,'use.fs');await fs.writeFile(first,': square dup * ;');await fs.writeFile(second,'8 square . s" 世界" type 255 emit');
  const result=cli(['--file',first,'--file',second]);assert.equal(result.status,0,result.stderr.toString());assert.deepEqual(result.stdout,Buffer.concat([Buffer.from('64 世界'),Buffer.from([255])]));
  const error=cli(['--eval','missing','--json']);assert.equal(error.status,2);assert.equal(JSON.parse(error.stdout).code,-13);
 });
 await group('Actual line REPL and JSONL protocol preserve state and diagnose unfinished definitions',async()=>{
  const repl=cli(['--lines'],': square\ndup *\n;\n5 square .\n');assert.equal(repl.status,0,repl.stderr.toString());assert.equal(repl.stdout.toString(),'25 ');
  assert.equal(cli(['--lines'],': unfinished\n').status,2);
  const commands=[{op:'feed',source:': x'},{op:'feed',source:'7 ;'},{op:'eval',source:'x'},{op:'state'},{op:'reset'},{op:'state'}];
  const result=cli(['--jsonl'],commands.map(x=>JSON.stringify(x)).join('\n')+'\n');assert.equal(result.status,0,result.stderr.toString());const rows=result.stdout.toString().trim().split('\n').map(JSON.parse);assert.equal(rows.length,6);assert.equal(rows[0].compiling,true);assert.deepEqual(rows[2].stack,[7]);assert.deepEqual(rows[5].stack,[]);
  const malformed=cli(['--jsonl'],'{bad}\n{"op":"eval","source":"4"}\n');assert.equal(malformed.status,1);const errors=malformed.stdout.toString().trim().split('\n').map(JSON.parse);assert.equal(errors[0].host_error,true);assert.deepEqual(errors[1].stack,[4]);
 });
 await group('Actual CLI rejects malformed UTF8, input size and invalid options',async()=>{
  const invalid=path.join(temporary,'invalid.fs');await fs.writeFile(invalid,Buffer.from([255]));
  assert.equal(cli(['--file',invalid]).status,1);assert.equal(cli([],Buffer.from([255])).status,1);assert.equal(cli(['--lines'],Buffer.from([255])).status,1);
  assert.equal(cli([],Buffer.alloc(2097153,32)).status,1);assert.equal(cli(['--unknown']).status,1);assert.equal(cli(['--budget','0','--eval','1']).status,1);
 });
 await group('One thousand real worker exchanges retain variables without accumulating output',()=>withSession(async value=>{
  await value.eval('variable n : tick 1 n +! ;');const start=performance.now();
  for(let i=0;i<1000;i++){const result=await value.eval('tick');assert.equal(result.ok,true);assert.deepEqual(result.stack,[]);assert.deepEqual(result.bytes,[])}
  const result=await value.eval('n @');assert.deepEqual(result.stack,[1000]);measured={requests:1000,elapsedMs:performance.now()-start,runtime:process.version,cpu:os.cpus()[0].model,scope:'One local Worker session, request serialization and validation included; no upstream throughput or exact memory claim'};
 }));
 await fs.writeFile(path.join(root,'evidence/session-validation.json'),JSON.stringify({date:new Date().toISOString(),passed:groups.length,groups,measured},null,2)+'\n');console.log(JSON.stringify({passed:groups.length,measured}));
}finally{const real=await fs.realpath(temporary),base=await fs.realpath(os.tmpdir());if(path.dirname(real).toLowerCase()!==base.toLowerCase()||!path.basename(real).startsWith('forth-session-'))throw Error('Unsafe test cleanup');await fs.rm(real,{recursive:true,force:true})}
