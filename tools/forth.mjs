import fs from 'node:fs/promises';import {ForthSession} from './session-runtime.mjs';
const actions=[];let mode='batch',json=false,timeoutMs=5000,budget=1000000,instance,failed=false,hostFailed=false;
const controller=new AbortController(),interrupted=()=>{controller.abort(Error('Interrupted'));process.stdin.destroy(Error('Interrupted'))};
process.once('SIGINT',interrupted);process.once('SIGTERM',interrupted);
const write=(stream,data)=>new Promise((resolve,reject)=>stream.write(data,error=>error?reject(error):resolve()));
const decode=data=>new TextDecoder('utf-8',{fatal:true}).decode(data);
async function* lines(stream){
 const decoder=new TextDecoder('utf-8',{fatal:true});let pending='';
 for await(const chunk of stream){pending+=decoder.decode(chunk,{stream:true});let end;while((end=pending.indexOf('\n'))>=0){const line=pending.slice(0,end).replace(/\r$/,'');pending=pending.slice(end+1);if(Buffer.byteLength(line)>2097152)throw Error('Input line exceeds 2 MiB');yield line}if(Buffer.byteLength(pending)>2097152)throw Error('Input line exceeds 2 MiB')}
 pending+=decoder.decode();if(pending)yield pending;
}
async function display(result,asJson=json){if(!result.ok)failed=true;if(asJson)await write(process.stdout,JSON.stringify(result)+'\n');else{if(result.bytes)await write(process.stdout,Buffer.from(result.bytes));if(!result.ok)await write(process.stderr,JSON.stringify({ok:false,code:result.code,error:result.error})+'\n')}}
async function command(value){
 if(!value||typeof value!=='object'||Array.isArray(value)||Object.keys(value).some(k=>!['op','source'].includes(k)))throw Error('Expected an object with op and optional source');
 if(['state','reset'].includes(value.op)){if('source'in value)throw Error('source is not valid for '+value.op);return value.op==='state'?instance.state():instance.reset()}
 if(!['eval','feed'].includes(value.op)||typeof value.source!=='string')throw Error('Use eval/feed with a source string, or state/reset');
 return value.op==='eval'?instance.eval(value.source):instance.feed(value.source);
}
try{
 const args=process.argv.slice(2);
 for(let i=0;i<args.length;i++){
  const arg=args[i];
  if(arg==='--help'){console.log('Usage: node tools/forth.mjs [--eval SOURCE | --file FILE]... [--json]\nNo source: UTF-8 stdin. --lines feeds each line into one persistent machine.\n--jsonl accepts {op: eval|feed|state|reset, source?} commands, one JSON response per line.\n--timeout MS defaults to 5000 per operation; --budget N defaults to 1000000.\nMultiple files/evals execute sequentially in the same machine. Byte output is written unchanged.\nExit: 0 success, 2 Forth error/unfinished definition, 1 host error, 130 interrupted.');process.exit(0)}
  if(arg==='--json'){json=true;continue}
  if(arg==='--lines'||arg==='--jsonl'){if(mode!=='batch')throw Error('Only one streaming mode');mode=arg.slice(2);continue}
  if(!['--eval','--file','--timeout','--budget'].includes(arg)||++i>=args.length)throw Error('Unknown or missing argument '+arg);
  if(arg==='--timeout')timeoutMs=Number(args[i]);else if(arg==='--budget')budget=Number(args[i]);else actions.push({kind:arg.slice(2),value:args[i]});
 }
 if(actions.length&&mode!=='batch')throw Error('Streaming mode cannot mix with file/eval actions');
 if(mode==='jsonl'&&json)throw Error('--jsonl already returns JSON');
 if(!actions.length&&process.stdin.isTTY&&mode==='batch')mode='lines';
 instance=await ForthSession.open({timeoutMs,budget,signal:controller.signal});
 if(mode!=='batch'){
  if(process.stdin.isTTY)await write(process.stderr,'forth> ');
  for await(const line of lines(process.stdin)){
   try{await display(mode==='jsonl'?await command(JSON.parse(line)):await instance.feed(line+'\n'),mode==='jsonl'||json)}
   catch(error){if(controller.signal.aborted)throw error;hostFailed=true;await write(mode==='jsonl'?process.stdout:process.stderr,JSON.stringify({ok:false,host_error:true,error:String(error.message??error)})+'\n')}
   if(process.stdin.isTTY)await write(process.stderr,(await instance.state()).compiling?'   ... ':'forth> ');
  }
 }else if(actions.length){
  for(const action of actions){
   let source=action.value;
   if(action.kind==='file'){const stat=await fs.stat(action.value);if(stat.size>2097152)throw Error('File exceeds 2 MiB');source=decode(await fs.readFile(action.value))}
   else if(Buffer.byteLength(source)>2097152)throw Error('Source exceeds 2 MiB');
   const result=await instance.eval(source);await display(result);if(!result.ok)break;
  }
 }else{
  const chunks=[];let size=0;for await(const chunk of process.stdin){size+=chunk.length;if(size>2097152)throw Error('Input exceeds 2 MiB');chunks.push(chunk)}
  await display(await instance.eval(decode(Buffer.concat(chunks))));
 }
 if((await instance.state()).compiling){failed=true;await write(process.stderr,JSON.stringify({ok:false,error:'Unfinished definition at end of input'})+'\n')}
 process.exitCode=hostFailed?1:failed?2:0;
}catch(error){process.stderr.write(JSON.stringify({ok:false,error:String(error.message??error)})+'\n');process.exitCode=controller.signal.aborted?130:1}
finally{await instance?.close();process.removeListener('SIGINT',interrupted);process.removeListener('SIGTERM',interrupted)}
