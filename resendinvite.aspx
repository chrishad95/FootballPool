<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.ODBC" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
	private myname as string = ""

	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub
</script>
<%
server.execute("/cookiecheck.aspx")

dim fb as new Rasputin.FootballUtility()

dim message_text as string = ""

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
	fb.makesystemlog("error in showsched", ex.tostring())
end try

dim email as string = ""
try
	email = request("email")
catch ex as exception
end try

if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
else	
	callerror("Invalid pool_id")
end if

dim res as string = ""
try
	res = fb.resendinvite(pool_id:=pool_id, email:=email)
catch
end try

if res <> email then
	message_text = "Failed to resend invitation. <br />" & res
else
	message_text = "Invitation was resent."
end if

%>

<html>
<head>
	<title>Resend Invitation Email - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/style2.css";</style>
</head>

<body>


	<div id="Header">
		<a href="/"><% = http_host %></a>
	</div>

	<div id="Content">
		<% = message_text %>
	</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>



<!-- BlueRobot was here. -->

</body>
</html>
