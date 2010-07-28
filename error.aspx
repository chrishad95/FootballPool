<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%
server.execute("/cookiecheck.aspx")

	dim myname as string = ""
	server.execute ("/cookiecheck.aspx")
	try
		myname = session("username")
	catch
	end try
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
%>
<html>
<head>
	<title>Error - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style2.css";</style>
	
</head>

<body>


	<div id="Header">
		<a href="/"><% = http_host %></a>
	</div>

	<div id="Content">

		<%
		response.write (session("page_message"))
		session("page_message") = ""
		%>

	</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
<%

%>
