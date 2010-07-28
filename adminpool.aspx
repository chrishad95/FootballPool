<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Collections" %>
<script runat="server" language="VB">
	private myname as string = ""
	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub

</script>
<%
	dim fb as new Rasputin.FootballUtility()
	fb.initialize()

	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try

	server.execute ("/football/cookiecheck.aspx")
	dim message_text as string = ""
	try
		myname = session("username")
	catch
	end try
	if myname = "" then
		session("page_message") = "You must login to create pools."
		response.redirect("error.aspx", true)
	end if

	dim pool_id as integer
	try
		if request("pool_id") <> "" then
			pool_id = request("pool_id")
		end if
	catch
	end try
	dim isowner as boolean = false
	isowner = fb.isowner(pool_id:=pool_id, pool_owner:=myname) 
	
	if isowner then
	else		
		session("page_message") = "Invalid pool_id."
		response.redirect("error.aspx", true)
	end if

	try
		if request("submit") = "Update Pool Details" then
			fb.updatepool(pool_id:=pool_id, pool_owner:=myname, pool_name:=request("poolname"), pool_desc:=request("desc"), pool_banner:=request("bannerurl"), pool_logo:=request("logourl"), eligibility:=request("eligibility"), scorer:=request("scorer"))
		end if
	catch
	end try
	'CreateTeam(TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER)
	try
		if request("submit") = "Add Team" then
			dim res as string = ""
			res = fb.createteam(pool_id:=pool_id, pool_owner:=myname, team_name:=request("team_name"), team_shortname:=request("team_shortname"), url:=request("url"))
			if res <> request("team_name") then
				message_text = res
			else
				message_text = "Team was added successfully."
			end if
		end if
	catch
	end try

	'CreateGame(WEEK_ID as INTEGER, HOME_ID as INTEGER, AWAY_ID as INTEGER, GAME_TSP as datetime, GAME_URL as String, POOL_ID as INTEGER)
	try
		if request("submit") = "Add Game" then

			dim res as string = ""
			res = fb.creategame(pool_id:=pool_id, pool_owner:=myname, week_id:=request("week_id"), home_id:=request("home_id_select"), away_id:=request("away_id_select"), game_tsp:=request("game_time"), game_url:=request("game_url"))
			if res <> myname then
				message_text = res
			else
				message_text = "Game was added successfully."
			end if
		end if
	catch ex as exception
		message_text = ex.message
		fb.makesystemlog("error adding game", ex.tostring())
	end try

	try
		if request("submit") = "Update Game" then

			dim res as string = ""
			res = fb.updategame(game_id:=request("game_select"), pool_id:=pool_id, pool_owner:=myname, week_id:=request("week_id"), home_id:=request("home_id_select"), away_id:=request("away_id_select"), game_tsp:=request("game_time"), game_url:=request("game_url"))
			if res <> myname then
				message_text = res
			else
				message_text = "Game was updated successfully."
			end if
		end if
	catch ex as exception
		message_text = ex.message
		fb.makesystemlog("error adding game", ex.tostring())
	end try

	try
		if request("submit") = "Edit Team" then
			dim res as string = ""
			res = fb.updateteam(team_id:=request("team_select"), pool_id:=pool_id, pool_owner:=myname, team_name:=request("team_name"), team_shortname:=request("team_shortname"), url:=request("url"))
			if res <> request("team_name") then
				message_text = res
			else
				message_text = "Team was updated successfully."
			end if
		end if
	catch
	end try

	try
		if request("submit") = "Import Team" then
			dim res as string = ""
			dim sel as string = ""
			try
				if request("team_select") <> "" then
					sel = request("team_select")
				end if
			catch
			end try
			dim teams as string()
			teams = sel.split(",")
			for each t as string in teams
				res = res & fb.importteam(team_id:=t, pool_id:=pool_id, pool_owner:=myname)
			next
			message_text = res 

		end if
	catch
	end try

	try
		if request("submit") = "Import Game" then
			dim res as string = ""
			dim sel as string = ""
			try
				if request("import_game_select") <> "" then
					sel = request("import_game_select")
				end if
			catch
			end try

			dim games as string()
			games = sel.split(",")
			for each t as string in games
				res = res & fb.importgame(game_id:=t, pool_id:=pool_id, pool_owner:=myname)
			next
			message_text = res 

		end if
	catch
	end try


	try
		if request("submit") = "Add Games" then
			dim res as string = ""
			res = fb.AddGames(pool_id:=pool_id, pool_owner:=myname, games_text:=request("games_text"))
			if res <> myname then
				message_text = res
			else
				message_text = "Games were added successfully."
			end if
		end if
	catch
	end try

	try
		if request("submit") = "Set Tiebreaker Game" then
			dim res as string = ""
			res = fb.UpdateTiebreaker(pool_id:=pool_id, pool_owner:=myname, week_id:=request("tb_weekid_select"), game_id:=request("tb_game_select"))
			if res <> myname then
				message_text = res
			else
				message_text = "Tiebreaker was set successfully."
			end if
		end if
	catch
	end try

	try
		if request("submit") = "Set Feed" then
			dim res as string = ""
			res = fb.SetFeed(pool_id:=pool_id, feed_id:=request("rssfeed_select"))
			if res <> pool_id then
				message_text = res
			else
				message_text = "Feed was set successfully."
			end if
		end if
	catch
	end try


	dim options_ht as new system.collections.hashtable()
	options_ht = fb.getPoolOptions(pool_id:=pool_id)

	try
		if request("submit") = "Update Pool Options" then

			dim res as string = ""
			for each o as string in options_ht.keys
				try
					if request("opt" & o.tostring()) = "on" then
						res = fb.SetOption(pool_id:=pool_id, optionname:=o.tostring(), optionvalue:="on")
					else
						res = fb.SetOption(pool_id:=pool_id, optionname:=o.tostring(), optionvalue:="off")
					end if
				catch
				end try
			next
			
			options_ht = fb.getPoolOptions(pool_id:=pool_id)
		end if
	catch
	end try

	try
		if request("submit") = "Invite Player" then
			dim res as string = ""
			res = fb.InvitePlayer(pool_id:=pool_id, username:=myname, email:=request("invite_player_email"))

			if res = "SUCCESS" then
				message_text = "The invitation was sent." 
			else
				message_text = "There was a problem sending the invitation."
			end if
		end if
	catch
	end try

	try
		if request("submit") = "Invite Previous Players" then
			dim res as string = ""
			dim sel as string = ""
			try
				if request("invite_previous_players") <> "" then
					sel = request("invite_previous_players")
				end if
			catch
			end try
			dim previous_players as string()
			previous_players = sel.split(",")
			for each player_name as string in previous_players
				res = fb.InvitePreviousPlayer(pool_id:=pool_id, username:=myname, player_name:=player_name)
			next

			if res = "SUCCESS" then
				message_text = "The invitation was sent." 
			else
				message_text = "There was a problem sending the invitation."
			end if

		end if
	catch
	end try



	try
		if request("submit") = "Import Team" then
			dim res as string = ""
			dim sel as string = ""
			try
				if request("team_select") <> "" then
					sel = request("team_select")
				end if
			catch
			end try
			dim teams as string()
			teams = sel.split(",")
			for each t as string in teams
				res = res & fb.importteam(team_id:=t, pool_id:=pool_id, pool_owner:=myname)
			next
			message_text = res 

		end if
	catch
	end try






















	dim pool_ds as dataset
	pool_ds = fb.GetPoolDetails(pool_id)
	
	dim pool_drow as datarow

	if pool_ds.tables.count > 0 then
		if pool_ds.tables(0).rows.count > 0 then
			Pool_drow = pool_ds.tables(0).rows(0)
		else
			callerror("Pool not found.")
		end if
	else
		callerror("Pool not found.")
	end if
	dim teams_ds as dataset
	teams_ds = fb.getpoolteams(myname, pool_id)

	dim players_ds as dataset
	players_ds = fb.getPoolPlayers(pool_id:=pool_id)

	dim importteams_ds as dataset
	importteams_ds = fb.getImportTeams()

	dim importgames_ds as dataset
	importgames_ds = fb.getImportGames()

%>
<html>
<head>
<title>Pool Admin Page</title>    
	<script type="text/javascript" src="jquery.js"></script>
    <script type="text/javascript" src="cmxform.js"></script>
	 <script>
		var teams = {};
		<%
		try
			for each team_drow as datarow in teams_ds.tables(0).rows
				response.write(system.environment.newline)
				%>teams[<% = team_drow("team_id") %>]= new Array("<% = team_drow("team_name") %>","<% = team_drow("team_shortname") %>","<% = team_drow("url") %>");<%
			next
		catch
		end try
		
		%>

		var tiebreakers = {};
		<%
		try
			dim tb_ds as new dataset()
			tb_ds = fb.GetTiebreakers(pool_id:=pool_id, pool_owner:=myname)
			if tb_ds.tables.count > 0 then
				if tb_ds.tables(0).rows.count > 0 then
					for each drow as datarow in tb_ds.tables(0).rows
						response.write(system.environment.newline)
						%>tiebreakers[<% = drow("week_id") %>]= <% = drow("game_id") %>;<%
					next
				end if
			end if
		catch ex as exception
			fb.makesystemlog("error getting tiebreakers js", ex.tostring())
		end try
		%>


		function handleteamselect() {
			var x=document.getElementsByName("team_select");
			var idx = x[0].value;

			x = document.getElementsByName("team_name");
			x[0].value = teams[idx][0];

			x = document.getElementsByName("team_shortname");
			x[0].value = teams[idx][1];

			x = document.getElementsByName("url");
			x[0].value = teams[idx][2];

		}

		var games = {};
		<%

		try	
			dim temp_ds as new dataset()
			temp_ds = fb.GetPoolGames(pool_id:=pool_id, pool_owner:=myname)
			for each drow as datarow in temp_ds.tables(0).rows
				response.write(system.environment.newline)
				%>games[<% = drow("game_id") %>]= new Array("<% = drow("week_id") %>","<% = drow("home_id") %>","<% = drow("away_id") %>","<% = drow("game_tsp") %>","<% = drow("game_url") %>");<%
			next
		catch
		end try
		
		%>



		function addexampletext() {
			var exampletext = "";
			exampletext = exampletext +  "1,Miami Dolphins,Pittsburgh Steelers,09/10/2009 8:30 PM\n";
			exampletext = exampletext + "1,atl,car,09/11/2009 13:00\n";
			exampletext = exampletext + "1,Baltimore Ravens,Tampa Bay Buccaneers,09/11/2009 1:00 PM\n";
			exampletext = exampletext + "1,Buffalo Bills,New England Patriots,09/11/2009 1:00 PM\n";

			var x=document.getElementsByName("games_text");
			x[0].value = exampletext;

		}


		function handletbselect() {
	
			var x=document.getElementsByName("tb_weekid_select");
			if (x[0].selectedIndex > 0) {

				var y=document.getElementsByName("tb_game_select");
				y[0].options.length = 0;
				y[0].options[y[0].options.length] = new Option("Select Game", "", true, true)

				for (var i in games)
				{
					if (games[i][0] == x[0].value) {
						y[0].options[y[0].options.length] = new Option("" + teams[games[i][2]][0] + " at " + teams[games[i][1]][0], i, false, false)
					}
				}

				if (tiebreakers[x[0].value]) {
					for (var i=0; i<y[0].options.length; i++) {
						if (y[0].options[i].value == tiebreakers[x[0].value]) {
							y[0].selectedIndex = i;
						}
					}
				}
			}
		}


		function handlegameselect() {
			var x=document.getElementsByName("game_select");
			if (x[0].selectedIndex > 0)
			{
				var idx = x[0].value;

				x = document.getElementsByName("away_id_select");
				var i = 0;
				for (i=0; i< x[0].length; i++)
				{
					if (x[0].options[i].value == games[idx][2])
					{
						x[0].selectedIndex = i;
					}
				}
				x = document.getElementsByName("home_id_select");
				var i = 0;
				for (i=0; i< x[0].length; i++)
				{
					if (x[0].options[i].value == games[idx][1])
					{
						x[0].selectedIndex = i;
					}
				}
				x = document.getElementsByName("game_time");				
				x[0].value = games[idx][3];
				x = document.getElementsByName("week_id");				
				x[0].value = games[idx][0];
				x = document.getElementsByName("game_url");				
				x[0].value = games[idx][4];
			}
		}
	 </script>
	<style type="text/css" media="all">@import "/football/style2.css";</style>
	<style type="text/css" media="all">@import "like-adw.css";</style>
	<style type="text/css" media="all">@import "cmxform.css";</style>
	<style>
		.smallprint {
			font-size: 10px;
		}
	</style>

</head>

<body onLoad="handleteamselect()">

<div id="Header"><% = http_host %></div>

<div id="Content">
	<h2><% = pool_drow("pool_name") %></h2>

	<%
	if message_text <> "" then
		%><script>window.alert("<% = message_text.replace("""", "\""") %>")</script><%
	end if
	%>
	<a href="#details">Details</a> - 
	<a href="#teams">Teams</a> - 
	<a href="#players">Players</a> - 
	<a href="#invitations">Invites</a> - 
	<a href="#games">Games</a> - 
	<a href="#tiebreakers">Tie Breakers</a> - 
	<a href="#rssfeed">RSS Feeds</a> - 
	<a href="#options">Options</a> 
	<br />

	<a name="details"></a>
	<form class="cmxform">
		<input type="hidden" name="pool_id" value="<% = pool_drow("pool_id") %>" />
		<fieldset>
			<legend>Pool Details</legend>
			<ol>
				<li><label for="poolname">Name <em>*</em></label> <input type="text" name="poolname" id="poolname" value = "<% = pool_drow("pool_name") %>" /></li>
				<li><label for="desc">Description </label> <textarea id="desc" name="desc" cols="40" rows="5" /><% = pool_drow("pool_desc") %></textarea></li>
				<li><label for="bannerurl">Banner Url </label> <select id="bannerurl" name="bannerurl" >
				<%
					dim userfiles as new system.collections.arraylist()
					userfiles = fb.getfiles(server.mappath("/users/" & myname ))
					dim myenum as system.collections.ienumerator = userfiles.getEnumerator()
					while myenum.movenext()
						if not pool_drow("pool_banner") is dbnull.value then
							if myenum.current.tostring() = pool_drow("pool_banner")
								%><option value="<% = myenum.current.tostring() %>" SELECTED><% = myenum.current.tostring() %></option><%
							else
								%><option value="<% = myenum.current.tostring() %>"><% = myenum.current.tostring() %></option><%
							end if
						else
							%><option value="<% = myenum.current.tostring() %>"><% = myenum.current.tostring() %></option><%

						end if
					end while

				%>				
				</select></li>
				<li><label for="logourl">Logo Url </label> <input id="logourl" name="logourl" value="<% = pool_drow("pool_logo") %>" /></li>
				<li><label for="eligibility">Eligibility <em>*</em></label> <select name="eligibility" id="eligibility"><%
					try
						dim temparray() as string = {"OPEN","CLOSED"}
						for each s as string in temparray
							if s = pool_drow("eligibility") then
								%><option value="<% = s %>" SELECTED><% = s %></option><%
							else
								%><option value="<% = s %>" ><% = s %></option><%
							end if
						next
					catch ex as exception
						fb.makesystemlog("Error in adminpool.aspx", ex.tostring())
					end try
				
				%></select></li>
				<li><label for="scorer">Scorer</label> <select name="scorer" id="scorer">
				<option value="">None</option>
				<%
					try

						dim scorer as string = ""

						if not pool_drow("scorer") is dbnull.value then
							scorer = pool_drow("scorer")
						end if

						if players_ds.tables.count > 0 then
							if players_ds.tables(0).rows.count > 0 then
								for each player_drow as datarow in players_ds.tables(0).rows
									
									dim pname as string = ""
									if player_drow("nickname") is dbnull.value then
										pname = player_drow("username")
									else
										if player_drow("nickname") <> "" then
											pname = player_drow("nickname")
										else
											pname = player_drow("username")
										end if
									end if

									if player_drow("username") = scorer then
										%><option value="<% = player_drow("username") %>" SELECTED><% = pname %></option><%
									else
										%><option value="<% = player_drow("username") %>" ><% = pname %></option><%
									end if
								next
							end if
						end if

					catch ex as exception
						fb.makesystemlog("Error in adminpool.aspx", ex.tostring())
					end try
				
				%></select></li>
			</ol>
			<input type="submit" name="submit" value="Update Pool Details" />
		</fieldset>
	</form>

	<a name="teams"></a>
		<fieldset>
			<legend>Teams</legend>
			<form class="cmxform">
				<input type="hidden" name="pool_id" value="<% = pool_id %>">
				<%
					if teams_ds.tables.count > 0 then
						if teams_ds.tables(0).rows.count > 0 then
							%><li><label for="team_select">Teams </label> <select onChange="handleteamselect()" name="team_select" id="team_select"><%
							for each team_drow as datarow in teams_ds.tables(0).rows
								%><option value="<% = team_drow("team_id") %>"><% = team_drow("team_name") %></option><%
							next
							%></select> <input type="submit" name="submit" value="Delete Team"></li><%
						else
							%><ol><li><label >No teams found.</label></li></ol><%
						end if
					else
						%><ol><li><label >No teams found.</label></li></ol><%
					end if
				%>
				
				<ol>
					<li><label ><b>Team Details</b></label></li>
					<li><label for="team_name">Team Name <em>*</em></label> <input type="text" name="team_name" id="team_name" value = "" /></li>
					<li><label for="team_shortname">Team Shortname </label> <input type="text" id="team_shortname" name="team_shortname" /></li>
					<li><label for="url">Team Url </label> <input id="url" name="url" value="" /></li>
				</ol>
				<input type="submit" name="submit" value="Add Team" /> <input type="submit" name="submit" value="Edit Team">
			</form>
			<form name="importeams">
				<input type="hidden" name="pool_id" value="<% = pool_id %>">
				<select name="team_select" id="importteamselect" multiple>
				<%
				for each importteam as datarow in importteams_ds.tables(0).rows
					%><option value="<% = importteam("team_id") %>"><% = importteam("team_name") %></option><%
				next
				%>
				</select>
				<input type="submit" name="submit" value="Import Team" />
			</form>
		</fieldset>

	<a name="players"></a>
	<form class="cmxform">
		<input type="hidden" name="pool_id" value="<% = pool_drow("pool_id") %>" />
		<fieldset>
			<legend>Players</legend>
			<%
				if players_ds.tables.count > 0 then
					if players_ds.tables(0).rows.count > 0 then
						%><ol><li><label for="player_select">Players </label> <select name="player_select" id="player_select"><%
						for each player_drow as datarow in players_ds.tables(0).rows
							
							dim pname as string = ""
							if player_drow("nickname") is dbnull.value then
								pname = player_drow("username")
							else
								if player_drow("nickname") <> "" then
									pname = player_drow("nickname")
								else
									pname = player_drow("username")
								end if
							end if

							%><option value="<% = player_drow("player_id") %>"><% = pname %></option><%
						next
						%></select> <input type="submit" name="submit" value="Delete Player"></li></ol><%
					else
						%><ol><li><label >No players found.</label></li></ol><%
					end if
				else
					%><ol><li><label >No players found.</label></li></ol><%
				end if
			%>
		</fieldset>

		<a name="invitations"></a>
		<fieldset>
			<legend>Invitations</legend>
			<ol>
				<li><label for="invite_player_email">Email </label> <input type="text" name="invite_player_email" id="invite_player_email" value = "" /> <input type="submit" name="submit" value="Invite Player"></li>
			</ol>
			Invite Players From Previous Pools:<br />
			<select name="invite_previous_players" multiple size=5>
			<%
			try
				dim previousplayers_ds as new dataset()
				previousplayers_ds = fb.GetPreviousPlayers(pool_owner:=myname)

				for each pprow as datarow in previousplayers_ds.tables(0).rows
					%><option value="<% = pprow("username") %>"><% = pprow("username") %></option>
<%
				next
			catch ex as exception
			end try
			%>
			</select><br />
			<input type="submit" name="submit" value="Invite Previous Players"><br />
			<%
				try
					dim invites_ds as dataset
					invites_ds = fb.GetPoolInvitations(pool_id:=pool_id, pool_owner:=myname)

					if invites_ds.tables.count > 0 then
						if invites_ds.tables(0).rows.count > 0 then
							%>
							<table>			
							<caption>Open Invitations</caption>
							<thead>
								<tr>
									<th scope="col">Email Address</th>
									<th scope="col">Invitation Time</th>
									<th scope="col">Actions</th>
								</tr>
							</thead>	
							<tfoot>
								<tr>
									<th scope="row">Total</th>
									<td colspan="2"><% = invites_ds.tables(0).rows.count %> invitations</td>
								</tr>
							</tfoot>	
							<tbody>
							<%
							for each invite_drow as datarow in invites_ds.tables(0).rows
								%><tr>
								<td><% = invite_drow("email") %></td>
								<td><% = invite_drow("invite_tsp") %></td>
								<td><a href="deleteinvite.aspx?pool_id=<% = pool_id %>&email=<% = system.web.httputility.urlencode(invite_drow("email"))  %>">Delete</a><br />
								<a href="resendinvite.aspx?pool_id=<% = pool_id %>&email=<% = system.web.httputility.urlencode(invite_drow("email")) %>">Resend</a></td>
								</tr><%
							next
							%></tbody></table><%
						else
							%><ol><li><label >No invitations found.</label></li></ol><%
						end if
					else
						%><ol><li><label >No invitations found.</label></li></ol><%
					end if
				catch ex as exception
					fb.makesystemlog("error in adminpool.aspx", ex.tostring())
				end try
			%>
		</fieldset>
	</form>
	
	<a name="games"></a>
	<form class="cmxform" method="post">
		<input type="hidden" name="pool_id" value="<% = pool_drow("pool_id") %>" />
		<fieldset>
			<legend>Games</legend>
			<%
			
				dim games_ds as new dataset()
				try
					games_ds = fb.GetPoolGames(pool_id:=pool_id, pool_owner:=myname)
				catch
				end try

				if games_ds.tables.count > 0 then
					if games_ds.tables(0).rows.count > 0 then
						%><li><label for="game_select">Games </label> <select  onChange="handlegameselect()" name="game_select" id="game_select"><option value="">Select Game</option><%
						
						if teams_ds.tables.count > 0 then
							if teams_ds.tables(0).rows.count > 0 then
								for each drow as datarow in games_ds.tables(0).rows
									%><option value="<% = drow("game_id") %>">W:<% = drow("week_id") %> <% = drow("away_team_name") %> at <% = drow("home_team_name") %> on <% = drow("game_tsp") %></option><%
								next
							end if
						end if
						%></select> <input type="submit" name="submit" value="Delete Game"></li><%
					else
						%><ol><li><label >No games found.</label></li></ol><%
					end if
				else
					%><ol><li><label >No games found.</label></li></ol><%
				end if
			%>
			
			<ol>
				<li><label ><b>Game Details</b></label></li>
				<li><label for="away_id_select">Away Team <em>*</em></label> <select name="away_id_select" id="away_id_select"><%								if teams_ds.tables.count > 0 then
							if teams_ds.tables(0).rows.count > 0 then
								for each drow as datarow in teams_ds.tables(0).rows
									%><option value="<% = drow("team_id") %>"><% = drow("team_name") %></option><%
								next
							end if
						end if
						%></select></li>
				<li><label for="home_id_select">Home Team <em>*</em></label> <select name="home_id_select" id="home_id_select"><%								if teams_ds.tables.count > 0 then
							if teams_ds.tables(0).rows.count > 0 then
								for each drow as datarow in teams_ds.tables(0).rows
									%><option value="<% = drow("team_id") %>"><% = drow("team_name") %></option><%
								next
							end if
						end if
						%></select></li>
				<li><label for="game_time">Game Time <em>*</em></label> <input type="text" name="game_time" id="game_time" value = "" /> MM/DD/YYYY HH:MM</li>
				<li><label for="week_id">Week <em>*</em></label> <input type="text" name="week_id" id="week_id" value = "" /></li>
				<li><label for="game_url">Game Link </label> <input type="text" name="game_url" id="game_url" value = "" /></li>
			</ol>
			<input type="submit" name="submit" value="Add Game" /> <input type="submit" name="submit" value="Update Game"><br />

			<br />
			Games:<br />
			<textarea name="games_text" id="games_text" rows="5" cols="80"></textarea><br />
			<input type="submit" name="submit" value="Add Games" /> <input type="button" value="Example Text" onClick="addexampletext();" /> <br />

			Import Games<br />
			<select name="import_game_select" size=5 multiple>
			<%
				for each drow as datarow in importgames_ds.tables(0).rows
					%><option value="<% = drow("game_id") %>"><% = drow("away_team") %> at <% = drow("home_team") %> <% = drow("game_tsp") %></option><%
				next
			%>
			</select>
			<input type="submit" name="submit" value="Import Game" /><br />
		</fieldset>

		
		<a name="tiebreakers"></a>
		<fieldset>
			<legend>Tie Breakers</legend>
			<ol>
				<li><label for="tb_weekid_select">Week <em>*</em></label> <select name="tb_weekid_select" id="tb_weekid_select" onChange="handletbselect()" ><option value="">Select Week</option><%
					try
						dim weeks_ds as dataset
						weeks_ds = fb.listweeks(pool_id:=pool_id)
						if weeks_ds.tables.count > 0 then
							if weeks_ds.tables(0).rows.count > 0 then
								for each drow as datarow in weeks_ds.tables(0).rows
									%><option value="<% = drow("week_id") %>"><% = drow("week_id") %></option><%
								next
							end if
						end if
					catch ex as exception
						fb.makesystemlog("error listing weeks", ex.tostring())
					end try
				%></select></li>

				<li><label for="tb_game_select">Game <em>*</em></label> <select name="tb_game_select" id="tb_game_select"><option value="">Select Game</option></select></li>

			</ol>

			<input type="submit" name="submit" value="Set Tiebreaker Game" /><br />
			
		</fieldset>
		
		<a name="rssfeed"></a>
		<fieldset>
			<legend>RSS Feed</legend>
			<ol>
				<li><label for="rssfeed_select">Feed <em>*</em></label> <select name="rssfeed_select" id="rssfeed_select" ><option value="">Select a Feed</option><%
					try
						dim feeds_ds as dataset
						feeds_ds = fb.listfeeds()
						for each drow as datarow in feeds_ds.tables(0).rows
							if pool_ds.tables(0).rows(0)("feed_id") is dbnull.value then
								%><option value="<% = drow("feed_id") %>"><% = drow("feed_title") %></option><%
							else
								if pool_ds.tables(0).rows(0)("feed_id") = drow("feed_id") then
									%><option value="<% = drow("feed_id") %>" SELECTED><% = drow("feed_title") %></option><%
								else
									%><option value="<% = drow("feed_id") %>"><% = drow("feed_title") %></option><%
								end if
							end if
						next
					catch ex as exception
						fb.makesystemlog("error listing feeds in adminpool.aspx", ex.tostring())
					end try
				%></select></li>
			</ol>

			<input type="submit" name="submit" value="Set Feed" /><br />
			
		</fieldset>

		
	<a name="options"></a>
		<fieldset>
			<legend>Pool Options</legend>
			<TABLE id="optiontable">
			<TR>
				<TD class="optionlabel">Lone Wolfe Picks:</TD>
				<%
				dim optionchecked as string = ""

				if options_ht("LONEWOLFEPICK") = "on" then
					optionchecked = "CHECKED"
				else
					optionchecked = ""
				end if
				%>
				<TD><input type="checkbox" name="optLonewolfepick" <% = optionchecked %>></TD>
			</TR>
			<TR>
				<TD class="optionlabel">Extra Point for Winning Week:</TD>
				<%
				if options_ht("WINWEEKPOINT") = "on" then
					optionchecked = "CHECKED"
				else
					optionchecked = ""
				end if
				%>
				<TD><input type="checkbox" name="optWinWeekPoint"  <% = optionchecked %> ></TD>
			</TR>
			<TR>
				<TD class="optionlabel">Hide NP Rows:</TD>
				<%
				if options_ht("HIDENPROWS") = "on" then
					optionchecked = "CHECKED"
				else
					optionchecked = ""
				end if
				%>
				<TD><input type="checkbox" name="optHideNPRows"  <% = optionchecked %> ></TD>
			</TR>
			<TR>
				<TD class="optionlabel">Show Team Records in Make Picks:</TD>
				<%
				if options_ht("TEAMRECORDS") = "on" then
					optionchecked = "CHECKED"
				else
					optionchecked = ""
				end if
				%>
				<TD><input type="checkbox" name="optTeamRecords"  <% = optionchecked %> ></TD>
			</TR>
			<TR>
				<TD class="optionlabel">Auto Home Picks:</TD>
				<%
				if options_ht("AUTOHOMEPICKS") = "on" then
					optionchecked = "CHECKED"
				else
					optionchecked = ""
				end if
				%>
				<TD><input type="checkbox" name="optAUTOHOMEPICKS"  <% = optionchecked %> ></TD>
			</TR>
			<TR>
				<TD class="optionlabel">Hide Standings:<br /><span class="smallprint">Standings are hidden from non-pool members.</span></TD>
				<%
				if options_ht("HIDESTANDINGS") = "on" then
					optionchecked = "CHECKED"
				else
					optionchecked = ""
				end if
				%>
				<TD><input type="checkbox" name="optHIDESTANDINGS"  <% = optionchecked %> ></TD>
			</TR>
			<TR>
				<TD class="optionlabel">Hide Comments:<br /><span class="smallprint">Comments are hidden from non-pool members.</span></TD>
				<%
				if options_ht("HIDECOMMENTS") = "on" then
					optionchecked = "CHECKED"
				else
					optionchecked = ""
				end if
				%>
				<TD><input type="checkbox" name="optHIDECOMMENTS"  <% = optionchecked %> ></TD>
			</TR>
			</TABLE>
			<input type="submit" name="submit" value="Update Pool Options" /><br />
			
		</fieldset>
	</form>
</div>

<div id="Menu">
<% 
Server.Execute("nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
