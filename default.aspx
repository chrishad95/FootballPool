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
	server.execute ("/football/cookiecheck.aspx")
	try
		myname = session("username")
	catch
	end try
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
	
	if myname = "" then
		dim returnurl as string = "/football"
		response.redirect("login.aspx?returnurl=" & returnurl, true)
	end if

	dim pool_id as integer 
	dim pool_id_found as boolean = false
	try
		if request("pool_id") <> "" then
			pool_id = request("pool_id")
			if fb.isowner(pool_id:=pool_id, pool_owner:=myname) or fb.isplayer(pool_id:=pool_id, player_name:=myname) then
				pool_id_found = true
			end if
		end if
	catch
	end try

	dim mypools as dataset
	mypools = fb.getmypools(player_name:=myname)
	if mypools.tables(0).rows.count = 1 and not pool_id_found then
		response.redirect("default.aspx?pool_id=" & mypools.tables(0).rows(0)("pool_id"), true)
	end if

%>
<html>
<head>
<title><% = http_host %></title>
<style type="text/css" media="all">@import "/football/style4.css";</style>
<style>

	caption {
		padding: 0.5em 0.6em 0.8em;
		font-size: 16px;
		font-weight: bold;
		text-align: left;
		color: #000;
		background: LightSteelBlue;
	}
	
	.table_subheader {
		font-size: 11px;
		font-weight: bold;
		background: Silver;
	}
	.table_header {
		font-size: 12px;
		font-weight: bold;
		background: Silver;
	}	
	.table_header td {
		font-size: 12px;
		font-weight: bold;
		background: Silver;
	}	
	.table_header a {
		color: #000000;
		font-size: 11px;
		font-weight: bold;
	}

	.RowLight {
		background: WhiteSmoke;
	}

	.RowDark {
		background: Gainsboro;
	}

	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
	table {
		font-size: 10px;
		font-weight: normal;
	}
	.score_cell {
		text-align: right;
	}

	#MyPoolsTable {
		border-collapse: collapse;
		border: 2px solid #3f7c5f;
		font: normal 80%/140% arial, verdana, helvetica, sans-serif;
		font-size: 14px;
		color: #000;
		background: #fff;
	}

	#MyPoolsTable caption {
		padding: 0 0.6em 0.8em;
		font-size: 18px;
		font-weight: bold;
		text-align: left;
		color: #000;
		background: transparent;
	}

	#MyPoolsTable td, th {
		border: 1px solid #e0e0e0;
		padding: 0.5em;
	}

	#MyPoolsTable thead th {
		border: 1px solid #e0e0e0;
		text-align: left;
		font-size: 14px;
		font-weight: bold;
		background: #c6d7cf;
	}
	
	tfoot th, tfoot td {
		border: 1px solid #e0e0e0;
		text-align: left;
		font-size: 14px;
		background: #e8e8cf;
	}
	tfoot th {
		font-weight: bold;
	}
	tbody td a {
		background: transparent;
		color: #00c;
		text-decoration: none;
	}
	tbody td a:hover {
		background: transparent;
		color: #00c;
		text-decoration: underline;
	}
	tbody th a {
		background: transparent;
		color: #3f7c5f;
		text-decoration: underline;
		font-weight: bold;
	}
	tbody th a:visited {
		color: #b98b00;
	}
	tbody th, tbody td {
		vertical-align: top;
		text-align: left;
	}
	tfoot td {
		border: 1px solid #996;
	}
		
	.actions_column {
		width: 150px;
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		background: #E1E4F2;
		text-align: left;
		border-width: 0px 1px 1px 0px;
		border-color: DarkGray;
		border-style: solid;
	}
	.actions_column a {
		display: block; 
		text-decoration: none;
		border: 1px solid gray;   
		border-color: rgb(90%,85%,80%) rgb(60%,55%,50%) rgb(60%,55%,50%) rgb(90%,85%,80%); 
		color: navy;
		background: rgb(92%,91%,90%) url(images/link-base.gif) 3px 50% no-repeat;
		padding: 2px 10px 1px 20px;
		margin: 0;
		font: bold 100% Arial, Verdana, sans-serif;
	}

	.actions_column a:hover {
		background: rgb(92%,91%,90%) url(images/link-hover.gif) 3px 50% no-repeat;
	}

	.pool_name {	
		background: #E1E4F2;
		border-width: 1px 1px 0px 1px;
		border-color: DarkGray;
		border-style: solid;

	}
	.pool_name a {
		color: #030303;
		font:16px verdana, arial, helvetica, sans-serif;
		font-weight: bold;
		text-decoration: none;
	}

	.pool_owner {
		background: #F5F5FF;
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		border-width: 0px 1px 1px 1px;
		border-color: DarkGray;
		border-style: solid;
	}
	.pool_desc {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		background: #E1E4F2;
		border-width: 0px 0px 1px 1px;
		border-color: DarkGray;
		border-style: solid;
		padding: 2px 2px 2px 2px;
	}



	#showthreads .tborder
	{
		background: #D1D1E1;
		color: #000000;
		border: 1px solid #0B198C;
	}
	
	#showthreads .thread_title {	
		background: #F5F5FF;
		color: #000000;
		width: 500px;
	}
	#showthreads .last_post {
		background: #E1E4F2;
		color:#333;
		font:10px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	#showthreads .title_text {
		color:#333;
		font:14px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	#showthreads .author_text {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	#showthreads .time_text {
		color:#333;
		font:10px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	#showthreads .poster_text {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	#showthreads .replies {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		background: #F5F5FF;
		text-align: right;
	}
	#showthreads .views {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		background: #E1E4F2;
		text-align: right;
	}
	
	#showthreads .thead
	{
		background: #5C7099 url(images/gradients/gradient_thead.gif) repeat-x top left;
		color: #FFFFFF;
		font: bold 14px tahoma, verdana, geneva, lucida, 'lucida grande', arial, helvetica, sans-serif;
	}
	#showthreads .thead a:link
	{
		color: #FFFFFF;
	}
	#showthreads .thead a:visited
	{
		color: #FFFFFF;
	}
	#showthreads .thead a:hover, .thead a:active
	{
		color: #FFFF00;
	}
	#showthreads .tfoot
	{
		background: #3E5C92;
		color: #E0E0F6;
	}
	#showthreads .tfoot a:link
	{
		color: #E0E0F6;
	}
	#showthreads .tfoot a:visited
	{
		color: #E0E0F6;
	}
	#showthreads .tfoot a:hover, .tfoot a:active
	{
		color: #FFFF66;
	}

</style>
</head>

<body>

<div class="content">
    <%
	if myname = "" then
		response.write("You are not logged in.<br />")
	else
		if mypools.tables.count > 0 then

			if not pool_id_found and mypools.tables(0).rows.count > 1  then
				%>
				<h1><% = http_host %></h1>
				<h2>My Pools</h2>
				<%
				dim temppoolrows as datarow()
				temppoolrows = mypools.tables(0).select("1=1", "pool_tsp desc")

				for each drow as datarow in temppoolrows
					dim pooldesc as string = ""
					if not drow("pool_desc") is dbnull.value then
						pooldesc = drow("pool_desc")
					end if

					%>
					<table class="pool_table" cellspacing="0">
					<tr><td colspan="2" class="pool_name"><a href="?pool_id=<% = drow("pool_id") %>"><% = drow("pool_name") %></a></td></tr>
					<tr><td colspan="2" class="pool_owner">Administrator: <% = drow("pool_owner") %></td></tr>
					<tr>
					<td class="pool_desc" ><% = fb.bbencode(pooldesc) %></td>
					<td class="actions_column"><a href="showsched.aspx?pool_id=<% = drow("pool_id") %>">Schedule</a>
					<a href="makepicks.aspx?pool_id=<% = drow("pool_id") %>">Make&nbsp;Picks</a>
					<a href="showpicks.aspx?pool_id=<% = drow("pool_id") %>">Show&nbsp;Picks</a>
					<a href="standings.aspx?pool_id=<% = drow("pool_id") %>">Standings</a>
					<a href="nickname.aspx?pool_id=<% = drow("pool_id") %>">Change&nbsp;Nickname</a>
					<a href="showthreads.aspx?pool_id=<% = drow("pool_id") %>">Trash&nbsp;Talk</a><%
					if fb.isowner(pool_id:=drow("pool_id"), pool_owner:=myname) then
						%>
						<br />
						<a href="adminpool.aspx?pool_id=<% = drow("pool_id") %>">Admin</a>
						<a href="scoregames.aspx?pool_id=<% = drow("pool_id") %>">Scores</a>
						<a href="sendnotice.aspx?pool_id=<% = drow("pool_id") %>">Send Notices</a>
						<%
					end if
					%>
					</td>
					</tr></table>
					<br />
					<%
				next
			elseif mypools.tables(0).rows.count = 1 or pool_id_found then

				if not pool_id_found then
					pool_id = mypools.tables(0).rows(0)("pool_id")
				end if
				
				dim pool_details_ds as new dataset()
				pool_details_ds = fb.getpooldetails(pool_id:= pool_id)


				
				dim banner_image as string = ""
				if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
					banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" &  pool_details_ds.tables(0).rows(0)("pool_banner")
				end if

				dim pool_name as string = ""
				pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

				dim standings_ds as new dataset()
				standings_ds = fb.getstandings(pool_id:=pool_id)


				dim sort_by as string = "TOTALSCORE"
				dim sort_dir as string = "DESC"

				try
					if request("sort_by") = "USERNAME" OR request("sort_by") = "HOME" OR request("sort_by") = "AWAY" OR request("sort_by") = "WINS" OR request("sort_by") = "LOSSES" OR request("sort_by") = "WEEKWINS"  OR request("sort_by") = "TOTALSCORE" OR request("sort_by") = "LWP" then
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

				dim options_ht as new system.collections.hashtable()
				options_ht = fb.getPoolOptions(pool_id:=pool_id)
				dim colspan as integer = 7

				if options_ht("LONEWOLFEPICK") = "on" then
						colspan = colspan + 1
				end if

				if options_ht("WINWEEKPOINT") = "on" then
						colspan = colspan + 1
				end if
				if banner_image = "" then
					%><h1><% = pool_name %></h1><%
				else
					%><img src="<% = banner_image %>" border="0"><BR><BR><%
				end if

				%>
				<table border=1 cellspacing=0 cellpadding=3>
				<tr><td class="table_header" colspan="<% = colspan %>"><table border="0"><tr><td class="table_header"><% = pool_name %> Standings (Top 5)</td><td style="text-align: right;"><a  href="standings.aspx?pool_id=<% = pool_id %>">View All Standings</a></td></tr></table></td></tr>
				<tr><%

						%><td class="table_subheader">Player</td><%
						%><td class="table_subheader">WINS</td><%
						%><td class="table_subheader">LOSSES</td><%
						%><td class="table_subheader">Win %</td><%
						%><td class="table_subheader">HOME</td><%
						%><td class="table_subheader">AWAY</td><%

					if options_ht("LONEWOLFEPICK") = "on" then
							%><td class="table_subheader">LWP</td><%
					end if

					if options_ht("WINWEEKPOINT") = "on" then
						%><td class="table_subheader">Week Wins</td><%
					end if

					%><td class="table_subheader">Total Score</td><%
				%>
				</tr>
				<% 
				dim player_rows as datarow()
				player_rows = standings_ds.tables(0).select(filterExpression:="1=1", sort:=sort_by & " " & sort_dir)

				dim rowtype as string = "RowDark"	
				dim maxrows as integer = 5
				if player_rows.length < 5 then
					maxrows = player_rows.length
				end if
				for i as integer = 0 to maxrows - 1
					dim pdrow as datarow = player_rows(i)

					if rowtype = "RowLight" then
						rowtype = "RowDark"
					else
						rowtype = "RowLight"
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
					Dim pcent as integer = 0
					try
						pcent = system.convert.toInt32 ( (pdrow("wins") / (pdrow("wins") + pdrow("losses"))) * 10000) / 100
					catch
					End try
					%><tr class="<% = rowtype %>"><td nowrap><% = pname %></td>
					<td class="score_cell"><% = pdrow("wins") %></td>
					<td class="score_cell"><% = pdrow("losses") %></td>
					<td class="score_cell"><% = pcent  %>%</td>
					<td class="score_cell"><% = pdrow("home") %></td>
					<td class="score_cell"><% = pdrow("away") %></td><%

					if options_ht("LONEWOLFEPICK") = "on" then
						%><td class="score_cell"><% = pdrow("lwp") %></td><%
					end if
					if options_ht("WINWEEKPOINT") = "on" then
						%><td class="score_cell"><% = pdrow("weekwins") %></td><%
					end if
					%>
					<td class="score_cell"><% = pdrow("totalscore") %></td>
					</tr><%
				next
				%>
				
				</table>

				<BR><BR>
				<div id="showthreads">
				<%


				dim threads_ds as new dataset()
				threads_ds = fb.ShowThreads(pool_id:=pool_id, count:=0)


				%>
				<div align="left">
				<a href="newcomment.aspx?pool_id=<% = pool_id %>" rel="nofollow"><img src="images/newthread.gif" alt="New Thread" border="0" /></a>
				</div>
				<br />

				<table class="tborder" border=0 cellspacing=1 cellpadding=2 width="100%">		
				<tr><td colspan="4" class="thead">Latest Discussions for <% = pool_name %></td><tr>
				<%
					dim threadsfound as integer = 0
					dim maxthreads as integer = 5
					try
						threadsfound = threads_ds.tables(0).rows.count
						if threads_ds.tables(0).rows.count > 0 then
							%>	
							<tr><td class="thead">Thread</td><td class="thead">Last Post</td><td class="thead">Replies</td><td class="thead">Views</td></tr>
							<%
							dim threadrows as datarow()
							threadrows = threads_ds.tables(0).select(filterExpression:="1=1", sort:="thread_tsp desc")

							if threadrows.length < 5 then
								maxthreads = threadrows.length
							end if
							for threadidx as integer = 0 to maxthreads -1
								dim threadrow as datarow = threadrows(threadidx)


								dim thread_title as string = threadrow("thread_title")
								dim thread_author as string = threadrow("thread_author")
								dim thread_tsp as datetime = threadrow("thread_tsp")
								dim last_poster as string = threadrow("last_poster")
								dim replies as integer = threadrow("replies")
								dim views as integer = threadrow("views")
								dim thread_id as integer = threadrow("thread_id")

								%>
								<tr><td class="thread_title"><span class="title_text"><a href="showthread.aspx?t=<% = thread_id %>&pool_id=<% = pool_id %>"><% = thread_title %></a></span><br /><span class="author_text"><% = thread_author %></span></td><td class="last_post"><span class="time_text"><% = thread_tsp.tostring().replace(" ", "&nbsp;") %></span><br />
								by&nbsp;<span class="poster_text"><% = last_poster %></span></td><td class="replies"><% = replies %></td><td class="views"><% = views %></td></tr>
								<%
							next
						end if
					catch ex as exception
						fb.makesystemlog("error in showthreads.aspx", ex.tostring())
					end try			
					%>				
					<tr><td colspan="4" class="tfoot" >Showing latest <% = maxthreads %> out of <% = threadsfound %> active threads.</td></tr>
					</table>
					
					
					</div>
					
					<BR><BR>

					<script type="text/javascript"><!--
					google_ad_client = "pub-8829998647639174";
					google_ad_width = 728;
					google_ad_height = 90;
					google_ad_format = "728x90_as";
					google_ad_type = "text_image";
					google_ad_channel = "";
					google_color_border = "6699CC";
					google_color_bg = "003366";
					google_color_link = "FFFFFF";
					google_color_text = "AECCEB";
					google_color_url = "AECCEB";
					//--></script>
					<script type="text/javascript"
					  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
					</script>
					<%


			else
				%><h1><% = http_host %></h1><%
				response.write("No pools found.<br />")
				response.write("If you think you should see something here, you may want to try accepting the invitation again.  Many people go through the registration and login progress and then forget to accept their pool invitation.<br />")

			end if
		end if
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
