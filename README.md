# log-schema
log schema for relational databases.

## Instalation

### Auto-install
- You need to have a properly configured oracle client on machine to user oracledb dependency. If you connect from your machine into a oracle database you probably don`t need to do anything. See https://oracle.github.io/node-oracledb/INSTALL.html#quickstart
- you need to have node/npm properly installed
- run `npm install`
- configure your connection string data in connection.json (alredy on .gitignore) or pass them as parameter
- execute `node initdb.js`
  - to pass connection info as parameter: `node initdb.js user:password@database`
  - exe: `node initdb.js system:oracle@localhost/XE`
- everything should work if the user has suficiente permissions (create user, tables, packages, views, give permissions to its own resources). If not. Ask nicelly for a dba to do it for you
- you can manually remove some scripts from [config.files](config.json) and ask for a dba to run them

### Manual-install
run scripts inside script folder in the order described in [config.json - files](config.json)
You can use any sql client you like.

### Configuration
In general, the app was made to require minimun modifications to [config.json](config.json). But if you want to mess around, fell free to do it.

At the file [config.json](config.json) you can change:
- encoding: text encoding of sql files
- defaultCommandDelimiter: end of block of script. Should be the end of one complete unit of command. One insert, one create table, etc. It is a regex.
- clear: clear scripts to be run before you run the script files. 
  - method: name of the cleaning method
  - files: object containing all avaliable methods
- files: files to be run. Can be only a string containing the path of the file or a object containing the path of the file and a custom commando delimiter for that file.

## Observations
- the package `log_audit.pkg_log_i` exists only as an interface. No logic asside clob to xml and vice-versa is involved. The conversion is necessary because oracle drivers for xmltype tend to be obscure to use. Sending/reciving a clob from an application is way easyer and will work with almost all drivers.
- for applications you should only acess the procedures existent in log_audit.pkg_log_i
- NO ONE needs to have permissions to edit or delete logs. Only high level dbas can do so and, for the team/company own safety. Theses modifications should have its own high priority auditing as well. You don`t want some smart guy changing logs. Only corruption and villany can result from that. 

## Libraries
To have easy acess to log schema implementations you can use:
- java [log-audit](https://github.com/techleadits/log-audit)