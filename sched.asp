<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>2005 NFL Schedule - rasputin.dnsalias.com [<% = session("username") %>]</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
<style type="text/css">
.week_block {
	background-color: #C0C0C0;
}
</style>
</head>

<body>

<div id="Header"><a href="http://rasputin.dnsalias.com">rasputin.dnsalias.com</a></div>


		<%
		if session("page_message") <> "" then
			%><div id="Content"><%
			response.write session("page_message") & "<BR>"
			%></div><%
			session("page_message") = ""
		end if

		set cn = server.createobject("adodb.connection")
		cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"
		sql = "select max(week_id) as week_id from football.sched"
		
		set rs = cn.execute(sql)
		
		max_week_id = rs("week_id")
		
		rs.close()
		
		sql = "select a.game_id,a.week_id,a.away_id,a.home_id, char(a.game_tsp) as game_tsp,dayname(a.game_tsp) as game_day ,b.team_name as away_team, c.team_name as home_team , a.game_url from football.sched a full outer join football.teams b on a.away_id=b.team_id full outer join football.teams c on a.home_id=c.team_id order by week_id, game_tsp"
		current_week_id = ""

		set rs = cn.execute(sql)
		
		%><div id="Content">
		Week <%
		for i = 1 to max_week_id
		%><a href="#week<% = i %>"><% = i %></a> <%
		next
		while not rs.eof
			if isnull(rs("game_url")) then
				game_url = ""
			else
				game_url = rs("game_url")
			end if

			game_id = rs("game_id")
			week_id = rs("week_id")
			away_id = rs("away_id")
			home_id = rs("home_id")
			game_tsp = rs("game_tsp")
			home_team = rs("home_team")
			away_team = rs("away_team")
			game_day = rs("game_day")
			game_hour = mid(game_tsp,12,2)
			if cint(game_hour) >= 12 then
				if cint(game_hour > 12) then 
					game_hour = game_hour - 12
				end if
				ampm = "pm"
			else
				ampm = "am"
			end if

			game_minute = mid(game_tsp,15,2)

			'2004-09-09-21.00.00.000000
			action_block = ""
			if session("username") = "chadley" then
				action_block = "<td>&nbsp;</td>"
			end if
			if cstr(week_id) <> cstr(current_week_id) then
				if cint(week_id) = 1 then
				else
					%></table><br /><%
				end if
				if session("username") = "chadley" then
				%>
				<a name="week<% = week_id %>" />
				<table border=1 cellspacing=0 cellpadding=3 width=500>
				<tr><td class="week_block" colspan=5 ><table border=0 cellspacing=0 cellpadding=0 width=100% ><tr><td>Week #<% = week_id %></td><td align=right><a href="makepicks.asp?week_id=<% = week_id %>">Make Picks</a></td></tr></table></td></tr>
				<tr><td class="week_block">Away Team</td><td class="week_block">Home Team</td><td class="week_block">Game Time</td><td class="week_block">Action</td><td class="week_block">Results</td></tr>
				<%
				else
				%>
				<table border=1 cellspacing=0 cellpadding=3 width=500>
				<tr><td class="week_block" colspan=4 ><table border=0 cellspacing=0 cellpadding=0 width=100% ><tr><td>Week #<% = week_id %></td><td align=right><a href="makepicks.asp?week_id=<% = week_id %>">Make Picks</a></td></tr></table></td></tr>
				<tr><td class="week_block">Away Team</td><td class="week_block">Home Team</td><td class="week_block">Game Time</td><td class="week_block">Results</td></tr>
				<%
				end if
				

				current_week_id = week_id
			end if
			if session("username") = "chadley" then
				%><tr><td><% = away_team %></td><td><% = home_team %></td><td><% = game_day %>&nbsp;<% = mid(game_tsp,6,2) & "/" & mid(game_tsp,9,2) & " " & game_hour & ":" & game_minute & " " & ampm %></td><td><a href="enterscore.asp?game_id=<% = game_id %>">Score</a></td><td><a href="addgameurl.asp?game_id=<% = game_id %>">Add&nbsp;URL</a><%
				if game_url <> "" then
				%><br />
				<a href="<% = game_url %>" target="_blank">Result</a></td><%
				else
				%></td><%
				end if
				%>
				</tr>
				<%
			else
				%><tr><td><% = away_team %></td><td><% = home_team %></td><td><% = game_day %>&nbsp;<% = mid(game_tsp,6,2) & "/" & mid(game_tsp,9,2) & " " & game_hour & ":" & game_minute & " " & ampm %></td><%
				if game_url <> "" then
				%><td><a href="<% = game_url %>" target="_blank">Result</a></td><%
				else
				%><td>&nbsp;</td><%
				end if
				%></tr><%
			end if
			

			rs.movenext
		wend
		rs.close
		%>
		</table>
		</div>

<div id="Menu">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>

<!-- BlueRobot was here. -->

</body>

</html>