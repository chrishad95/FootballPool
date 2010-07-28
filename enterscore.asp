<%
server.execute "/cookiecheck.asp"
myname = session("username")
if myname <> "chadley" then
	response.redirect "default.asp"
	response.end
end if
'server.execute "updateplayerscores.asp"

if myname = "" then
	session("page_message") = "You must login to make picks in the football pool."
	response.redirect "default.asp"
	response.end
end if

game_id = request("game_id")
if not isnumeric(game_id) then
	response.redirect("2004sched.asp")
	response.end
end if

home_score = request("home_score")
away_score = request("away_score")
if home_score = "" then
	home_score = "NAN"
end if
if away_score = "" then
	away_score = "NAN"
end if

set cn=server.createobject("adodb.connection")
cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

if isnumeric(home_score) and isnumeric(away_score) then

sql = "select count(*) from football.scores where game_id=?"

set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true
cmd.parameters.append cmd.createparameter("game_id",3)


cmd("game_id") = cint(game_id)
set rs = cmd.execute()
if rs(0) = 0 then
	sql = "insert into football.scores (game_id,home_score,away_score) values (?,?,?)"
	
	 set cmd2=server.createobject("adodb.command") 'create a command object
	 set cmd2.activeconnection=cn // set active connection to the command object
	 
	 cmd2.commandtext=sql
	 cmd2.prepared=true
	 cmd2.parameters.append cmd2.createparameter("game_id",3)	 
	 cmd2("game_id") = cint(game_id)
	 cmd2.parameters.append cmd2.createparameter("home_score",3)	 
	 cmd2("home_score") = cint(home_score)
	 cmd2.parameters.append cmd2.createparameter("away_score",3)	 
	 cmd2("away_score") = cint(away_score)
	 cmd2.execute
	 
else

	sql = "update football.scores set home_score=?, away_score=? where game_id=?"
	
	 set cmd2=server.createobject("adodb.command") 'create a command object
	 set cmd2.activeconnection=cn // set active connection to the command object
	 
	 cmd2.commandtext=sql
	 cmd2.prepared=true
	 cmd2.parameters.append cmd2.createparameter("home_score",3)	 
	 cmd2("home_score") = cint(home_score)
	 cmd2.parameters.append cmd2.createparameter("away_score",3)	 
	 cmd2("away_score") = cint(away_score)
	 cmd2.parameters.append cmd2.createparameter("game_id",3)	 
	 cmd2("game_id") = cint(game_id)
	 cmd2.execute
end if
rs.close

response.redirect "showpicks.asp"
response.end

end if

sql = "select b.game_id, a.home_score, a.away_score,c.team_name as home_team, d.team_name as away_team from football.scores a full outer join football.sched b on a.game_id=b.game_id full outer join football.teams c on b.home_id=c.team_id full outer join football.teams d on b.away_id=d.team_id where b.game_id=?"

set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true
cmd.parameters.append cmd.createparameter("game_id",3)


cmd("game_id") = cint(game_id)

set rs=cmd.execute()
if rs.eof then
	session("page_message") = "Record not found"
	response.redirect("2004sched.asp")
	response.end
end if

while not rs.eof
	home_team = rs("home_team")
	away_team = rs("away_team")
	home_score = rs("home_score")
	away_score = rs("away_score")
	
	rs.movenext
wend
rs.close


%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Football - Enter Score - rasputin.dnsalias.com [<% = session("username") %>]</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
<style type="text/css">
.favorite {
	background-color: #FAF55A;
}

</style>
</head>

<body>

<div id="Header"><a href="http://rasputin.dnsalias.com">rasputin.dnsalias.com</a></div>

<div id="Content">
<form name="enterscoreform" action="enterscore.asp" method="post">
<input type="hidden" name="game_id" value="<% = game_id %>">
<h2>Enter Score</h2>
<table border=0>
<tr><td><% = away_team %></td><td><input type=text name="away_score" value="<% = away_score %>"></td></tr>
<tr><td><% = home_team %></td><td><input type=text name="home_score" value="<% = home_score %>"></td></tr>
<tr><td colspan=2><input type="submit" value="Enter Score"></td></tr>
</table>
</form>
</div>

<div id="Menu">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
