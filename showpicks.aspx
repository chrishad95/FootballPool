<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
	private myname as string = ""

	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub
</script>
<%

server.execute("/football/cookiecheck.aspx")

dim fb as new Rasputin.FootballUtility()
fb.initialize()

dim myname as string = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
	
dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

dim pool_id as integer
try
	if request("pool_id") <> "" then
		pool_id = request("pool_id")
	end if
catch 
end try

dim isowner as boolean = false
if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
	isowner = true
end if
if myname = "" then
	response.redirect("login.aspx?returnurl=showpicks.aspx?pool_id=" & pool_id, true)
end if
if fb.isplayer(pool_id:=pool_id, player_name:=myname) or isowner then
else	
	callerror("Invalid pool_id")
end if

dim week_id as integer
dim week_is_set as boolean = false
try
	if request("week_id") <> "" then
		week_id = request("week_id")
		week_is_set = true
	end if
catch 
end try
if not week_is_set then
	week_id = fb.getdefaultweek(pool_id:=pool_id)
end if

dim weeks_ds as new dataset()
weeks_ds = fb.listweeks(pool_id:=pool_id)

try
	dim foundweek as boolean = false
	for each drow as datarow in weeks_ds.tables(0).rows
		if drow("week_id") = week_id then
			foundweek = true
		end if
	next
	if not foundweek then
		week_id = weeks_ds.tables(0).rows(0)("week_id")
	end if
catch
end try

dim picks_ds as new dataset()
picks_ds = fb.getallpicksforweek(pool_id:=pool_id, week_id:=week_id)

dim games_ds as new dataset()
games_ds = fb.GetGamesForWeek(pool_id:=pool_id, week_id:=week_id)

dim players_ds as new dataset()
players_ds = fb.getplayers(pool_id:=pool_id)


dim scores_ds as new dataset()
scores_ds = fb.getscoresforweek(pool_id:=pool_id, week_id:=week_id)

dim player_scores_ds as new dataset()
player_scores_ds = fb.GetPlayerScoresForWeek(pool_id:=pool_id, week_id:=week_id)

dim sort_by as string = "SCORE"
dim sort_dir as string = "DESC"

try
	if request("sort_by") = "USERNAME" OR request("sort_by") = "SCORE" then
		sort_by = request("sort_by")
	end if
catch
end try
try
	if request("sort_dir") = "ASC" or request("sort_dir") = "DESC" then
		sort_dir = request("sort_dir")
	end if
catch
end try

dim playertiebreakers_ds as new dataset()
playertiebreakers_ds = fb.GetPlayerTiebreakers(pool_id:=pool_id, week_id:=week_id)

dim tiebreaker_game as string
tiebreaker_game = fb.GetTiebreaker(pool_id:=pool_id, week_id:=week_id)

dim picks_can_be_shown as boolean = fb.pickscanbeseen(pool_id:=pool_id, week_id:=week_id)

dim printview as string = ""
try 
	if request("printview") <> "" then
		printview = request("printview")
	end if
catch
end try
dim pool_details_ds as new dataset()
pool_details_ds = fb.getpooldetails(pool_id:= pool_id)


dim banner_image as string = fb.getbannerimage(pool_id)

dim pool_name as string = ""
pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

dim options_ht as new system.collections.hashtable()
options_ht = fb.getPoolOptions(pool_id:=pool_id)

%>

<html>
<head>
	<title>Show Picks - <% = pool_name %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	<style type="text/css">
	.winner {
		text-align: center;
		
	}
	.winner_cell {
		background-color: #00FF00;
		text-align: center;
		
	}
	.teams_cell {
		text-align: center;
	}
	.home_pick_cell {
		background-color: Lavender;
	}
	.away_pick_cell {
		background-color: MistyRose;
	}
	.loser {
		text-decoration: line-through;
		text-align: center;
	}
	.loser_cell {
		text-align: center;
	}
	.score_cell {
		text-align: right;
	}
	.teamname {
		text-align: left;
	}
	.playername {
		text-align: left;
	}
	.table_header {
		background-color: #C0C0C0;
	}
	td {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		whitespace: nowrap;

	}
	tr:hover {
		background: #ffffd9;	
	}
	.nopick_cell {
		background-color: #FFFF99;
	}
	.hidden_pick_cell {
		background-color: #0099CC;
	}
	
	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
	.weekselect {
		text-align: left;
	}
	@media print {
	   #NavAlpha {
	   	width:0;
	   }
	   .content {
	   		margin: 0 0 0 0;
		}
	}
	</style>
</head>

<body>

	<div class="content">
		<%
			if banner_image = "" then
				%><h1><% = pool_name %></h1><%
			else
				%><img src="<% = banner_image %>" border="0"><BR><BR><%
			end if
		%>
		<form>
		<input type="hidden" name="pool_id" value="<% = pool_id %>">
		<table>
		<tr><td colspan=3 id="weekselect" >Week # <select name="week_id" onChange="this.form.submit.click()">
		<%
		try
			for each drow as datarow in weeks_ds.tables(0).rows
				dim i as integer = drow("week_id")
				if i  = week_id then
					%>
					<option value="<% = i %>" selected><% = i %></option>
					<%
				else
					%>
					<option value="<% = i %>"><% = i %></option>
					<%
				end if
			next
		catch
		end try
		%>
		</select> <input type="submit" name="submit" value="Refresh"></td></tr>
		</table>
		</form>
		<%
		
		if printview = "true" then

			dim player_rows as datarow()
			if sort_dir = "ASC" then
				sort_dir = "DESC"
			else
				sort_dir = "ASC"
			end if

			if sort_by = "SCORE" then
				player_rows = player_scores_ds.tables(0).select(filterExpression:="1=1", sort:=sort_by & " " & sort_dir)
			else
				player_rows = players_ds.tables(0).select(filterExpression:="1=1", sort:=sort_by & " " & sort_dir)
			end if
			%>
			<table cellspacing="0" cellpadding="0" border="1">
			<tr>
			<%
			for each pdrow as datarow in player_rows

				dim pname as string = ""
				if pdrow("nickname") is dbnull.value then
					pname = pdrow("username")
				else
					if pdrow("nickname") <> "" then
						pname = pdrow("nickname")
					else
						pname = pdrow("username")
					end if
				end if

				%><td ><img src="/photo_viewer/txt2pic.aspx?t=<% = pname %>&w=150&h=20" border="0"></td><%
			next 
			%>
			<td ><img src="/photo_viewer/txt2pic.aspx?t=Player&w=150&h=20" border="0"></td>
			</tr>
			<%
			
			for each gdrow as datarow in games_ds.tables(0).rows
				%><tr><%
				for each pdrow as datarow in player_rows

					dim player_weekly_score as integer = 0
					if picks_can_be_shown then
						try
							dim scoretemprows as datarow()
							scoretemprows = player_scores_ds.tables(0).select("username='" & pdrow("username") & "'")
							if scoretemprows.length > 0 then
								player_weekly_score = scoretemprows(0)("score")
							end if
						catch ex as exception
							fb.makesystemlog("Error in showpicks.aspx", ex.tostring())
						end try
					end if

					dim player_tbscore as integer = 0
					if playertiebreakers_ds.tables.count > 0 then
						dim temprows37 as datarow()
						temprows37 = playertiebreakers_ds.tables(0).select("username='" & pdrow("username") & "'")
						if temprows37.length > 0 then
							player_tbscore = temprows37(0)("score")
						end if
					end if

					dim away_name as string = gdrow("away_shortname")
					dim home_name as string = gdrow("home_shortname")

					dim temprows as datarow()
					temprows = picks_ds.tables(0).select("username='" & pdrow("username") & "' and game_id=" & gdrow("game_id"))
					dim scorerows as datarow()
					scorerows = scores_ds.tables(0).select("game_id=" & gdrow("game_id"))
					dim tbstring as string = ""
					if gdrow("game_id") = tiebreaker_game then
						tbstring = ":&nbsp;" & player_tbscore
					end if
					if temprows.length > 0 then			

						'	If DateTime.Compare(t1, t2) > 0 Then
						'		Console.WriteLine("t1 > t2")
						'	End If
						'	If DateTime.Compare(t1, t2) = 0 Then
						'		Console.WriteLine("t1 == t2")
						'	End If
						'	If DateTime.Compare(t1, t2) < 0 Then
						'		Console.WriteLine("t1 < t2")
						'	End If
						dim checkdate as datetime
						checkdate = datetime.now
						checkdate = checkdate.addminutes(30) 
						if picks_can_be_shown then
							if isowner then
								if temprows(0)("pick_name") = away_name then
									if scorerows.length > 0 then
										if scorerows(0)("away_score") > scorerows(0)("home_score") then
											%><td class="winner" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										else
											%><td class="loser" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										end if
									else
										%><td class="away_pick_cell" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
									end if
								elseif temprows(0)("pick_name") = home_name then
									if scorerows.length > 0 then
										if scorerows(0)("away_score") > scorerows(0)("home_score") then
											%><td class="loser" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										else
											%><td class="winner" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										end if
									else
										%><td class="home_pick_cell" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
									end if
								end if
							else
								if temprows(0)("pick_name") = away_name then
									if scorerows.length > 0 then
										if scorerows(0)("away_score") > scorerows(0)("home_score") then
											%><td class="winner" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										else
											%><td class="loser" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										end if
									else
										%><td class="away_pick_cell" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
									end if
								elseif temprows(0)("pick_name") = home_name then
									if scorerows.length > 0 then
										if scorerows(0)("away_score") > scorerows(0)("home_score") then
											%><td class="loser" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										else
											%><td class="winner" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
										end if
									else
										%><td class="home_pick_cell" ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("pick_name") %><% = tbstring %>&w=30&h=20" border="0"></td><%
									end if
								end if
							end if
						else
							%><td class="hidden_pick_cell" ><img src="/photo_viewer/txt2pic.aspx?t=??&w=30&h=20" border="0"></td><%
						end if
					else
						if picks_can_be_shown and isowner then
							%><td class="nopick_cell" ><img src="/photo_viewer/txt2pic.aspx?t=NP<% = tbstring %>&w=30&h=20" border="0"></td><%
						else
							%><td class="nopick_cell" ><img src="/photo_viewer/txt2pic.aspx?t=NP<% = tbstring %>&w=30&h=20" border="0"></td><%
						end if
					end if

				next 

				%><td class="pick_cell"><img src="/photo_viewer/txt2pic.aspx?t=<% = gdrow("away_shortname") %>NEWLINEatNEWLINE<% = gdrow("home_shortname") %>&w=30&h=60" border="0"></td><%

	
				
				%></tr><%
			next
			
				%><tr><%
			for each pdrow as datarow in player_rows

				dim temprows as datarow()
				temprows = player_scores_ds.tables(0).select("username='" & pdrow("username") & "'")
				if temprows.length > 0 then
					%><td ><img src="/photo_viewer/txt2pic.aspx?t=<% = temprows(0)("score") %>&w=20&h=20" border="0"></td><%
				else
					%><td ><img src="/photo_viewer/txt2pic.aspx?t=0&w=20&h=20" border="0"></td><%
				end if
			next 
				%><td ><img src="/photo_viewer/txt2pic.aspx?t=Score&w=60&h=20" border="0"></td></tr><%
			%>
			</table>
			<a href="showpicks.aspx?pool_id=<% = pool_id %>&week_id=<% = week_id %>">Regular View</a><br />
			<%

		else ' end of printview block
		' =======================================================
		'   beginning of the non printview block
		' =======================================================


			%>
			<table border=1 cellspacing=0 cellpadding=3>
			<tr><td colspan="<% = games_ds.tables(0).rows.count + 2 %>" class="table_header">Pick Results for Week # <% = week_id %></td></tr>
			<tr><%
				if sort_by = "USERNAME" then
					if sort_dir = "ASC" then
						%><td><a href="?pool_id=<% = pool_id %>&week_id=<% = week_id %>&sort_by=USERNAME&sort_dir=DESC">Player</a></td><%
					else
						%><td><a href="?pool_id=<% = pool_id %>&week_id=<% = week_id %>&sort_by=USERNAME&sort_dir=ASC">Player</a></td><%
					end if
				else
					%><td><a href="?pool_id=<% = pool_id %>&week_id=<% = week_id %>&sort_by=USERNAME&sort_dir=ASC">Player</a></td><%
				end if
			
				for i as integer = 0 to games_ds.tables(0).rows.count -1
					%><td class="teams_cell"><% = games_ds.tables(0).rows(i)("away_shortname") %><br />at<br /><% = games_ds.tables(0).rows(i)("home_shortname") %></td>
					<%				
				next
				if sort_by = "SCORE" then
					if sort_dir = "ASC" then
						%><td><a href="?pool_id=<% = pool_id %>&week_id=<% = week_id %>&sort_by=SCORE&sort_dir=DESC">Score</a></td><%
					else
						%><td><a href="?pool_id=<% = pool_id %>&week_id=<% = week_id %>&sort_by=SCORE&sort_dir=ASC">Score</a></td><%
					end if
				else
					%><td><a href="?pool_id=<% = pool_id %>&week_id=<% = week_id %>&sort_by=SCORE&sort_dir=DESC">Score</a></td><%
				end if

			%>
			</tr>
			<% 
			dim player_rows as datarow()
			if sort_by = "SCORE" then
				player_rows = player_scores_ds.tables(0).select(filterExpression:="1=1", sort:=sort_by & " " & sort_dir)
			else
				player_rows = players_ds.tables(0).select(filterExpression:="1=1", sort:=sort_by & " " & sort_dir)
			end if

				
			for each pdrow as datarow in player_rows
				dim player_weekly_score as integer = 0
				
				dim picktemprows as datarow()
				picktemprows = picks_ds.tables(0).select("username='" & pdrow("username") & "'")
				if picktemprows.length = 0 and picks_can_be_shown and options_ht("HIDENPROWS") = "on" then
				else

					if picks_can_be_shown then
						try
							dim scoretemprows as datarow()
							scoretemprows = player_scores_ds.tables(0).select("username='" & pdrow("username") & "'")
							if scoretemprows.length > 0 then
								player_weekly_score = scoretemprows(0)("score")
							end if
						catch ex as exception
							fb.makesystemlog("Error in showpicks.aspx", ex.tostring())
						end try
					end if

					dim player_tbscore as integer = 0
					if playertiebreakers_ds.tables.count > 0 then
						dim temprows37 as datarow()
						temprows37 = playertiebreakers_ds.tables(0).select("username='" & pdrow("username") & "'")
						if temprows37.length > 0 then
							player_tbscore = temprows37(0)("score")
						end if
					end if

					dim pname as string = ""
					if pdrow("nickname") is dbnull.value then
						pname = pdrow("username")
					else
						if pdrow("nickname") <> "" then
							pname = pdrow("nickname")
						else
							pname = pdrow("username")
						end if
					end if

					%><tr><td nowrap class="playername"><% = pname %></td><%

					for each gdrow as datarow in games_ds.tables(0).rows
						dim away_name as string = gdrow("away_shortname")
						dim home_name as string = gdrow("home_shortname")
						dim temprows as datarow()
						temprows = picks_ds.tables(0).select("username='" & pdrow("username") & "' and game_id=" & gdrow("game_id"))
						dim scorerows as datarow()
						scorerows = scores_ds.tables(0).select("game_id=" & gdrow("game_id"))
						dim tbstring as string = ""
						if gdrow("game_id") = tiebreaker_game then
							tbstring = "&nbsp;TB:" & player_tbscore
						end if
						if temprows.length > 0 then			

							'	If DateTime.Compare(t1, t2) > 0 Then
							'		Console.WriteLine("t1 > t2")
							'	End If
							'	If DateTime.Compare(t1, t2) = 0 Then
							'		Console.WriteLine("t1 == t2")
							'	End If
							'	If DateTime.Compare(t1, t2) < 0 Then
							'		Console.WriteLine("t1 < t2")
							'	End If
							dim checkdate as datetime
							checkdate = datetime.now
							checkdate = checkdate.addminutes(30) 
							if picks_can_be_shown then
								if isowner then
									if temprows(0)("pick_name") = away_name then
										if scorerows.length > 0 then
											if scorerows(0)("away_score") > scorerows(0)("home_score") then
												%><td class="winner_cell" ><span class="winner"><a href="correctpick.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>&game_id=<% = temprows(0)("game_id") %>"><% = temprows(0)("pick_name") %></a></span><a href="correcttbscore.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>"><% = tbstring %></a></td><%
											else
												%><td class="loser_cell" ><span class="loser"><a  href="correctpick.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>&game_id=<% = temprows(0)("game_id") %>"><% = temprows(0)("pick_name") %></a></span><a href="correcttbscore.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>"><% = tbstring %></a></td><%
											end if
										else
											%><td class="away_pick_cell" ><a href="correctpick.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>&game_id=<% = temprows(0)("game_id") %>"><% = temprows(0)("pick_name") %></a><a href="correcttbscore.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>"><% = tbstring %></a></td><%
										end if
									elseif temprows(0)("pick_name") = home_name then
										if scorerows.length > 0 then
											if scorerows(0)("away_score") > scorerows(0)("home_score") then
												%><td class="loser_cell" ><span class="loser"><a href="correctpick.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>&game_id=<% = temprows(0)("game_id") %>"><% = temprows(0)("pick_name") %></a></span><a href="correcttbscore.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>"><% = tbstring %></a></td><%
											else
												%><td class="winner_cell" ><span class="winner"><a href="correctpick.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>&game_id=<% = temprows(0)("game_id") %>"><% = temprows(0)("pick_name") %></a></span><a href="correcttbscore.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>"><% = tbstring %></a></td><%
											end if
										else
											%><td class="home_pick_cell" ><a href="correctpick.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>&game_id=<% = temprows(0)("game_id") %>"><% = temprows(0)("pick_name") %></a><a href="correcttbscore.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>"><% = tbstring %></a></td><%
										end if
									end if
								else
									if temprows(0)("pick_name") = away_name then
										if scorerows.length > 0 then
											if scorerows(0)("away_score") > scorerows(0)("home_score") then
												%><td class="winner_cell" ><span class="winner"><% = temprows(0)("pick_name") %><% = tbstring %></span></td><%
											else
												%><td class="loser_cell" ><span class="loser"><% = temprows(0)("pick_name") %><% = tbstring %></span></td><%
											end if
										else
											%><td class="away_pick_cell" ><% = temprows(0)("pick_name") %><% = tbstring %></td><%
										end if
									elseif temprows(0)("pick_name") = home_name then
										if scorerows.length > 0 then
											if scorerows(0)("away_score") > scorerows(0)("home_score") then
												%><td class="loser_cell" ><span class="loser"><% = temprows(0)("pick_name") %></span><% = tbstring %></td><%
											else
												%><td class="winner_cell" ><span class="winner"><% = temprows(0)("pick_name") %></span><% = tbstring %></td><%
											end if
										else
											%><td class="home_pick_cell" ><% = temprows(0)("pick_name") %><% = tbstring %></td><%
										end if
									end if
								end if
							else
								%><td class="hidden_pick_cell" >??</td><%
							end if
						else
							if picks_can_be_shown and isowner then
								%><td class="nopick_cell" ><a href="correctpick.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>&game_id=<% = gdrow("game_id") %>">NP</a><a href="correcttbscore.aspx?week_id=<% = week_id %>&pool_id=<% = pool_id %>&player_name=<% = pdrow("username") %>"><% = tbstring %></a></td><%
							else
								%><td class="nopick_cell" >NP<% = tbstring %></td><%
							end if
						end if
					next
					%><td class="score_cell"><% = player_weekly_score %></td></tr><%

				end if
			next
			%>
			
			</table>
			<a href="showpicks.aspx?pool_id=<% = pool_id %>&week_id=<% = week_id %>&printview=true">Printer Friendly View</a><br />
			<%
		end if ' non print view
		%>
		<br />
		Would you like to make a <a href="/donate.aspx">donation?</a><br /><br />

		Scoreboard<br />
		<%
		dim game_counter as integer = 0
		for each drow as datarow in games_ds.tables(0).rows
				dim away_name as string = drow("away_team")
				dim home_name as string = drow("home_team")
				dim away_score as string = "-"
				dim home_score as string = "-"

				dim scorerows as datarow()
				scorerows = scores_ds.tables(0).select("game_id=" & drow("game_id"))
				if scorerows.length > 0 then
					if scorerows(0)("away_score") is dbnull.value then
					else
						away_score = scorerows(0)("away_score")
					end if
					if scorerows(0)("home_score") is dbnull.value then
					else
						home_score = scorerows(0)("home_score")
					end if
				else
				end if
				if game_counter mod 3 = 0 then
					if game_counter > 0 then
						%>
							</td></tr>
						<%
					end if
					if game_counter = 0 then
						%>
						<table>
						<%
					end if
					%>
					<tr>
					<%
				end if
				%>
				<td width="205">
				<table border="1" cellspacing="0" cellpadding="0"><tr>
				<td><TABLE cellpadding="2" cellspacing="0" >
				<TR bgcolor="#C0C0C0">
					<TD width="200" class="teamname"><% = away_name %></TD>
					<TD width="5" class="score_cell"><% = away_score %></TD>
				</TR>
				<TR bgcolor="#66CCFF">
					<TD width="200" class="teamname"><% = home_name %></TD>
					<TD width="5" class="score_cell"><% = home_score %></TD>
				</TR>
				</TABLE></td></tr></table></td>
				<%
				game_counter = game_counter + 1
		next
		%></tr></table>
	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>

<!-- BlueRobot was here. -->
</body>
</html>
