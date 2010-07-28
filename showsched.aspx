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

	server.execute ("/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
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

	if fb.isplayer(pool_id:=pool_id, player_name:=myname) or fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
	else	
		callerror("Invalid pool_id")
	end if

	dim sched_ds as new dataset()
	sched_ds = fb.GetSchedule(pool_id:=pool_id)

	dim pool_details_ds as new dataset()
	pool_details_ds = fb.getpooldetails(pool_id:= pool_id)


	dim banner_image as string = ""
	if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
		banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" &  pool_details_ds.tables(0).rows(0)("pool_banner")
	end if

	dim pool_name as string = ""
	pool_name = pool_details_ds.tables(0).rows(0)("pool_name")


	dim weeks_ds as new dataset()
	weeks_ds = fb.listweeks(pool_id:=pool_id)
%>
<html>
<head>
<title>Schedule</title>
<style type="text/css" media="all">@import "/football/style4.css";</football/style>
<style type="text/css" media="all">@import "like-adw.css";</football/style>
<style>

	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
</football/style>

</head>

<body>

<div class="content">
	<%
		if banner_image = "" then
			%><h1><% = pool_name %></h1><%
		else
			%><img src="<% = banner_image %>" border="0"><BR><BR><%
		end if
	
	%>Jump to Week# <%

	for each week_drow as datarow in weeks_ds.tables(0).rows
		%><a href="#week_<% = week_drow("week_id")  %>"><% = week_drow("week_id")  %></a> <%
	next
	
	%><br /><%

	dim gotgames as boolean = false
	if sched_ds.tables.count > 0 then
		if sched_ds.tables(0).rows.count > 0 then
			gotgames = true
			for each week_drow as datarow in weeks_ds.tables(0).rows
				dim temprows as datarow()
				temprows = sched_ds.tables(0).select("week_id=" & week_drow("week_id"))

				%>
				<br />
				<a name="week_<% = week_drow("week_id") %>">
				<table>			
				<caption>Week # <% = week_drow("week_id") %></caption>
				<thead>
					<tr>
						<th scope="col">Away Team</th>
						<th scope="col">Home Team</th>
						<th scope="col">Game Time</th>
						<%
						if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
							%><th scope="col">Actions</th><%
						end if
						%>
					</tr>
				</thead>	
				<tfoot>
					<tr>
						<th scope="row">Total</th>
						<%
						if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
							%><td colspan="4"><% = temprows.length %> games.</td><%
						else
							%><td colspan="3"><% = temprows.length %> games.</td><%
						end if
						%>
					</tr>
				</tfoot>	
				<tbody>
				<%
				dim months as string() = {"blan", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
				dim daysoftheweek as string() = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

				for each drow as datarow in temprows
					dim gt as datetime = drow("game_tsp")
					dim gametime as string
					gametime = daysoftheweek(gt.dayofweek)
					gametime = gametime & " " 
					gametime = gametime & months(gt.month)
					gametime = gametime & " " 
					gametime = gametime & gt.day 
					gametime = gametime & " " 
					
					dim ampm as string = "AM"

					if gt.hour > 12 then
						gametime = gametime & gt.hour mod 12
						ampm = "PM"
					end if

					if gt.minute > 0 then
						dim m as string = gt.minute
						m = m.padleft(2,"0")

						gametime = gametime & ":" & m
					end if

					gametime = gametime & ampm
	

					%><tr>
					<td><% = drow("away_team_name") %></td>
					<td><% = drow("home_team_name") %></td>
					<td><% = gametime %></td>
					<%
					if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
						%><td><a href="deletegame.aspx?game_id=<% = drow("game_id") %>">Delete</a></td><%
					end if
					%>
					</tr><%
				next
				%></tbody></table><%
			next
		end if
	end if
	if not gotgames then
		response.write("No games found.<br />")
	end if
	%>
</div>

<div id="NavAlpha">
<% 
server.execute("nav.aspx")
%>
<br />
<script type="text/javascript"><!--
google_ad_client = "pub-8829998647639174";
google_ad_width = 120;
google_ad_height = 600;
google_ad_format = "120x600_as";
google_ad_type = "text_image";
google_ad_channel = "";
google_color_border = "FFFFFF";
google_color_bg = "EEEEEE";
google_color_link = "0000FF";
google_color_text = "000000";
google_color_url = "008000";
//-->
</script>
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
