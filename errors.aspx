<%@ Page language="VB" debug="true" src="/football/football.vb" %>
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

	dim errors as new datatable()
	errors = fb.geterrors()

%>
<html>
<head>
<title>Error Log</title>
<style type="text/css" media="all">@import "/football/style4.css";</style>
<style type="text/css" media="all">@import "like-adw.css";</style>
<style>

	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
</style>

</head>

<body>

<div class="content">
	<% for each drow as datarow in errors.rows %>
	<fieldset>
	<legend><% = drow("entry_title") %></legend>
	<% = drow("entry_text").replace(system.environment.newline,"<br>" & system.environment.newline) %>
	</fieldset>
	<% next %>

	<br />
</div>

<div id="NavAlpha">
<% 
server.execute("nav.aspx")
%>
<br />
</div>
<!-- BlueRobot was here. -->
</body>

</html>
