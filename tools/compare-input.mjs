import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import {spawnSync} from 'node:child_process';import {createHash} from 'node:crypto';import {report} from '../web/engine.mjs';
const root=new URL('../',import.meta.url),command=JSON.parse(process.env.GFORTH_COMMAND_JSON??'["gforth"]');
if(!Array.isArray(command)||!command.length||command.some(s=>typeof s!=='string'))throw Error('Invalid GFORTH_COMMAND_JSON');
const sourceCases=JSON.parse(fs.readFileSync(new URL('./input-cases.json',import.meta.url),'utf8'));
const folder=fs.mkdtempSync(path.join(os.tmpdir(),'forth-input-')),sourceFile=path.join(folder,'input.fs'),harness=path.join(folder,'harness.fs');
const referencePath=file=>process.env.GFORTH_WSL==='1'?'/mnt/'+file[0].toLowerCase()+file.slice(2).replaceAll('\\','/'):file;
const execute=args=>{const result=spawnSync(command[0],[...command.slice(1),...args],{timeout:15000,maxBuffer:8000000,windowsHide:true});return {...result,raw:result.stdout,stdout:result.stdout?.toString('utf8'),stderr:result.stderr?.toString('utf8')};};
const version=execute(['--version']);if(version.status!==0)throw Error(version.stderr);
const marker='__MOON_FORTH_REFERENCE_918__',rows=[];
try{
 for(const test of sourceCases){
  fs.writeFileSync(sourceFile,test.source);
  fs.writeFileSync(harness,': run-reference s" '+referencePath(sourceFile)+'" slurp-file [\'] evaluate catch cr ." '+marker+'" decimal . cr .s cr ; run-reference bye\n');
  const reference=execute([referencePath(harness)]),position=reference.raw.indexOf(Buffer.from('\n'+marker)),tail=reference.raw.subarray(position+marker.length+1).toString('utf8');
  if(reference.status!==0||position<0)throw Error('Reference harness failed '+test.name+': '+reference.stderr);
  const code=Number(tail.match(/^\s*(-?\d+)/)?.[1]),stackMatch=tail.match(/<(\d+)>[^\r\n]*/),stack=stackMatch?stackMatch[0].replace(/^<\d+>/,'').trim().split(/\s+/).filter(Boolean).map(Number):[];
  if(!Number.isInteger(code)||!stackMatch||stack.length!==Number(stackMatch[1]))throw Error('Reference capture failed '+test.name);
  const expected={code,output:reference.raw.subarray(0,position).toString('utf8'),outputHex:reference.raw.subarray(0,position).toString('hex'),stack:code===0?stack:null},actual=JSON.parse(report(test.source));
  const passed=actual.ok===(code===0)&&(code===0?JSON.stringify(actual.stack)===JSON.stringify(stack)&&Buffer.from(actual.bytes).toString('hex')===expected.outputHex:actual.code===code);
  rows.push({...test,reference:expected,actual,passed,referenceStderr:reference.stderr});
 }
}finally{fs.unlinkSync(sourceFile);fs.unlinkSync(harness);fs.rmdirSync(folder);}
const result={reference:(version.stdout+' '+version.stderr).match(/gforth[^\r\n]*/i)?.[0],engineSHA256:createHash('sha256').update(fs.readFileSync(new URL('../web/engine.mjs',import.meta.url))).digest('hex'),casesSHA256:createHash('sha256').update(fs.readFileSync(new URL('./input-cases.json',import.meta.url))).digest('hex'),scope:'Unmodified Gforth 0.7.3, whole-source EVALUATE harness to match input buffers. Portable values only; raw addresses and 64/32-bit boundaries excluded. On uncaught errors compare codes, not implementation-defined partial stack/output.',rows,passed:rows.filter(r=>r.passed).length,failed:rows.filter(r=>!r.passed).length};
fs.writeFileSync(new URL('evidence/input-comparison.json',root),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({passed:result.passed,failed:result.failed,failures:rows.filter(r=>!r.passed)}));process.exitCode=result.failed?1:0;
