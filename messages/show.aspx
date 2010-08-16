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
	dim id as integer = -1
	dim msg as new Hashtable()
	if request("id") <> "" then 
		msg = fb.GetMessage(request("id"))
		if not msg("to_user") = myname and not msg("from_user") = myname then
			response.redirect("default.aspx", true)
		end if
	end if

%>
<html>
<head>
<title><% = http_host %> | Messages</title>
<style type="text/css" media="all">@import "/football/css/cssplay4.css";</style>
<style>
	#sender {
		background-color: lightgray;
		font-weight: bold;
		font-size: 1.5em;
		padding: 4px;
	}
	
	#subject {
		background-color: navy;
		color: white;
		font-weight: bold;
		font-size: 1.8em;
		padding: 3px;
	}
	#message_body {
		font-size: 1.2em;
		padding: 5px;
	}

	#links { float: right; }
	#links a {color: white; text-decoration: none;}

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
	<div id="subject">
	<% = msg("subject") %>
	<div id="links">
	<a href="new.aspx?id=<% = msg("id") %>">Reply</a>
	</div>
	</div>
	<div id="sender">
	On <% = msg("created_at") %>, <% = msg("from_user") %> said:
	</div>
	<div id="message_body">
	<% = msg("body") %>
	</div>
</div>

<div id="left">
<% 
server.execute("/football/nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
