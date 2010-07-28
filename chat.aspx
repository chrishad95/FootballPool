<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
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

	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
%>
<html>
<head>
	<title>Chat - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style2.css";</style>
	
</head>

<body>


	<div id="Header">
		<a href="/"><% = http_host %></a>
	</div>

	<div id="Content">

		<% 
		dim chat_username as string = ""
		if myname = "" then
			if application("guest_chat_user_count") = "" then
				application("guest_chat_user_count") = 0
			end if
			application("guest_chat_user_count") = application("guest_chat_user_count")  + 1
			
			chat_username = "Guest" & application("guest_chat_user_count")
		else
			chat_username = myname
		end if
		%>
		<applet code=tcchat width=550 height=300>
			<PARAM name="host"  value="<% = http_host %>">
			<PARAM name="port"  value="8900">
			<PARAM name="name"  value="<% = chat_username %>">
		</applet>

	</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
