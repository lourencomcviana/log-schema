var cachedConfig=null;
module.exports ={
    get:function(){
        return cachedConfig;
    },
    set:function(config,connection){
        config.connection=connection;
        parserConfig(config);
        cachedConfig=config;
    },
}

function parserConfig(config){
    x=[];
    for(var id in config.files){
        config.files[id]= parseFile(config.files[id]);
    }
  
    if(config.clear&&config.clear.files){
        for(var id in  config.clear.files){
            config.clear.files[id]=parseFile(config.clear.files[id]);
        }

    }
   
}

function parseFile(e){
    let model={
        file:undefined,
        delimiter:undefined
    }
    if(typeof e =='string'){
        model.file=e;
        return model;
    }
    return e;
}
