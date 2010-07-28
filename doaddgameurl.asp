<%
server.execute "/cookiecheck.asp"
myname = session("username")
if session("username") <> "chadley" then
	response.redirect "2004sched.asp"
	response.end
end if

game_url = request("game_url")
game_id = request("game_id")
if not isnumeric(game_id) then
	response.redirect("2004sched.asp")
	response.end
end if


set cn = server.createobject("adodb.connection")
cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

sql = "update football.sched set game_url=? where game_id=?"

		
set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true

cmd.parameters.append cmd.createparameter("game_url",200,,300)
cmd("game_url") = game_url

cmd.parameters.append cmd.createparameter("game_id",3)
cmd("game_id") = game_id

cmd.execute
%>
<script>window.document.location.replace("2004sched.asp");</script>
