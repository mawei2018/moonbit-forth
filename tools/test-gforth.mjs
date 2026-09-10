import fs from 'node:fs';
import {createHash} from 'node:crypto';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {run} from '../web/engine.mjs';
const root=fileURLToPath(new URL('../',import.meta.url));
const command=JSON.parse(process.env.GFORTH_COMMAND_JSON || '["gforth"]');
if(!Array.isArray(command)||!command.length||command.some(x=>typeof x!=='string'))throw Error('Invalid GFORTH_COMMAND_JSON');
const cases=JSON.parse(fs.readFileSync(new URL('./gforth-cases.json',import.meta.url),'utf8'));
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'forth-oracle-'));
const filename=path.join(dir,'case.fs');
const oraclePath=process.env.GFORTH_WSL==='1'?'/mnt/'+filename[0].toLowerCase()+filename.slice(2).replaceAll('\\','/'):filename;
const execute=args=>spawnSync(command[0],[...command.slice(1),...args],{encoding:'utf8',timeout:15000,maxBuffer:1024*1024,windowsHide:true});
const version=execute(['--version']);
const versionText=(version.stdout+' '+version.stderr).match(/gforth[^\r\n]*/i)?.[0] || 'unavailable';
const results=[];
try {
 for(const c of cases){
  fs.writeFileSync(filename,c.source+'\ncr .s cr bye\n');
  const ref=execute([oraclePath]);
  const match=ref.stdout?.match(/<(\d+)>[^\r\n]*/);
  const actual=run(c.source);
  const localMatch=actual.match(/Stack: (\[[^\n]*\])/);
  const expected=match?match[0].replace(/^<\d+>/,'').trim().split(/\s+/).filter(Boolean).map(Number):null;
  const local=localMatch?JSON.parse(localMatch[1]):null;
  const passed=ref.status===0&&expected!==null&&expected.length===Number(match[1])&&local!==null&&JSON.stringify(expected)===JSON.stringify(local);
  results.push({name:c.name,passed,expected,actual:local,...(!passed?{error:ref.error?.message||ref.stderr,localOutput:actual}:{})});
 }
}finally{if(fs.existsSync(filename))fs.unlinkSync(filename);fs.rmdirSync(dir);}
const engineSha256=createHash('sha256').update(fs.readFileSync(path.join(root,'web/engine.mjs'))).digest('hex');
const casesSha256=createHash('sha256').update(fs.readFileSync(path.join(root,'tools/gforth-cases.json'))).digest('hex');
const report={engineSha256,casesSha256,timestamp:new Date().toISOString(),reference:versionText,referenceExit:version.status,engine:'web/engine.mjs',scope:'shared portable integer programs; no address or cell-width equivalence claim',fullSuiteRun:false,results,passed:results.filter(x=>x.passed).length,failed:results.filter(x=>!x.passed).length};
fs.writeFileSync(path.join(root,'evidence/gforth-comparison.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({reference:report.reference,passed:report.passed,failed:report.failed,failures:results.filter(x=>!x.passed)}));
process.exitCode=report.failed?1:0;
