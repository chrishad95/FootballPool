<%
server.execute "/cookiecheck.asp"
myname = session("username")
if myname <> "chadley" then
	response.redirect("2004sched.asp")
	response.end
end if

game_id = request("game_id")
if not isnumeric(game_id) then
	response.redirect("2004sched.asp")
	response.end
end if


%>
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Football - Add Game URL - rasputin.dnsalias.com</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
</head>

<body>

<div id="Header"><a href="http://rasputin.dnsalias.com">rasputin.dnsalias.com</a></div>

<div id="Content">
		<%
		if session("page_message") <> "" then
			response.write session("page_message") & "<BR>"
			session("page_message") = ""
		end if
		set cn=server.createobject("adodb.connection")
		cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"
		sql = "select a.game_id, a.week_id, a.home_id, a.away_id, a.game_tsp, a.game_url, b.team_name as home_team_name, c.team_name as away_team_name from football.sched a full outer join football.teams b on b.team_id = a.home_id full outer join football.teams c on c.team_id = a.away_id where game_id=?"
		
		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true
		cmd.parameters.append cmd.createparameter("game_id",3)


		cmd("game_id") = cint(game_id)
		set rs = cmd.execute()

		%>
		<FORM ACTION="doaddgameurl.asp">
		<input type="hidden" name="game_id" value="<% = game_id %>">
		<TABLE>
		<TR>
			<TD>Week Id:</TD>
			<TD><% = rs("week_id") %></TD>
		</TR>
		<TR>
			<TD>Home Team:</TD>
			<TD><% = rs("home_team_name") %></TD>
		</TR>
		<TR>
			<TD>Away Team:</TD>
			<TD><% = rs("away_team_name") %></TD>
		</TR>
		<TR>
			<TD>Game Time:</TD>
			<TD><% = rs("game_tsp") %></TD>
		</TR>
		<TR>
			<TD colspan=2 >Game URL:<br />
			<textarea cols="40" rows="5" name="game_url"><% = rs("game_url") %></textarea></TD>
		</TR>
		<TR>
			<TD colspan=2><INPUT TYPE="submit" value="Add Game URL"></TD>
		</TR>
		</TABLE>
		</FORM>

</div>

<div id="Menu">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>

<!-- BlueRobot was here. -->

</body>

</html>