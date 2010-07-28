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

try
	myname = session("username")
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
catch ex as exception
	fb.makesystemlog("error in showsched", ex.tostring())
end try
dim isowner as boolean = false
isowner = fb.isowner(pool_id:=pool_id, pool_owner:=myname)

dim message as string = ""
try
	message = request("message")
catch
end try

dim week_id as integer = 0
try
	week_id = request("week_id")
catch ex as exception
end try

dim players_ds as dataset
players_ds = fb.getPoolPlayers(pool_id:=pool_id)

dim submit as string
try
	submit = request("submit")
catch
end try
if submit = "Send Notice" then
	dim players as string = request("username")
	for each p as string in players.split(",")
		fb.sendnotice(pool_id:=pool_id, week_id:=week_id, player_id:=p, message:=message)
	next
end if
%>

<html>
<head>
	<title>Send Notice - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style2.css";</style>
</head>

<body>


	<div id="Header">
		<a href="/"><% = http_host %></a>
	</div>

	<div id="Content">
		
		<form >
		<input type="hidden" name="pool_id" value="<% = pool_id %>">
		<table>
		<tr><td width="150">Week&nbsp;#</td><td  width="100%" align="left"><SELECT NAME="week_id">
		<%
			try
				dim weeks_ds as dataset
				weeks_ds = fb.listweeks(pool_id:=pool_id)
				if weeks_ds.tables.count > 0 then
					if weeks_ds.tables(0).rows.count > 0 then
						for each drow as datarow in weeks_ds.tables(0).rows
							dim selected as string = ""
							if week_id = drow("week_id") then
								selected = " SELECTED "
							else
								selected = ""
							end if
							%><option value="<% = drow("week_id") %>" <% = selected %>><% = drow("week_id") %></option><%
						next
					end if
				end if
			catch ex as exception
				fb.makesystemlog("error listing weeks", ex.tostring())
			end try
		%>
		</SELECT></td></tr>
		<tr><td width="150">Player:</td><td width="100%" align="left"><select name="username" multiple >
			<%		
			for each drow as datarow in players_ds.tables(0).rows
				dim player_name as string = ""
				if drow("nickname") is dbnull.value then
					player_name = drow("username")
				else
					if drow("nickname").trim() <> "" then
						player_name = drow("nickname")
					else
						player_name = drow("username")
					end if
				end if
				%>
				<option value="<% = drow("player_id") %>"><% = player_name %></option>
				<%
				
			next		
			%>
		</select></td></tr>
		<tr><td colspan="2">Message:<br /><textarea name="message" rows="5" cols="60"></textarea></td></tr>
		<tr><td colspan="2"><input type="submit" name="submit" value="Send Notice"></td></tr>
		</table>
		</form>
		
		<br/>
		<br/>
		<br />
		
	</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>



<!-- BlueRobot was here. -->

</body>
</html>
