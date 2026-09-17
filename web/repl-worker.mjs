import {session} from './engine.mjs';
let handle;
self.onmessage=({data})=>{try{const request=data.op==='open'?{op:'open'}:{...data,id:handle};delete request.requestId;const result=JSON.parse(session(JSON.stringify(request)));if(data.op==='open'&&result.ok)handle=result.id;self.postMessage({requestId:data.requestId,result})}catch(error){self.postMessage({requestId:data.requestId,error:String(error.message??error)})}};
