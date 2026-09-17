import {Worker} from 'node:worker_threads';

export class ForthSession {
 #worker;#pending;#counter=0;#closed=false;#closing;#signal;#abort;#timeout;#budget;
 constructor({timeoutMs=5000,budget=1000000,signal}={}){
  if(!Number.isInteger(timeoutMs)||timeoutMs<1||timeoutMs>300000)throw Error('timeoutMs must be 1..300000');
  if(!Number.isInteger(budget)||budget<1||budget>10000000)throw Error('budget must be 1..10000000');
  if(signal!==undefined&&!(signal instanceof AbortSignal))throw Error('signal must be an AbortSignal');
  if(signal?.aborted)throw signal.reason??Error('Aborted');
  this.#timeout=timeoutMs;this.#budget=budget;this.#signal=signal;
  this.#worker=new Worker(new URL('./repl-worker.mjs',import.meta.url),{execArgv:process.execArgv.filter(a=>!a.startsWith('--input-type')),resourceLimits:{maxOldGenerationSizeMb:512}});
  this.#worker.on('message',message=>{const pending=this.#pending;if(!pending||pending.id!==message.requestId)return;this.#pending=undefined;clearTimeout(pending.timer);message.error?pending.reject(Error(message.error)):pending.resolve(message.result)});
  this.#worker.on('error',error=>this.close(error));
  this.#worker.on('exit',code=>{if(!this.#closed)this.close(Error('Worker exited: '+code))});
  this.#abort=()=>this.close(signal.reason??Error('Aborted'));signal?.addEventListener('abort',this.#abort,{once:true});
 }
 async #call(request){
  if(this.#closed)throw Error('Session is closed');if(this.#pending)throw Error('Concurrent session operation is not allowed');
  return new Promise((resolve,reject)=>{const id=++this.#counter,timer=setTimeout(()=>this.close(Error('Execution timeout')),this.#timeout);this.#pending={id,resolve,reject,timer};try{this.#worker.postMessage({...request,requestId:id})}catch(error){this.close(error)}});
 }
 static async open(options){const value=new ForthSession(options);try{const result=await value.#call({op:'open'});if(!result.ok)throw Error(result.error);return value}catch(error){await value.close();throw error}}
 #source(op,source){if(typeof source!=='string'||source.length>1000000)throw Error('source must be a string with at most 1000000 UTF-16 units');return this.#call({op,source,budget:this.#budget})}
 eval(source){return this.#source('eval',source)}
 feed(source){return this.#source('feed',source)}
 state(){return this.#call({op:'state'})}
 reset(){return this.#call({op:'reset'})}
 close(reason=Error('Session closed')){
  if(this.#closing)return this.#closing;this.#closed=true;this.#signal?.removeEventListener('abort',this.#abort);
  if(this.#pending){clearTimeout(this.#pending.timer);this.#pending.reject(reason);this.#pending=undefined}
  this.#closing=this.#worker.terminate().then(()=>{});return this.#closing;
 }
}
