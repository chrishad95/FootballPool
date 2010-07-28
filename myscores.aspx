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
dim message_text as string = ""

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

dim isplayer as boolean = false
isplayer = fb.isplayer(pool_id:=pool_id, player_name:=myname)

if isplayer then
else	
	callerror("Invalid pool_id/player_name")
end if

dim week_id as integer
try
	week_id = request("week_id")
catch 
end try


dim weeks_ds as new dataset()
weeks_ds = fb.listweeks(pool_id:=pool_id)

dim foundweek as boolean = false
try
	for each drow as datarow in weeks_ds.tables(0).rows
		if drow("week_id") = week_id then
			foundweek = true
		end if
	next
catch
end try

if not foundweek then
	response.redirect("showpicks.aspx?pool_id=" & pool_id, true)
end if

dim games_ds as new dataset()
games_ds = fb.GetGamesForWeek(pool_id:=pool_id, week_id:=week_id)

dim submit as string = ""
try
	submit = request("submit")
catch
end try
if submit = "Update Scores" then
	try
		for each drow as datarow in games_ds.tables(0).rows
			if request("away_score_" & drow("game_id")) <> "" and request("home_score_" & drow("game_id")) <> "" then

				session("pool_id=" & pool_id & ",week_id=" & week_id & ",game_id=" & drow("game_id") & ",away_score") = request("away_score_" & drow("game_id"))
				session("pool_id=" & pool_id & ",week_id=" & week_id & ",game_id=" & drow("game_id") & ",home_score") = request("home_score_" & drow("game_id"))
			end if
		next
	catch ex as exception
		fb.makesystemlog("Error in scoregames.aspx", ex.tostring())
	end try
end if

dim scores_ds as new dataset()
scores_ds = fb.getscoresforweek(pool_id:=pool_id, week_id:=week_id)
%>

<html>
<head>
	<title>Game Scores - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style2.css";</style>
</head>

<body>


	<div id="Header">
		<a href="/"><% = http_host %></a>
	</div>

	<div id="Content">
		
		<form>
		<input type="hidden" name="pool_id" value="<% = pool_id %>">
		<table>
		<tr><td colspan=3>Week # <select name="week_id" >
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
		
		
		<form>
		<input type="hidden" name="week_id" value="<% = week_id %>">
		<input type="hidden" name="pool_id" value="<% = pool_id %>">
		<%
		for each drow as datarow in games_ds.tables(0).rows
			dim away_score as string = ""
			dim home_score as string = ""
			dim temprows as datarow()
			temprows = scores_ds.tables(0).select("game_id=" & drow("game_id"))
			if temprows.length > 0 then
				if temprows(0)("away_score") is dbnull.value then
				else
					away_score = temprows(0)("away_score")
				end if

				if temprows(0)("home_score") is dbnull.value then
				else
					home_score = temprows(0)("home_score")
				end if
			else
				try
					if session("pool_id=" & pool_id & ",week_id=" & week_id & ",game_id=" & drow("game_id") & ",away_score") <> "" then
						away_score = session("pool_id=" & pool_id & ",week_id=" & week_id & ",game_id=" & drow("game_id") & ",away_score")
					end if
					if session("pool_id=" & pool_id & ",week_id=" & week_id & ",game_id=" & drow("game_id") & ",home_score") <> "" then
						home_score = session("pool_id=" & pool_id & ",week_id=" & week_id & ",game_id=" & drow("game_id") & ",home_score")
					end if
				catch ex as exception
				end try
			end if

			%>
			
			<table border="1" cellspacing="0" cellpadding="1">
			<tr><td>
				<table border="0" cellspacing="1" cellpadding="0">
				<tr><td width=200 nowrap bgcolor="#FFFFCC" ><% = drow("away_team") %></td><td width=20 ><input type="text" size=5 name="away_score_<% = drow("game_id") %>" value="<% = away_score %>"></td></tr>
				<tr><td width=200 nowrap bgcolor="#99CCCC"><% = drow("home_team") %></td><td width=20 ><input type="text" size=5 name="home_score_<% = drow("game_id") %>" value="<% = home_score %>"></td></tr>
				</table>
			</td></tr>
			</table>
			<br />
			<%
		next
		%>
		<input type="submit" name="submit" value="Update Scores">
		</form>
		
		<% = message_text %>
	</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>



<!-- BlueRobot was here. -->

</body>
</html>
