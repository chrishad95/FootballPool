<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Web.Mail" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server" language="VB">


</script>
<%
	server.execute("/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
	dim submit as string
	try
		submit = request("submit")
	catch
	end try
	dim username as string = ""
	try
		username = request("username")
	catch
	end try
	dim message_text as string = ""

	if submit = "Reset Password" then
		if username <> "" then
			dim res as string
			res = fb.resetpassword(username)
			message_text = "Password reset successful.  You will receive an email with a new password."
		end if
	end if
%>
<html>
<head>
	<title>Reset Password - <% = http_host %></title>
	<style type="text/css" media="screen">@import "/football/style2.css";</style>
	
</head>

<body>
 <div id="Header"><% = http_host %></div>

 <div id="Content">
		<h2>Reset Password</h2>
		<form>
		<TABLE>
		<TR>
			<TD>Username or Email Address:</TD>
			<TD><input type="text" name="username" id="username" /></TD>
		</TR>
		<TR>
			<TD colspan=2><input type="submit" name="submit" value="Reset Password" /></TD>
		</TR>
		</TABLE>
		</form>
		<%
			if message_text <> "" then
				%><script>window.alert("<% = message_text %>")</script><%
			end if
		%>
	</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
