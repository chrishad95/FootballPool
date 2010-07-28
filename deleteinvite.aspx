<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
	private myname as string = ""

	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub
</script>
<%
server.execute("/football/cookiecheck.aspx")

dim fb as new Rasputin.FootballUtility()
fb.initialize()

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
	res = fb.deleteinvite(pool_id:=pool_id, email:=email)
catch
end try

if res <> "SUCCESS" then
	message_text = "Failed to delete invitation. <br />" & res
else
	message_text = "Invitation was deleted."
end if

%><script>window.document.location.replace("/football/adminpool.aspx?pool_id=<% = pool_id %>#invitations")</script>
