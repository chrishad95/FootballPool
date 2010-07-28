<%
response.redirect "/football/showpicks.aspx"
response.end


server.execute "/cookiecheck.asp"
myname = session("username")


week_id = request("week_id")

%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Football - Show Picks - rasputin.dnsalias.com [<% = session("username") %>]</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
<style type="text/css">
.winner {
	background-color: #00FF00;
	
}
.loser {
text-decoration: line-through;
}
.loser a {
	color:#333;
	font:11px verdana, arial, helvetica, sans-serif;
	text-decoration: none;
}
.winner a{
	color:#333;
	font:11px verdana, arial, helvetica, sans-serif;
	text-decoration: none;
}
.table_header {
	background-color: #C0C0C0;
}

</style>
</head>

<body>

<div id="Header"><a href="http://rasputin.dnsalias.com">rasputin.dnsalias.com</a></div>

<div id="Content">
		<%

		
		set cn=server.createobject("adodb.connection")
		cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

		sql = "select max(week_id) as max_week_id from (select min(game_tsp), week_id from football.sched where game_tsp < current timestamp + 30 minutes group by week_id ) as t"
		set rs = cn.execute(sql)
		default_week_id = rs("max_week_id")
		rs.close
		if week_id = "" then
			week_id = default_week_id
		end if
		if not isnumeric(week_id) then
			week_id = default_week_id
		end if
		if not isnumeric(week_id) then
			week_id = 1
			default_week_id = 1 
		end if
		week_id = cint(week_id)
		
		if week_id > default_week_id then
			week_id = default_week_id
		end if
		

		sql = "select a.game_id, d.away_score, d.home_score,  b.team_id as home_id, b.team_name as home_name, b.team_shortname as home_shortname, b.team_alias as home_alias, c.team_id as away_id, c.team_name as away_name, c.team_shortname as away_shortname, c.team_alias as away_alias , a.game_url, year(a.game_tsp) as game_year, month(a.game_tsp) as game_month, day(a.game_tsp) as game_day from football.sched a full outer join football.teams b on b.team_id=a.home_id full outer join football.teams c on c.team_id=a.away_id full outer join football.scores d on d.game_id=a.game_id where a.week_id=? order by a.game_tsp, a.game_id"
		
		
		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true
		cmd.parameters.append cmd.createparameter("week_id",3)


		cmd("week_id") = cint(week_id)
		set rs = server.createobject("adodb.recordset")
		rs.cursortype = 3
		rs.cursorlocation = 2
		rs.open cmd
		
		
		scores = rs.getrows()
		rs.close
		
		'rs = cmd.execute()
		rowcount = ubound(scores,2)
		
		%>
		
		
		<form name="pickweekform" action="showpicks.asp">
		<table>
		<tr><td colspan=3>Week # <select name="week_id" onChange="window.document.pickweekform.submit();" >
		<%
		for i = 1 to default_week_id
			if i = week_id then
				%>
				<option value="<% = i %>" selected><% = i %></option>
				<%
			else
				%>
				<option value="<% = i %>"><% = i %></option>
				<%
			end if
			
		next		
		%>
		</select></td></tr>
		</table>
		</form>
		
		<table border=1 cellspacing=0 cellpadding=3>
		<tr><td colspan="<% = rowcount + 3 %>" class="table_header">Pick Results for Week # <% = week_id %></td></tr>
		<tr>
		<td>Player</td>
		<%
		
			for i = 0 to rowcount
				if isnull(scores(1,i)) then
					scores(1,i) = "-1"
				end if
				if isnull(scores(2,i)) then
					scores(2,i) = "-1"
				end if
			
				if session("username") = "chadley" then
				
					%>				
					<td><a href="enterscore.asp?game_id=<% = scores(0,i) %>"><% = scores(9,i) %><br />at<br /><% = scores(5,i) %></a></td>
					<%
				else
					if isnull(scores(11,i)) then

					%>				
					<td><a href="http://www.nfl.com/gamecenter/recap/NFL_<% = right("000" & scores(12,i),4) %><% = right("000" & scores(13,i),2) %><% = right("000" & scores(14,i),2) %>_<% = trim(ucase(scores(9,i))) %>@<% = trim(ucase(scores(5,i))) %>" target="_blank" ><% = scores(9,i) %><br />at<br /><% = scores(5,i) %></a></td>
					<%
					else
					%>				
					<td><a href="<% = scores(11,i) %>" target="_blank" ><% = scores(9,i) %><br />at<br /><% = scores(5,i) %></a></td>
					<%
					end if

				end if
			
			next
		
		%>
		<td>Score</td>
		</tr>
		<%
				
		'response.write game_id_list
		sql = "select distinct username from football.picks2 order by username"
		username_list = ""
		
		set rs = cn.execute(sql)
		while not rs.eof
			if username_list = "" then
				username_list = rs("username")
			else
				username_list = username_list & "," & rs("username")
			end if
			
			rs.movenext
		wend
		rs.close
		
		for each u in split(username_list, ",")
		
			sql = "select score from football.tiebreaker where username='" & u & "' and week_id=" & week_id
			set rs = cn.execute(sql)
			
			if rs.eof then
				tiebreaker = ""
			else
				tiebreaker = rs("score")
			end if
			rs.close
			
			u_score = 0
			%><tr>
			<td><a href="compare.asp?primary=<% = u %>&week_id=<% = week_id %>" ><% = u %></a></td>
			<%
			for i = 0 to rowcount
				if i = rowcount then
					tb_string = " T:" & tiebreaker
				else
					tb_string = ""
				end if
				
				sql = "select * from football.picks2 where username='" & u & "' and game_id=" & scores(0,i)
				
				set rs = cn.execute(sql)
				if rs.eof then
						if session("username") = "chadley" then
							%><td><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>">NP<% = tb_string %></a></td><%
						else
							%><td>NP<% = tb_string %></td><%
						end if
				else
					if rs("pick") = "H" then
					
						' pick is the home team
						' scores array is GAME_ID AWAY_SCORE HOME_SCORE HOME_ID HOME_NAME HOME_SHORTNAME HOME_ALIAS AWAY_ID AWAY_NAME AWAY_SHORTNAME AWAY_ALIAS 
						if session("username") = "chadley" then
							if cint(scores(1,i)) < cint(scores(2,i)) then
										%><td class="winner"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(5,i) %><% = tb_string %></a></td><%
										u_score = u_score + 1
							elseif cint(scores(1,i)) > cint(scores(2,i)) then
										%><td class="loser"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(5,i) %><% = tb_string %></a></td><%
							else
										%><td ><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(5,i) %><% = tb_string %></a></td><%
							end if
						else
							if cint(scores(1,i)) < cint(scores(2,i)) then
										%><td class="winner"><% = scores(5,i) %><% = tb_string %></td><%
										u_score = u_score + 1
							elseif cint(scores(1,i)) > cint(scores(2,i)) then
										%><td class="loser"><% = scores(5,i) %><% = tb_string %></td><%
							else
										%><td ><% = scores(5,i) %><% = tb_string %></td><%
							end if
						end if

					elseif rs("pick") = "A" then
					
						' pick is the home team
						' scores array is GAME_ID AWAY_SCORE HOME_SCORE HOME_ID HOME_NAME HOME_SHORTNAME HOME_ALIAS AWAY_ID AWAY_NAME AWAY_SHORTNAME AWAY_ALIAS 

						if session("username") = "chadley" then
							if cint(scores(1,i)) > cint(scores(2,i)) then
										%><td class="winner"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(9,i) %><% = tb_string %></a></td><%
										u_score = u_score + 1
							elseif cint(scores(1,i)) < cint(scores(2,i)) then
										%><td class="loser"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(9,i) %><% = tb_string %></a></td><%
							else
										%><td><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(9,i) %><% = tb_string %></a></td><%
							end if
						else
							if cint(scores(1,i)) > cint(scores(2,i)) then
										%><td class="winner"><% = scores(9,i) %><% = tb_string %></td><%
										u_score = u_score + 1
							elseif cint(scores(1,i)) < cint(scores(2,i)) then
										%><td class="loser"><% = scores(9,i) %><% = tb_string %></td><%
							else
										%><td ><% = scores(9,i) %><% = tb_string %></td><%
							end if
						end if
			
					else
						if session("username") = "chadley" then
							%><td><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>">NP<% = tb_string %></a></td><%
						else
							%><td>NP<% = tb_string %></td><%
						end if

					end if
				end if
				
			next
			%><td><% = u_score %></td><%
		next
		
		'vegas section
		for each u in split("Vegas,Pumpkin,Hunter", ",")
			u_score = 0
			%><tr>
			<td><% = u %></td>
			<%
			for i = 0 to rowcount
			
				sql = "select * from football.special_picks where username='" & u & "' and game_id=" & scores(0,i)
				
				set rs = cn.execute(sql)
				if rs.eof then
						%><td> - </td><%
				else
					if rs("pick") = "H" then
					
						' pick is the home team
						' scores array is GAME_ID AWAY_SCORE HOME_SCORE HOME_ID HOME_NAME HOME_SHORTNAME HOME_ALIAS AWAY_ID AWAY_NAME AWAY_SHORTNAME AWAY_ALIAS 
						if cint(scores(1,i)) < cint(scores(2,i)) then
									%><td class="winner"><% = scores(5,i) %></td><%
									u_score = u_score + 1
						else
									%><td><% = scores(5,i) %></td><%
						end if
					elseif rs("pick") = "A" then
					
						' pick is the home team
						' scores array is GAME_ID AWAY_SCORE HOME_SCORE HOME_ID HOME_NAME HOME_SHORTNAME HOME_ALIAS AWAY_ID AWAY_NAME AWAY_SHORTNAME AWAY_ALIAS 
						if cint(scores(1,i)) > cint(scores(2,i)) then
									%><td class="winner"><% = scores(9,i) %></td><%
									u_score = u_score + 1
						else
									%><td><% = scores(9,i) %></td><%
						end if			
					else
						%><td> - </td><%
					end if
				end if
				
			next
			%><td><% = u_score %></td><%
		next
		%>
		
		</tr>
		</table>
		<br />
		<%
		sql = "select  comment_title,comment_info,comment_text,username,char(comment_tsp) as comment_tsp, comment_tsp as comment_time from site.comments where comment_type='FOOTBALL' AND COMMENT_INFO='" & week_id & "' order by comment_tsp asc"
		
		set rs = cn.execute(sql)
		if rs.eof then
			%>No comments found for this week.<%
		else
			while not rs.eof
				comment_week_id = rs("comment_info")
				comment_title = rs("comment_title")
				comment_text = rs("comment_text")
				comment_author = rs("username")
				comment_time = rs("comment_time")
				comment_tsp = rs("comment_tsp")

				%>
				<TABLE cellspacing=0 border=1 width=100%>
				<TR>
					<TD bgcolor=#FFFFCC width=100 valign="top" align="left"><B><% = comment_author %></B><BR><% = comment_time %><BR>Week #<% = week_id %><BR>
				<%
				if myname = comment_author then
				%><A HREF='editcomment.asp?comment_tsp=<% = rs("comment_tsp") %>'>Edit Comment</A><%
				end if
				%></TD>
					<TD bgcolor=#CCFFCC valign="top" align="left"><b><% = replace(comment_title,vbcrlf,"<BR>") %></b><br /><br /><% = replace(comment_text,vbcrlf,"<BR>" & vbcrlf) %></TD>
				</TR>
				</TABLE>
				<%
				rs.movenext
			wend
		end if
		
		rs.close
		
		%>
</div>

<div id="Menu">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
