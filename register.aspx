<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.ODBC" %>
<%@ Import Namespace="System.Web.Mail" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server" language="VB">
	
	
</script>
<%

	dim fb as new Rasputin.FootballUtility()
	server.execute ("/cookiecheck.aspx")
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try

	Dim username as String = ""
	Dim password as String = ""
	Dim password2 as String = ""
	Dim email as String = ""

	try 
		username = request("username")
	catch
	End try
	try
		password = request("password")
	catch
	End try
	try
		password2 = request("password2")
	catch
	End try
	try
		email = request("email")
	catch
	End try

	dim submit as string = ""
	try
		submit = request("submit")
	catch 
	end try
	if submit = "Register" then

		if username = "" or password = "" or password2 = "" or email = "" then
			session("page_message") = "Incorrect form data.  Please use your BACK button and try again."
			response.redirect("error.aspx",true)
		end if
		
		if password <> password2 then
			session("page_message") = "Incorrect form data.  Passwords do not match. Please use your BACK button and try again."		
			response.redirect("error.aspx",true)
		end If
		
		if password.length < 6  then
			session("page_message") = "Invalid form data.  Password length must be at least 6.  Use the BACK button and try again."
			response.redirect("error.aspx",true)
		end if
				
		if not fb.validusername(username) then
			session("page_message") = "Invalid form data.  Invalid characters in username.  Use the BACK button and try again."
			response.redirect("error.aspx",true)
		end If

		dim res as string = ""
		res = fb.registeruser(username:=username, email:=email, password:=password)
		if res <> email then
			session("page_message") = res
			response.redirect("error.aspx", true)
		else
			dim remote_addr as string = ""
			try
				remote_addr = request.servervariables("REMOTE_ADDR")
			catch
			end try
			dim qs as string = ""
			try
				qs = request.servervariables("QUERY_STRING")
			catch
			end try
			dim http_referer as string = ""
			try
				http_referer = request.servervariables("HTTP_REFERER")
			catch
			end try


			dim sb as new system.text.stringbuilder()
			sb.append("Username: " & username & system.environment.newline)
			sb.append("Email: " & email & system.environment.newline)
			sb.append("IP Address: " & remote_addr & system.environment.newline)
			sb.append("Http Host: " & http_host & system.environment.newline)
			sb.append("System Time: " & system.datetime.now & system.environment.newline)

			fb.makesystemlog("A new user has registered", sb.tostring())
		end if

	end if
%>
<html>
<head>
<title>Register</title>
<style type="text/css" media="all">@import "/style2.css";</style>
</head>

<body>

<div id="Header"><% = http_host %></div>

<div id="Content">
<form>
  <h2>Create a Username (register)</h2>
  <table>
  <tr><td>Username:</td><td><input type="text" name="username" id="username" /></td></tr>
  <tr><td>Password:</td><td><input type="password" name="password" id="password" /></td></tr>
  <tr><td>Confirm Password:</td><td><input type="password" name="password2" id="password2" /></td></tr>
  <tr><td>Email:</td><td><input type="text" name="email" id="email" /></td></tr>
  <tr><td colspan=2><input type="submit" name="submit" value="Register" /></td></tr>
  </table>
</form>
After submitting this form successfully, you will receive an email with a validation key.  You must validate this email address before you can use your account.

</div>

<div id="Menu">
<% 
Server.Execute("nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>

