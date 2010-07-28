<%
server.execute "/cookiecheck.asp"
myname = session("username")


week_id = request("week_id")
primary = request("primary")
if isnull(primary) then
	primary = ""
end if

secondary = request("secondary")

if isnull(secondary) then
	secondary = ""
end if


%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Football - Compare Picks - rasputin.dnsalias.com [<% = session("username") %>]</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
<style type="text/css">
.winner {
	background-color: #FFFF33;
	
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

		sql = "select max(week_id) as max_week_id from (select min(game_tsp), week_id from football.sched where game_tsp < current timestamp + 2 hours group by week_id ) as t"
		set rs = cn.execute(sql)
		default_week_id = rs("max_week_id")
		rs.close
		if week_id = "" then
			week_id = default_week_id
		end if
		if not isnumeric(week_id) then
			week_id = default_week_id
		end if
		week_id = cint(week_id)
		
		if week_id > default_week_id then
			week_id = default_week_id
		end if
		
		
		if primary <> "" then
			 
			 sql = "select * from football.special_picks a full outer join football.sched b on a.game_id=b.game_id where not a.game_id is null"
			 set rs = cn.execute(sql)
			 
			 while not rs.eof
				 if rs("pick") = "H" then
				 	sql = "update football.special_picks set pick_id=" & rs("home_id") & "  where username='" & rs("username") & "' and game_id = " & rs("game_id") & ""
					 
				 elseif rs("pick") = "A" then

				 	sql = "update football.special_picks set pick_id=" & rs("away_id") & "  where username='" & rs("username") & "' and game_id = " & rs("game_id") & ""
				 end if
				 'cn.execute sql
				 
				 'response.write sql
				 'response.write "<br />"
				 rs.movenext
			 wend
			 rs.close
			 
	 
			 sql = "select a.game_id, d.away_score, d.home_score,  b.team_id as home_id, b.team_name as home_name, b.team_shortname as home_shortname, b.team_alias as home_alias, c.team_id as away_id, c.team_name as away_name, c.team_shortname as away_shortname, c.team_alias as away_alias , a.game_url from football.sched a full outer join football.teams b on b.team_id=a.home_id full outer join football.teams c on c.team_id=a.away_id full outer join football.scores d on d.game_id=a.game_id where a.week_id=? order by a.game_tsp, a.game_id"
			 
			 
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
						 <td><% = scores(9,i) %><br />at<br /><% = scores(5,i) %></td>
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
			 sql = "select distinct username from football.picks2 where username=?"
			 set cmd=server.createobject("adodb.command") 'create a command object
			 set cmd.activeconnection=cn // set active connection to the command object
	 
			 cmd.commandtext=sql
			 cmd.prepared=true
			 cmd.parameters.append cmd.createparameter("username",200,,50)
	 
	 
			 cmd("username") = primary
			 username_list = ""
			 
			 set rs = cmd.execute
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
				 u_score = 0
				 %><tr>
				 <td><% = u %></td>
				 <%
				 for i = 0 to rowcount
				 
					 sql = "select * from football.picks2 where username='" & u & "' and game_id=" & scores(0,i)
					 
					 set rs = cn.execute(sql)
					 if rs.eof then
							 if session("username") = "chadley" then
								 %><td><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>">NP</a></td><%
							 else
								 %><td>NP</td><%
							 end if
					 else
						 if rs("pick") = "H" then
						 
							 ' pick is the home team
							 ' scores array is GAME_ID AWAY_SCORE HOME_SCORE HOME_ID HOME_NAME HOME_SHORTNAME HOME_ALIAS AWAY_ID AWAY_NAME AWAY_SHORTNAME AWAY_ALIAS 
							 if session("username") = "chadley" then
								 if cint(scores(1,i)) < cint(scores(2,i)) then
											 %><td class="winner"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(5,i) %></a></td><%
											 u_score = u_score + 1
								 else
											 %><td class="loser"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(5,i) %></a></td><%
								 end if
							 else
								 if cint(scores(1,i)) < cint(scores(2,i)) then
											 %><td class="winner"><% = scores(5,i) %></td><%
											 u_score = u_score + 1
								 else
											 %><td class="loser"><% = scores(5,i) %></td><%
								 end if
							 end if
	 
						 elseif rs("pick") = "A" then
						 
							 ' pick is the home team
							 ' scores array is GAME_ID AWAY_SCORE HOME_SCORE HOME_ID HOME_NAME HOME_SHORTNAME HOME_ALIAS AWAY_ID AWAY_NAME AWAY_SHORTNAME AWAY_ALIAS 
	 
							 if session("username") = "chadley" then
								 if cint(scores(1,i)) > cint(scores(2,i)) then
											 %><td class="winner"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(9,i) %></a></td><%
											 u_score = u_score + 1
								 else
											 %><td class="loser"><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>"><% = scores(9,i) %></a></td><%
								 end if
							 else
								 if cint(scores(1,i)) > cint(scores(2,i)) then
											 %><td class="winner"><% = scores(9,i) %></td><%
											 u_score = u_score + 1
								 else
											 %><td class="loser"><% = scores(9,i) %></td><%
								 end if
							 end if
				 
						 else
							 if session("username") = "chadley" then
								 %><td><a href="correctpick.asp?game_id=<% = scores(0,i) %>&u=<% = u %>">NP</a></td><%
							 else
								 %><td>NP</td><%
							 end if
	 
						 end if
					 end if
					 
				 next
				 %><td><% = u_score %></td></tr><%
			 next
			 
			 
			 'special picks section
			 for each u in split(secondary, ",")
				 u = trim(u)
				 if instr(u, "Special_Pick_") = 1 then
				 	u = mid(u,14)
						
					 u_score = 0
					 %><tr>
					 <td><% = u %></td>
					 <%
					 for i = 0 to rowcount
					 
						 sql = "select * from football.special_picks where username=? and game_id=" & scores(0,i)
						 
						 set cmd=server.createobject("adodb.command") 'create a command object
						 set cmd.activeconnection=cn // set active connection to the command object
				 
						 cmd.commandtext=sql
						 cmd.prepared=true
						 cmd.parameters.append cmd.createparameter("username",200,,50)
				 
				 
						 cmd("username") = u
						 
						 set rs = cmd.execute
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
					 %><td><% = u_score %></td></tr><%
				 elseif u = "CALCULATED_PICK_MAJORITY" then
				 	 u = "Majority"
				 	 u = trim(u)
					 u_score = 0
					 %><tr>
					 <td><% = u %></td>
					 <%
					 for i = 0 to rowcount
					 	 sql = "select game_id,pick_id, count(*) as pick_count from football.picks2 where game_id = " & scores(0,i) & " group by game_id,pick_id"
						 'response.write sql
						 
						 pick_count = -1
						 majority_pick_id = -1
						 
						 set rs = cn.execute(sql)
						 while not rs.eof
						 	if rs("pick_count") > pick_count then
								majority_pick_id = rs("pick_id")
								pick_count = rs("pick_count")
							elseif rs("pick_count") = pick_count then
								majority_pick_id = -1
								pick_count = rs("pick_count")
							end if
						 	rs.movenext
						 wend
						 rs.close
						 'response.write sql & "  " & scores(0,i) & "," & majority_pick_id & "<BR>"
						 if majority_pick_id = scores(3,i) then
						 	'majority picked home team
								if cint(scores(1,i)) > cint(scores(2,i)) then
						 			%><td><% = scores(5,i) %></td><%
								else
									%><td class="winner"><% = scores(5,i) %></td><%
									u_score = u_score + 1
								end if							
						 elseif  majority_pick_id = scores(7,i) then
						 	'majority picked away team
								if cint(scores(1,i)) < cint(scores(2,i)) then
						 			%><td><% = scores(9,i) %></td><%
								else
									%><td class="winner"><% = scores(9,i) %></td><%
									u_score = u_score + 1
								end if								
						 else
						 	'majority was split
						 	%><td align=center>/</td><%					
						 end if
						 
					 next
					 %><td><% = u_score %></td></tr><%
				 elseif u = "CALCULATED_PICK_HOME" then
				 	 u = "Home Teams"
				 	 u = trim(u)
					 u_score = 0
					 %><tr>
					 <td><% = u %></td>
					 <%
					 for i = 0 to rowcount

							if cint(scores(1,i)) > cint(scores(2,i)) then
								%><td><% = scores(5,i) %></td><%
							else
								%><td class="winner"><% = scores(5,i) %></td><%
								u_score = u_score + 1
							end if	
						 
					 next
					 %><td><% = u_score %></td></tr><%
				 elseif u = "CALCULATED_PICK_AWAY" then
				 	 u = "Away Teams"
				 	 u = trim(u)
					 u_score = 0
					 %><tr>
					 <td><% = u %></td>
					 <%
					 for i = 0 to rowcount

							if cint(scores(1,i)) < cint(scores(2,i)) then
								%><td><% = scores(9,i) %></td><%
							else
								%><td class="winner"><% = scores(9,i) %></td><%
								u_score = u_score + 1
							end if	
						 
					 next
					 %><td><% = u_score %></td></tr><%
				 
				 else
				 	 u = trim(u)
					 u_score = 0
					 %><tr>
					 <td><% = u %></td>
					 <%
					 for i = 0 to rowcount
					 
						 sql = "select * from football.picks2 where username=? and game_id=" & scores(0,i)
						 
						 set cmd=server.createobject("adodb.command") 'create a command object
						 set cmd.activeconnection=cn // set active connection to the command object
				 
						 cmd.commandtext=sql
						 cmd.prepared=true
						 cmd.parameters.append cmd.createparameter("username",200,,50)
				 
				 
						 cmd("username") = u
						 
						 set rs = cmd.execute
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
					 %><td><% = u_score %></td></tr><%
				 end if
			 next
			 %>
			 
			 </table>
		<br />
		<br />
		<% end if %>
		<form name="compareform" action="compare.asp">
		<table>
		<tr><td colspan=3>Week # <select name="week_id">
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
		<tr><td valign=top>Compare <select name="primary">
		<%
		sql = "select distinct username from football.picks2 order by username"
		set rs = cn.execute(sql)
		while not rs.eof
			if primary = rs("username") then
				%>
				<option value="<% = rs("username") %>" selected><% = rs("username") %></option>
				<%
			else
				%>
				<option value="<% = rs("username") %>" ><% = rs("username") %></option>
				<%
			end if
			rs.movenext
		wend 
		rs.close
		
		%>
		</select> </td><td valign=top> to </td><td valign=top><select name="secondary" multiple size=5>
		<%
		sql = "select distinct username from football.picks2 order by username"
		set rs = cn.execute(sql)
		while not rs.eof
		  %>
		  <option value="<% = rs("username") %>" ><% = rs("username") %></option>
		  <%
			rs.movenext
		wend 
		rs.close
		
		%>
		<option value="Special_Pick_Vegas">Vegas</option>
		<option value="Special_Pick_Pumpkin">Pumpkin</option>
		<option value="Special_Pick_Hunter">Hunter</option>
		<option value="CALCULATED_PICK_AWAY">Away Teams</option>
		<option value="CALCULATED_PICK_HOME">Home Teams</option>
		<option value="CALCULATED_PICK_MAJORITY">Majority</option>
		</select></td></tr>
		<tr><td colspan=3><input type="submit" value="Compare"></td></tr>
		
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