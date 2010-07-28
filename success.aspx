<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.ODBC" %>
<%
server.execute("/cookiecheck.aspx")

dim myname as string
myname = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
%>
<html>
<head>
	<title>Success - rasputin.dnsalias.com - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/style2.css";</style>
	
</head>

<body>


	<div id="Header">
		<a href="/">rasputin.dnsalias.com</a>
	</div>

	<div id="Content">

		<%
		response.write (session("page_message"))
		session("page_message") = ""
		%>

	</div>

<div id="Menu">
<% server.execute ("/nav.aspx") %>
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
<%

%>
