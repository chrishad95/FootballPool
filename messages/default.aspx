<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Collections" %>
<script runat="server" language="VB">
	private myname as string = ""
</script>
<%
	server.execute ("/football/cookiecheck.aspx")
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
	
	if myname = "" then
		dim returnurl as string = "/football/messages"
		response.redirect(System.Configuration.ConfigurationSettings.AppSettings("login") & "?returnurl=" & returnurl, true)
	end if
	dim mymessages as new ArrayList()
	mymessages = fb.GetMessagesFor(myname)

%>
<html>
<head>
<title><% = http_host %> | Messages</title>
<style type="text/css" media="all">@import "/football/css/cssplay4.css";</style>
<style>
/*
Theme: Dark Night
Author: Michael Schmieding
Web site: http://www.slifer.de/
*/

table a, table, tbody, tfoot, tr, th, td, table caption {
	font-family: Verdana, arial, helvetica, sans-serif;
	background:#262b38;
	color:#fff;
	text-align:left;
	font-size:12px;
}
table, table caption {
	border-left:3px solid #567;
	border-right:3px solid #000;
}
table {
	border-top:1px solid #567;
	border-bottom:3px solid #000;
}
table a {
	text-decoration:underline;
	font-weight:bold;
}
table a:visited {
	background:#262b38;
	color:#abc;
}
table a:hover {
	text-decoration:none;
	position:relative;
	top:1px;
	left:1px;
}
table caption {
	border-top:3px solid #567;
	border-bottom:1px solid #000;
	font-size:20px;
	font-weight:bold;
}
table, td, th {
	margin:0px;
	padding:0px;
}
tbody td, tbody th, tbody tr.odd th, tbody tr.odd td {
	border:1px solid;
	border-color:#567 #000 #000 #567;
}
td, th, table caption {
	padding:5px;
	vertical-align:middle;
}
tfoot td, tfoot th, thead th {
	border:1px solid;
	border-color:#000 #567 #567 #000;
	font-weight:bold;
	white-space:nowrap;
	font-size:14px;
}
table {
	width: 700px;
}
</style>
</head>

<body>

<div id="head">
</div>
<div id="foot">
</div>
<div id="content">
	<%
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
			<td><a href="?sort_by=from_user">From</a></td>
			<td><a href="?sort_by=subject">Subject</a></td>
			<td align="right"><a href="new.aspx">New</a></td>
		</tr>
	</thead>
	<tbody>
	<%
	for each msg as Hashtable in mymessages
		%>
		<tr>
			<td><% = msg("from_user") %></td>
			<td><a href="show.aspx?id=<% = msg("id") %>"><% = msg("subject") %></a></td>
			<td><a href="delete.aspx?id=<% = msg("id") %>">Delete</a></td>
		</tr>
		<%
	next
	if mymessages.count = 0 then
		%>
		<tr>
			<td colspan=3>No messages found.</td>
		</tr>
		<%
	end if
	%>
	</tbody>
	</table>
</div>

<div id="left">
<% 
server.execute("/football/nav.aspx")
%>
</div>
</body>
</html>
