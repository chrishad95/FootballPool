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


	if request("id") <> "" then
		fb.DeleteMessage(request("id"), myname)
	else
		session("error_message") = "Invalid message id."
	end if
%>
<script>window.document.location.replace("/football/messages")</script>
