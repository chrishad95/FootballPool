<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Web.Mail" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<%

	dim fb as new Rasputin.FootballUtility()
	fb.initialize()
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try

	dim username as string = ""
	dim password as string = ""
	dim rememberlogin as string = ""
	dim returnurl as string = ""
	try
		username = request("username")
	catch
	end try

	try
		password = request("password")
		rememberlogin = request("rememberlogin")
		returnurl = request("returnurl")
	catch
	end try
	dim submit as string = ""
	try
		submit = request("submit")
	catch
	end try

	if submit = "Login" then
		if username = "" or password = ""  then
			session("page_message") = "Incorrect username/password.  Please use your BACK button and try again."		
			response.redirect("error.aspx",true)
		end if

		dim res as string = ""
		res = fb.login(username:=username, password:=password)

		if res.toupper() = username.toupper() then
			if rememberlogin = "on" then
				Dim MyCookie As New HttpCookie("username")
				Dim now As DateTime = DateTime.Now

				MyCookie.Value = res
				MyCookie.Expires = now.AddDays(15)
				
				Response.Cookies.Add(MyCookie)
				MyCookie = new HttpCookie("password")
				MyCookie.Value = password
				MyCookie.Expires = now.AddDays(15)
				
				Response.Cookies.Add(MyCookie)
			end if
			session("username") = res

			if returnurl = "" then
				response.redirect("default.aspx", true)
			else
				response.redirect(returnurl, true)
			end if
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
			sb.append("IP Address: " & remote_addr & system.environment.newline)
			sb.append("Http Host: " & http_host & system.environment.newline)
			sb.append("System Time: " & system.datetime.now & system.environment.newline)

			fb.makesystemlog("Failed Login", sb.tostring())
			session("page_message") = "Invalid username/password, please try again. <br /><br />Remember, if you have just created your username, you MUST validate your account by clicking the link in the email you got after you registered."
			response.redirect("error.aspx", true)
					
		end if
	end if

%>
<html>
<head>
	<title>Login</title>
	<style type="text/css" media="all">@import "/football/style2.css";</style> 
	<script type="text/javascript" src="jquery.js"></script>
	<script type="text/javascript" src="cmxform.js"></script>
	<style>
		
		form.cmxform fieldset {
		  margin-bottom: 10px;
		}
		form.cmxform legend {
		  padding: 0 2px;
		  font-weight: bold;
		}
		form.cmxform label {
		  display: inline-block;
		  line-height: 1.8;
		  vertical-align: top;
		}
		form.cmxform fieldset ol {
		  margin: 0;
		  padding: 0;
		}
		form.cmxform fieldset li {
		  list-style: none;
		  padding: 5px;
		  margin: 0;
		}
		form.cmxform fieldset fieldset {
		  border: none;
		  margin: 3px 0 0;
		}
		form.cmxform fieldset fieldset legend {
		  padding: 0 0 5px;
		  font-weight: normal;
		}
		form.cmxform fieldset fieldset label {
		  display: block;
		  width: auto;
		}
		form.cmxform em {
		  font-weight: bold;
		  font-style: normal;
		  color: #f00;
		}
		form.cmxform label {
		  width: 120px; /* Width of labels */
		}
		form.cmxform fieldset fieldset label {
		  margin-left: 123px; /* Width plus 3 (html space) */
		}

	</style>
</head>

<body>

<div id="Header"><% = http_host %></div>

<div id="Content">
		<form class="cmxform" name="loginform" method="post" action="login.aspx">
			<%
			if returnurl <> "" then 
				%><input type="hidden" name="returnurl" value="<% = returnurl %>"><%
			end if
			%>
			<fieldset>
				<legend>Login</legend>
				<table border="0" cellspacing="2" cellpadding="2">
				<tr>
					<td> Username:</td>
					<td><input type="text" name="username" id="username" value="<% = username %>"></td>
				</tr>
				<tr>
					<td>Password:</td>
					<td><input type="password" name="password" id="password"></td>
				</tr>		
				<tr>
					<td>Remember Login?</td>
					<td><input type="checkbox" name="rememberlogin"></td>
				</tr>	
				<tr>
				<td colspan="2"> <input type="submit" name="submit" value="Login"></td>
				</tr>
				</table>
			</fieldset>
		</form>

	<BR />
	<%
	try
		if session("page_message") <> "" then
			%>
			<div class="message">
			<% = session("page_message") %><br />
			</div>
			<%
			session("page_message") = ""
		end if
	catch
	end try
	%>
	<br />
	Forgot your password?  You can <a href="resetpassword.aspx">reset</a> it.  If you don't have an account you can register <a href="register.aspx">here</a><BR />

</div>

<div id="Menu">
<% 
Server.Execute("nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>

