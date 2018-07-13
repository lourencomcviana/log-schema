

var oracledb = require('oracledb');
var Promise=  require('bluebird');
var fs=  require('fs-extra');
const configurationService=require("./configuration")
function showProgress(progress){
    try{
    
        let str="";
        let sucess=progress.sucess?"\x1b[34mO":"\x1b[31mX"
        progress.report=progress.report.split("\n")[0]
        let countColorSize=0;
        switch(progress.state){
            case "start":
                str=`starting: ${progress.report}`;
            break;
            case "finished":
                str=`${sucess} \x1b[0m${progress.report}\n`;
                countColorSize=7;
            break;
            default:
                str=`${sucess} \x1b[0m\x1b[44m${progress.time.getHours()}:${progress.time.getMinutes()}:${progress.time.getSeconds()}\x1b[0m - \x1b[32m${progress.left}\x1b[0m: ${progress.report}`;
                countColorSize=27;
            break;
        }
        let columns=process.stdout.columns?process.stdout.columns:100;
        //30 e o tamanho das cores.
        str=str.substring(0, columns+countColorSize);
        console.log(str);
    }catch(err){
        console.error("error on writing progress");
        console.error(err);
    }
}
module.exports = function () {
    var config=configurationService.get();
    var connection=config.connection;

    return  new Promise(function(resolve,reject){
        
        if(connection){
            let dropSchemaPromise=new Promise(resolve=>resolve(false));
            if(config.clear&&config.clear.files[config.clear.method]){
                dropSchemaPromise=readFile(config.clear.files[config.clear.method]).then(file=>{
                    return runScript(file,showProgress);
                })
                .then(data=>data)
                .catch(err=>err);
            }
            
            dropSchemaPromise.then(drops=>{
                return orderedFileRead(config.files)
            }).then(files=>{
            
                return runScript(files,showProgress);
            }).then(reports=>{

                resolve(reports);
            }).catch(err=>{
                reject(err);
            })
        }else{
            reject("no connection was found. Please Verify your connection data");
        }
    });

}

function orderedFileRead(files){
    var promisses=[];
    while(files&&files.length>0){
        let fileConfig=files.shift();
        if(fileConfig&&fileConfig.file){
            promisses.push(readFile(fileConfig));
        }
    }

    return Promise.all(promisses)
}

function readFile(fileConfig){
    let encoding=configurationService.get().encoding;
    return fs.readFile(fileConfig.file,encoding)
    .then(data=>{
        fileConfig.data=data;
        return fileConfig;
    })
    .catch(err=>{
        console.error("cant read file "+ fileName);
        return err;
    })
}

function runScript (scriptsFiles,callbackProgress) {
    if(!Array.isArray(scriptsFiles)){
        scriptsFiles=[scriptsFiles];
    }
    var connection=configurationService.get().connection;
    var scripts=[];
    scriptsFiles.forEach(scriptFile=>{
        scripts=scripts.concat(parseScript(scriptFile));
    })

    callProgress('start',`scripts to run ${scripts.length}`);

    return new Promise(function(resolve,reject){
        var results={
            executions:[],
            sucesses:[],
            errors:[]
        };
        recursiveExec(scripts).then(end=>{
            callProgress('finished',"scripts executados",true );
            resolve(results)
        }).catch(err=>{
            callProgress('finished',err,false);
            reject(err)
        });
        function recursiveExec(scripts){
            script=scripts.shift();
            return oraclePromise(script.toString(),connection)
            .then(result=>{
                let report={
                    script:script,
                    sucess:true,
                    result:result
                }
                
               
                results.sucesses.push(report);
                return report;
            })
            .catch(err=>{
                let report={
                    script:script,
                    sucess:false,
                    result:err
                }
                results.errors.push(report);
                return report;
            }).then(report=>{
                results.executions.push(report);
                
                callProgress('running',script.info.file+"-"+script.toString().trim(),report.sucess );
                if(!report.sucess){
                    
                }
                if(scripts.length>0){
                    return recursiveExec(scripts);
                }
            })
        }
    })
    
    function callProgress(state,report,sucess){
        if(callbackProgress&&typeof callbackProgress=='function'){
            
            callbackProgress({
                state:state,
                left:scripts.length,
                report:report,
                time: new Date(),
                sucess:sucess==undefined?true:sucess
            });
        }
    }
}

function parseScript(fileConfig){
    var endDelimiter=configurationService.get().defaultCommandDelimiter;
   
    if(fileConfig.delimiter){
        endDelimiter=fileConfig.delimiter;
    }
    var re = new RegExp(endDelimiter,'mg');
    let scripts=fileConfig.data.split(re);

    return scripts.map(e=>{
        e=e.trim();
       
        e=e.replace(/--.*/g,"");
        // e=e.replace(/\s*;\s*$/,"");
        
        sqlScript=new SqlScript(e,fileConfig);

        return sqlScript;
    });
}

class SqlScript{
    constructor(script, info) {
        this.script = script; this.info = info;
      }

    toString(){
        return this.script;
    }
}

function oraclePromise(script,connection,previousErr){
    return new Promise(function(resolve,reject){
        if(!script){
            resolve()
        }else{
         
            
            oracledb.getConnection(connection)
            .then(function(conn) {
                //block=`BEGIN EXECUTE IMMEDIATE '${script.replace(/'/g,"''")}';END;`
                block=script;
                return conn.execute(block)
                .then(function(result) {
                    conn.close().then(e=>{
                        resolve( result);
                    });

                })
                .catch(function(err) {
                    conn.close().then(e=>{
                        if(!previousErr){
                            
                            oraclePromise(script.replace(/\s*;\s*$/,""),connection,993)
                            .then(saida=>{
                                resolve(saida)
                            }).catch(err=>{
                                reject( err);
                            });
                        }else{
                            reject( err);
                        }
                        
                    });
                });
            })
            .catch(function(err) {
                reject( err);
            })
        }
    })
}