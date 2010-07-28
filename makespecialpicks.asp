<%
server.execute "/cookiecheck.asp"
myname = session("username")
if myname <> "chadley" then
	session("page_message") = "You are not authorized to enter special picks."
	response.redirect "default.asp"
	response.end
end if

week_id = request("week_id")

%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Football - Make Special Picks - rasputin.dnsalias.com [<% = session("username") %>]</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
</head>

<body>

<div id="Header"><a href="http://rasputin.dnsalias.com">rasputin.dnsalias.com</a></div>

<div id="Content">
		<%
		set cn=server.createobject("adodb.connection")
		cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

		sql = "select min(week_id) as week_id from (select week_id from football.sched where game_tsp > current timestamp + 2 hours) as t"
		set rs = cn.execute(sql)
		default_week_id = rs("week_id")
		rs.close
		if isnull(week_id) then
			default_week_id = 1
		end if
		if week_id = "" then
			week_id = default_week_id
		end if

		sql = "select a.game_id,a.week_id,a.away_id,a.home_id,a.game_tsp,b.team_name as away_team, b.url as away_url, c.team_name as home_team, c.url as home_url from football.sched a full outer join football.teams b on a.away_id=b.team_id full outer join football.teams c on a.home_id=c.team_id  where char(a.week_id)=? order by  a.game_tsp"

		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true
		cmd.parameters.append cmd.createparameter("week_id",200,,50)


		cmd("week_id") = cstr(week_id)


		set rs = cmd.execute 'execute the query
		if rs.eof then
			week_id = default_week_id
			rs.close
			sql = "select a.game_id,a.week_id,a.away_id,a.home_id,a.game_tsp,b.team_name as away_team, b.url as away_url, c.team_name as home_team, c.url as home_url from football.sched a full outer join football.teams b on a.away_id=b.team_id full outer join football.teams c on a.home_id=c.team_id  where char(a.week_id)=? order by  a.game_tsp"

			set cmd=server.createobject("adodb.command") 'create a command object
			set cmd.activeconnection=cn // set active connection to the command object

			cmd.commandtext=sql
			cmd.prepared=true
			cmd.parameters.append cmd.createparameter("week_id",200,,50)


			cmd("week_id") = cstr(week_id)


			set rs = cmd.execute 'execute the query
		end if

		%><h2>Make Special Picks: Week #<% = week_id %></h2>
		<form action="domakespecialpicks.asp" name="makepicks">
		Week #<SELECT NAME="week_id" onChange="window.document.makepicks.action='makespecialpicks.asp'; window.document.makepicks.submit();">
		<%
		sql = "select distinct week_id from football.sched order by week_id"
		set rs_week_id = cn.execute(sql)
		while not rs_week_id.eof
			if cint(week_id) = cint(rs_week_id("week_id")) then
				%><option value="<% = rs_week_id("week_id") %>" selected><% = rs_week_id("week_id") %></option><%
			else
				%><option value="<% = rs_week_id("week_id") %>"><% = rs_week_id("week_id") %></option><%
			end if
			rs_week_id.movenext
		wend
		rs_week_id.close

		
		%>
		</SELECT> <select name="special_username">
		
		<option value="Pumpkin">Pumpkin</option>
		<option value="Vegas">Vegas</option>
		<option value="Hunter">Hunter</option>
		</select><BR>
		<TABLE border=1>
		<TR><TD>Game Date/Time</TD><TD align=right>Away Team</TD><TD align=left>Home Team</TD></TR>
		<%
		while not rs.eof
			game_id = rs("game_id")
			week_id = rs("week_id")
			away_id = rs("away_id")
			home_id = rs("home_id")
			game_tsp = rs("game_tsp")
			home_team = rs("home_team")
			home_url = rs("home_url")
			away_team = rs("away_team")
			away_url = rs("away_url")


			away_wins = 0
			away_losses = 0
			away_ties = 0

			home_wins = 0
			home_losses = 0
			home_ties = 0

			if week_id = 1 then
				sql = "select wins,losses,ties from football.teamstandings where team_id=" & rs("home_id")
				set rs3 = cn.execute(sql)
				if rs3.eof then
					home_wins = 0
					home_losses = 0
					home_ties = 0
				else
					home_wins = rs3("wins")
					home_losses = rs3("losses")
					home_ties = rs3("ties")
				end if
				rs3.close

				sql = "select wins,losses,ties from football.teamstandings where team_id=" & rs("away_id")
				set rs3 = cn.execute(sql)
				if rs3.eof then
					away_wins = 0
					away_losses = 0
					away_ties = 0
				else
					away_wins = rs3("wins")
					away_losses = rs3("losses")
					away_ties = rs3("ties")
				end if
				rs3.close

			else

				sql = "select a.game_id,a.week_id,a.away_id,a.home_id,a.game_tsp,b.team_name as away_team, c.team_name as home_team,d.away_score,d.home_score from football.sched a full outer join football.teams b on a.away_id=b.team_id full outer join football.teams c on a.home_id=c.team_id full outer join football.scores d on a.game_id=d.game_id where not d.home_score is null and not d.away_score is null order by week_id, game_tsp"

				set rs3 = cn.execute(sql)
				while not rs3.eof
					if rs3("home_id") = home_id then
						if rs3("home_score") > rs3("away_score") then
							home_wins = home_wins + 1
						end if
						if rs3("home_score") < rs3("away_score") then
							home_losses = home_losses + 1
						end if
						if rs3("home_score") = rs3("away_score") then
							home_ties = home_ties + 1
						end if
					end if
					if rs3("away_id") = home_id then
						if rs3("home_score") > rs3("away_score") then
							home_losses = home_losses + 1
						end if
						if rs3("home_score") < rs3("away_score") then
							home_wins = home_wins + 1
						end if
						if rs3("home_score") = rs3("away_score") then
							home_ties = home_ties + 1
						end if
					end if

					if rs3("home_id") = away_id then
						if rs3("home_score") > rs3("away_score") then
							away_wins = away_wins + 1
						end if
						if rs3("home_score") < rs3("away_score") then
							away_losses = away_losses + 1
						end if
						if rs3("home_score") = rs3("away_score") then
							away_ties = away_ties + 1
						end if
					end if
					if rs3("away_id") = away_id then
						if rs3("home_score") > rs3("away_score") then
							away_losses = away_losses + 1
						end if
						if rs3("home_score") < rs3("away_score") then
							away_wins = away_wins + 1
						end if
						if rs3("home_score") = rs3("away_score") then
							away_ties = away_ties + 1
						end if
					end if


					rs3.movenext
				wend


			end if

			sql = "select pick from football.picks2 where game_id=" & game_id & " and username='" & myname & "'"
			set rs2 = cn.execute(sql)
			if rs2.eof then
				home_pick = ""
				away_pick = ""
			else
				if rs2("pick") = "H" then
					home_pick = "CHECKED"
					away_pick = ""
				elseif rs2("pick") = "A" then
				home_pick = ""
				away_pick = "CHECKED"
				else
				home_pick = ""
				away_pick = ""
				end if
			end if
			rs2.close

			%><TR><TD><% = game_tsp %></TD><TD align=right><a target=_blank href="<% = away_url %>"><% = away_team %></a> (<% = away_wins %>-<% = away_losses %>-<% = away_ties %>)<INPUT TYPE="radio" NAME="game_<% = game_id %>" value="AWAY" <% = away_pick %>></TD><TD align=left><INPUT TYPE="radio" NAME="game_<% = game_id %>" value="HOME" <% = home_pick %>><a target=_blank href="<% = home_url %>"><% = home_team %></a> (<% = home_wins %>-<% = home_losses %>-<% = home_ties %>)</TD></TR><%
			rs.movenext
		wend
			sql = "select score from football.tiebreaker where username='" & myname & "' and week_id=" & week_id
			set rs2 = cn.execute(sql)
			if rs2.eof then
				score = ""
			else
				score = rs2("score")
			end if
			rs2.close

			%><TR><TD colspan=3><B>Tie Breaker:</B> <% = away_team %> at <% = home_team %><BR>Total Points: <INPUT TYPE="text" NAME="tie_breaker" size=4 value="<% = score %>"></TD></TR><%
		rs.close
		%>
		
		</TABLE><%
		if default_week_id <= week_id then
		%><INPUT TYPE="submit" value="Submit Picks"><%
		end if %></form><%
				
		%>

</div>

<div id="Menu">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
