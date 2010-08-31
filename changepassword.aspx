<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<script runat="server" language="VB">
	
</script>
<% 

dim myname as string = ""
try
	myname = session("username")
catch
end try

if myname = "" then
	session("page_message") = "You must login first, to change your password."
	response.redirect("/football/login.aspx",true)
end if

dim fb as new Rasputin.FootballUtility()
if request("submit") = "Change Password" then

	if request("password") = "" or request("newpassword") = "" or request("newpassword2") = "" then
		session("error_message") = "Incorrect username/password."
		response.redirect("/football/changepassword.aspx", true)
	end if
	if request("newpassword") <> request("newpassword2") then
		session("error_message") = "New password fields do not match."
		response.redirect("/football/changepassword.aspx", true)
	end if
	if request("newpassword").length < 6 then
		session("error_message") = "New Password must be at least 6 characters."
		response.redirect("/football/changepassword.aspx", true)
	end if
	dim res as boolean = false
	res = fb.changepassword(myname, request("password"), request("newpassword"))
	if res then
		session("page_message") = "You have successfully changed your password."
		response.redirect("/football/default.aspx", true)
	end if
end if
%>
<html>
<head>
<title>Change Password - </title>
<style type="text/css" media="all">@import "/football/style2.css";</style>
</head>

<body>
<div id="Header"></div>
<div id="Content">
<form method="POST">
  <h2>Change Password</h2>
  <table>
  <tr><td>Username:</td><td><% = myname %></td></tr>
  <tr><td>Password:</td><td><input name="password" type="password" /></td></tr>
  <tr><td>New Password:</td><td><input type="password" name="newpassword" /></td></tr>
  <tr><td>Confirm New Password:</td><td><input type="password" name="newpassword2" /></td></tr>
  <tr><td colspan=2><input type="submit" name="submit" value="Change Password" /></td></tr>
  </table>
</form>
</div>

<div id="Menu">
<% 
Server.Execute("/football/nav.aspx")
%>
</div>
</body>
</html>

