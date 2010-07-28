<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%
server.execute("/football/cookiecheck.aspx")

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
	<title>Donate - <% = http_host %></title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	
</head>

<body>


	<div class="content">
		<h1><% = http_host %></h1>
	<h2>Donate to <% = http_host %></h2>
	If you enjoy this website and you would like to make a donation to support it, please use the button below.  Donate any amount that you wish.  All donations are appreciated.
	<br />
	<br/>
	To make your donation with PayPal, credit card, or e-check, please click the button below:
	<br />
	<br />
	<form action="https://www.paypal.com/cgi-bin/webscr" method="post">
	<input type="hidden" name="cmd" value="_s-xclick">
	<input type="image" src="https://www.paypal.com/en_US/i/btn/x-click-but21.gif" border="0" name="submit" alt="Make payments with PayPal - it's fast, free and secure!">
	<img alt="" border="0" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1">
	<input type="hidden" name="encrypted" value="-----BEGIN PKCS7-----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-----END PKCS7-----
	">
	</form>
	</div>

<div id="navAlpha">
<% server.execute ("/football/nav.aspx") %>
</div>

<div id="navBeta">
<% 	server.execute ("/quotes/getrandomquote.aspx") %>
</div>

<!-- BlueRobot was here. -->

</body>
</html>
