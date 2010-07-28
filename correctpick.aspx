<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%
	server.execute("/football/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
	fb.initialize()
	
	dim myname as string
	myname = ""
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
		pool_id = request("pool_id")
	catch
	end try
	dim week_id as integer
	try
		week_id = request("week_id")
	catch
	end try

	dim game_id as integer 
	try
		game_id = request("game_id")
	catch
	end try
	dim team_id as integer
	try
		team_id = request("team_id")
	catch
	end try
	dim player_name as string
	try
		player_name = request("player_name")
	catch
	end try
	dim submit as string
	try
		submit = request("submit")
	catch
	end try
	if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
	else
		session("page_message") = "Invalid pool_id"
		response.redirect("error.aspx", true)
	end if

	if player_name = "" then
		session("page_message") = "Invalid player name."
		response.redirect("error.aspx", true)
	end if

	dim game_ds as new dataset()
	game_ds = fb.GetGameDetails(pool_id:=pool_id, game_id:=game_id)

	dim message_text as string = ""

	dim game_time as datetime
	dim away_team_name as string
	dim home_team_name as string
	dim home_id as integer
	dim away_id as integer

	if game_ds.tables.count > 0 then
		if game_ds.tables(0).rows.count > 0 then
			game_time = game_ds.tables(0).rows(0)("game_tsp")
			away_team_name = game_ds.tables(0).rows(0)("away_team_name")
			home_team_name = game_ds.tables(0).rows(0)("home_team_name")
			away_id = game_ds.tables(0).rows(0)("away_id")
			home_id = game_ds.tables(0).rows(0)("home_id")
		else
			session("page_message") = "Incorrect game_id."
			response.redirect("error.aspx", true)
		end if
	else
		session("page_message") = "Incorrect game_id."
		response.redirect("error.aspx", true)
	end if

	if submit = "Correct Pick" then
		dim res as string
		res = fb.updatepick(pool_id:=pool_id, game_id:=game_id, username:=player_name, team_id:=request("team_id"), mod_user:=myname)
		if res = player_name then
			message_text = "Pick was updated successfully."
		else
			message_text = "Pick was not updated."
		end if
	end if
	if submit = "Correct Pick, Show Picks" then
		dim res as string
		res = fb.updatepick(pool_id:=pool_id, game_id:=game_id, username:=player_name, team_id:=request("team_id"), mod_user:=myname)
		if res = player_name then
			response.redirect("showpicks.aspx?pool_id=" & pool_id & "&week_id=" & week_id, true)
		else
			message_text = "Pick was not updated."
		end if
	end if
	dim pick as integer
	pick = fb.getpick(pool_id:=pool_id, game_id:=game_id, player_name:=player_name)

%>
<html>
<head>
	<title>Correct Pick - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style2.css";</style> 
	<script type="text/javascript" src="jquery.js"></script>
	<script type="text/javascript" src="cmxform.js"></script>
	<style>
		
		form.cmxform fieldset {
		  margin-bottom: 10px;
		}
		form.cmxform legend {
		  padding: 0 2px;
		  font-weight: bold;
		}
		form.cmxform label {
		  display: inline-block;
		  line-height: 1.8;
		  vertical-align: top;
		}
		form.cmxform fieldset ol {
		  margin: 0;
		  padding: 0;
		}
		form.cmxform fieldset li {
		  list-style: none;
		  padding: 5px;
		  margin: 0;
		}
		form.cmxform fieldset fieldset {
		  border: none;
		  margin: 3px 0 0;
		}
		form.cmxform fieldset fieldset legend {
		  padding: 0 0 5px;
		  font-weight: normal;
		}
		form.cmxform fieldset fieldset label {
		  display: block;
		  width: auto;
		}
		form.cmxform em {
		  font-weight: bold;
		  font-style: normal;
		  color: #f00;
		}
		form.cmxform label {
		  width: 120px; /* Width of labels */
		}
		form.cmxform fieldset fieldset label {
		  margin-left: 123px; /* Width plus 3 (html space) */
		}
	</style>
	
</head>

<body>


	<div id="Header">
		<a href="/"><% = http_host %></a>
	</div>

	<div id="Content">

		<form class="cmxform">
			<input type="hidden" name="player_name" value="<% = player_name %>">
			<input type="hidden" name="pool_id" value="<% = pool_id %>">
			<input type="hidden" name="game_id" value="<% = game_id %>">
			<input type="hidden" name="week_id" value="<% = week_id %>">
			<fieldset>
				<legend>Correct Pick</legend>
				<TABLE border=1 cellspacing=0 cellpadding=1>
				<TR>
					<TD>Player Name:</TD>
					<TD><% = player_name %></TD>
				</TR>
				<TR>
					<TD>Game Time:</TD>
					<TD><% = game_time %></TD>
				</TR>
				<TR>
					<TD>Away:</TD>
					<% 
					if pick = away_id then
						%><TD><INPUT TYPE="radio" NAME="team_id" value="<% = away_id %>" checked><% = away_team_name %></TD><%
					else
						%><TD><INPUT TYPE="radio" NAME="team_id" value="<% = away_id %>"><% = away_team_name %></TD><%
					end if 
					%>
				</TR>
				<TR>
					<TD>Home:</TD>
					<%
					if pick = home_id then	
						%><TD><INPUT TYPE="radio" NAME="team_id" value="<% = home_id %>" checked><% = home_team_name %></TD><%
					else
						%><TD><INPUT TYPE="radio" NAME="team_id" value="<% = home_id %>"><% = home_team_name %></TD><%
					end if
					%>
					
				</TR>
				</TABLE>
				<input type="submit" name="submit" value="Correct Pick" /> <input type="submit" name="submit" value="Correct Pick, Show Picks" />
			</fieldset>
		</form>

	</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

	<%
	if message_text <> "" then
		%><script>window.alert("<% = message_text.replace("""", "\""") %>")</script><%
	end if
	%>
</body>
</html>
