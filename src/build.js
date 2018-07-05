
const fs= require("fs");
const defaultConnection=
{
    user          : "system",
    password      : "oracle",
    connectString : "localhost/XE"
};
const files={
    connection:process.cwd() +"/connection.json",
    config:process.cwd() +"/config.json"
};
console.log("checking existence of configuration files");
fs.exists(files.connection,function(exists){
    if(!exists){
        console.log("\x1b[1mcreating connection data file in");
        console.log("\x1b[44m"+process.cwd() +"/connection.json\x1b[0m");
        fs.writeFile(process.cwd() +"/connection.json",JSON.stringify(defaultConnection,"",2),"UTF-8",function(err,data){
            if(err){
                console.error("\x1b[41mThere was a problem creating connection file\x1b[0m");
                console.error(err);
                process.exit(1);
            }else{
                console.log("\x1b[32mplease, verify your oracle connection data in connection.json\x1b[0m");
            }
        })
    }
})