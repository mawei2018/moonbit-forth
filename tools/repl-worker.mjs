import {parentPort} from 'node:worker_threads';import {session} from '../web/engine.mjs';
let handle;
parentPort.on('message',message=>{
 try{
  const request=message.op==='open'?{op:'open'}:{...message,id:handle};delete request.requestId;
  const result=JSON.parse(session(JSON.stringify(request)));
  if(message.op==='open'&&result.ok)handle=result.id;
  parentPort.postMessage({requestId:message.requestId,result});
 }catch(error){parentPort.postMessage({requestId:message.requestId,error:String(error.message??error)});}
});
