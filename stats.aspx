<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<script runat="server" language="VB">
	private myname as string = ""
</script>
<%

server.execute("/football/cookiecheck.aspx")
dim fb as new Rasputin.FootballUtility()
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
	session("page_message") = "Invalid pool/player."
	response.redirect("/football/error.aspx", true)
end if

dim player as string = myname 
try
	if request("player") <> "" then
		player = request("player")
	end if
catch
end try

dim weekly_stats as new dataset()
weekly_stats = fb.GetWeeklyStats(pool_id:=pool_id)

dim pool_details_ds as new dataset()
pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

dim banner_image as string = ""
if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
	banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" &  pool_details_ds.tables(0).rows(0)("pool_banner")
end if

dim pool_name as string = ""
pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

dim options_ht as new system.collections.hashtable()
options_ht = fb.getPoolOptions(pool_id:=pool_id)

%>

<html>
<head>
	<title>Statistics - <% = pool_name %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	<style type="text/css">
		.content {
			border: none;
			padding: 1px;
			margin:0px 0px 20px 170px;
		}
		.week_column {
			width: 100px;
		}
		.graph_title {
			font-size: 11px;
			font-weight: bold;
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
			<h2>Statistics for <% = pool_name %></h2><%

			dim nick as string = player
			dim temprows as datarow()
			temprows = weekly_stats.tables(0).select("username='" & player & "'")
			if temprows.length > 0 then
				if not temprows(0)("nickname") is dbnull.value then
					nick = temprows(0)("nickname")
				end if
			end if
		%>
		<table border="0">
		<tr><td align="center" valign="bottom">
		<img src="/football/useless.aspx?pool_id=<% = pool_id %>&player=<% = player %>&graph=win_pct"><br />
		<span class="graph_title">Weekly Win Percentages for <% = nick %></span>
		</td>
		<td align="center" valign="bottom">
		<img src="/football/useless.aspx?pool_id=<% = pool_id %>&player=<% = player %>&graph=win_vs_avg_vs_high"><br />
		<span class="graph_title">
		Weekly Scores for <% = nick %><br />
		Wins (black) vs Average (blue) vs High (red)
		</span>
		</td>
		</tr>
		</table>

	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>

<!-- BlueRobot was here. -->
</body>
</html>
