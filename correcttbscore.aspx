<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%
	server.execute("/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
	
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
	dim score as integer
	try
		score = request("score")
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
		session("page_message") = "Unauthorized to change tbscore."
		response.redirect("error.aspx", true)
	end if

	if player_name = "" then
		session("page_message") = "Invalid player name."
		response.redirect("error.aspx", true)
	end if

	dim message_text as string = ""

	if submit = "Correct Tiebreaker Score" then
		dim res as string
		res = fb.updatetiebreaker(pool_id:=pool_id, username:=player_name, score:=score, week_id:= week_id, mod_user:=myname)
		if res = player_name then
			message_text = "Tiebreaker was updated successfully."
		else
			message_text = "Tiebreaker was not updated."
		end if
	end if
	
	if submit = "Correct Tiebreaker, Show Picks" then
		dim res as string
		res = fb.updatetiebreaker(pool_id:=pool_id, username:=player_name, score:=score, week_id:= week_id, mod_user:=myname)
		if res = player_name then
			response.redirect("showpicks.aspx?pool_id=" & pool_id & "&week_id=" & week_id, true)
		else
			message_text = "Tiebreaker was not updated."
		end if
	end if

	dim oldscore as string = ""
	oldscore = fb.gettiebreakervalue(pool_id:=pool_id, week_id:=week_id, player_name:=player_name)

%>
<html>
<head>
	<title>Correct Tiebreaker Score - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style2.css";</football/style> 
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
	</football/style>
	
</head>

<body>


	<div id="Header">
		<a href="/"><% = http_host %></a>
	</div>

	<div id="Content">

		<form class="cmxform">
			<input type="hidden" name="player_name" value="<% = player_name %>">
			<input type="hidden" name="pool_id" value="<% = pool_id %>">
			<input type="hidden" name="week_id" value="<% = week_id %>">
			<fieldset>
				<legend>Correct Tiebreaker Score</legend>
				<TABLE border=0 cellspacing=1 cellpadding=2 bgcolor="#C0C0C0" >
				<TR>
					<TD>Player Name:</TD>
					<TD><% = player_name %></TD>
				</TR>
				<TR>
					<TD>Week:</TD>
					<TD><% = week_id %></TD>
				</TR>
				<TR>
					<TD>Score:</TD>
					<TD><input type="text" name="score" value="<% = oldscore %>" ></TD>
				</TR>
				</TABLE>
				<input type="submit" name="submit" value="Correct Tiebreaker Score" /> <input type="submit" name="submit" value="Correct Tiebreaker, Show Picks" />
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