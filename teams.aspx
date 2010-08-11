<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.Linq" %>
<%
server.execute("/football/cookiecheck.aspx")
dim fb as new Rasputin.FootballUtility()
dim myname as string = ""
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
	fb.makesystemlog("error in makepicks.aspx", ex.tostring())
end try

if fb.isnotowner(pool_id:=pool_id, pool_owner:=myname) then
	session("page_message") = "Invalid pool/pool owner."
	response.redirect("default.aspx", true)
end if

dim pool_details_ds as new dataset()
pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

dim banner_image as string = fb.getbannerimage(pool_id)

dim pool_name as string = ""
pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

dim options_ht as new system.collections.hashtable()
options_ht = fb.getPoolOptions(pool_id:=pool_id)

dim teams_ds as new dataset()
teams_ds = fb.getpoolteams(myname, pool_id)

%>

<html>
<head>
	<title><% = http_host %> | Teams</title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	<style type="text/css">
	.winner {
		background-color: #00FF00;
		text-align: center;
		
	}
	.home_pick_cell {
		background-color: Lavender;
	}
	.away_pick_cell {
		background-color: MistyRose;
	}
	.home_pick_cell {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.home_pick_cell a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.away_pick_cell {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.away_pick_cell a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.pick_cell {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.pick_cell a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.loser {
	text-decoration: line-through;
		text-align: center;
	}
	.loser a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.winner a{
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.score_cell {
		text-align: right;
	}
	.table_header {
		background-color: #C0C0C0;
	}
	td {
	font:11px verdana, arial, helvetica, sans-serif;
	}
	
	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
	</style>
	<style>
		table {
			text-align: left;
			font-size: 12px;
			font-family: verdana;
			background: #c0c0c0;
		}
 
		table thead tr,
		table tfoot tr {
			background: #c0c0c0;
		}
 
		table tbody tr {
			background: #f0f0f0;
		}
 
		td, th {
			border: 1px solid white;
		}
	</style>
	<script type="text/javascript" src="js/webtoolkit.scrollabletable.js"></script>
	<script type="text/javascript" src="js/jquery.js"></script>
	<script type="text/javascript" src="js/webtoolkit.jscrollable.js"></script>
	<script type="text/javascript">
		jQuery(document).ready(function() {
			jQuery('table').Scrollable(400, 800);
		});
 	</script>
 
</head>

<body>

	<div class="content">
	<%
	if banner_image = "" then
		%><h1><% = pool_name %></h1><%
	else
		%><img src="<% = banner_image %>" border="0"><BR><BR><%
	end if
	try
		if session("page_message") <> "" then
			%>
			<div class="message">
			<% = session("page_message") %><br />
			</div>
			<%
			session("page_message") = ""
		end if
	catch
	end try
	try
		if session("error_message") <> "" then
			%>
			<div class="error_message">
			<% = session("error_message") %><br />
			</div>
			<%
			session("error_message") = ""
		end if
	catch
	end try

	%>
	<table cellspacing="1">
	<thead>
		<tr>
			<td>Team Name</td>
			<td>Team Short Name</td>
			<td>&nbsp;</td>
		</tr>
	</thead>
	<tbody>
	<%
	for each drow as datarow in teams_ds.tables(0).rows
		%>
		<tr>
			<td><% = drow("team_name") %></td>
			<td><% = drow("team_shortname") %></td>
			<td><a href="#">Delete</a></td>
		</tr>
		<%
	next
	%>
	</tbody>
	</table>


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

	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>

<!-- BlueRobot was here. -->

</body>
</html>
