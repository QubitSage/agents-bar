const {spawn}=require('node:child_process');
const fs=require('node:fs');
const path=require('node:path');
const readline=require('node:readline');
const mode=process.argv.includes('--stdio')?'stdio':'proxy';
const threadId='01a17888-a104-77b2-895e-a212366b0849';
const binary=process.env.ESTACAO_CODEX_EXE||'codex';
const proc=spawn(binary,mode==='proxy'?['app-server','proxy']:['app-server','--listen','stdio://'],{windowsHide:true,stdio:['pipe','pipe','pipe']});
const report={transport:mode,initialized:false,observations:[],errors:[]};
const send=m=>proc.stdin.write(JSON.stringify(m)+'\n');
let done=false;
function finish(){if(done)return;done=true;clearTimeout(timer);proc.kill();fs.writeFileSync(path.join(__dirname,'../evidence/codex-probe-'+mode+'.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));}
const timer=setTimeout(finish,12000);
proc.on('error',e=>{report.errors.push(e.message);finish()});
proc.stderr.on('data',data=>{const s=String(data);if(/no such file|failed to connect|not found|refused|denied/i.test(s))report.errors.push(s.slice(0,600))});
readline.createInterface({input:proc.stdout}).on('line',line=>{
 let m;try{m=JSON.parse(line)}catch{return}
 if(m.id===1){if(m.error){report.errors.push(m.error);return finish()}report.initialized=true;send({method:'initialized',params:{}});send({id:2,method:'thread/read',params:{threadId,includeTurns:false}})}
 if(m.id===2){if(m.error)report.errors.push(m.error);else{report.threadStatus=m.result?.thread?.status;report.threadMatched=m.result?.thread?.id===threadId;report.threadPath=m.result?.thread?.path;}setTimeout(finish,2500)}
 if(m.method==='thread/status/changed'&&m.params?.threadId===threadId)report.observations.push({method:m.method,status:m.params.status});
});
proc.on('exit',()=>finish());
send({id:1,method:'initialize',params:{clientInfo:{name:'estacao_zero_probe',title:'Estacao Zero Read-only Probe',version:'0.1.0'}}});
