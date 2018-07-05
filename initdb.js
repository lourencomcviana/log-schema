const applyOnDatabase=require("./src/applyOnDatabase")
const configurationService=require("./src/configuration")
const config= require("./config.json")
//start the application

configurationService.set(config,getConnection());

applyOnDatabase(getConnection(),config).then(report=>{
    process.exit(0);
});

function getConnection(){
    let connection;
    if(process.argv.length>2){
        console.log("creating connection via parameter")
       
        
        if(!connection){
            connection=splitString();
        }
        if(!connection){
            connection=findAndParseOption("connection");
        }
        
        if(!connection){
            connection={
                user:findAndParseOption("user"),
                password:findAndParseOption("password"),
                connectString:findAndParseOption("connectionString")
            }
        } 
    }else{
        connection= require("./connection.json");
    }
    return connection;
}
function splitString(){
    try{
        let arr1= process.argv[2].split("@");
        let arr2= arr1[0].split(":");
        return {
            user:arr2[0],
            password:arr2[1],
            connectString:arr1[1]
        }
    }catch(e){
        return null;
    }
}
function findAndParseOption(option){
    let foundOption=process.argv.find(e=>e.startsWith("-"+option));
    if(foundOption){
       let oparr= foundOption.split("=");
       if(oparr.length>=2){
        return  oparr[1];
       }
    }
    return null;
}


