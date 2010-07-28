<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Collections" %>
<script runat="server" language="VB">
	private myname as string = ""

	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub

</script>
<%

	server.execute ("/cookiecheck.aspx")
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
	dim submit as string = ""
	try
		submit = request("submit")
	catch
	end try
	dim email as string = ""
	try
		email = request("email")
	catch
	end try
	dim msg as string
	try
		msg = request("message")
	catch
	end try

	if submit = "Send Message" then
		if email = "" or msg = "" then
			session("page_message") = "You must enter an email address and a message."
			response.redirect("error.aspx", true)
		end if
		dim res as string = ""
		res = fb.sendmessage(email:=email, msg:=msg, username:=myname)
		if res = email then
			session("page_message") = "Message was sent."
			response.redirect("error.aspx", true)
		else
			session("page_message") = "Message was not sent."
			response.redirect("error.aspx", true)
		end if
	end if
%>
<html>
<head>
<title>Help! - <% = http_host %></title>
<script type="text/javascript" src="jquery.js"></script>
<script type="text/javascript" src="cmxform.js"></script>
<style type="text/css" media="all">@import "/football/style2.css";</football/style>
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
</football/style>
</head>

<body>

<div id="Header"><% = http_host %></div>

<div id="Content">

	<form class="cmxform">
		<fieldset>
			<legend>Questions or Comments</legend>			
			<ol>
				<li><label for="email">Your Email Address </label> <input type="text" name="email" id="email" value = "" /></li>
				<li><label for="message">Message </label></li>
				<li><TEXTAREA NAME="message" ROWS="5" COLS="40"></TEXTAREA></li>
			</ol>
			<input type="submit" name="submit" value="Send Message" />
		</fieldset>
	</form>
</div>

<div id="Menu">
<% 
server.execute("nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>