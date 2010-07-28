<%
server.execute "/cookiecheck.asp"
if session("username") = "" then
	session("page_message") = "You must login."
	response.redirect "/login.asp"
	response.end
end if
myname = session("username")

comment = request("comment")

comment_title = request("comment_title")

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">

<html>
<head>
	<title>New Post - rasputin.dnsalias.com</title>
	<style type="text/css" media="screen">@import "/style4.css";</style>
	
</head>

<body>


	<div class="content">
		<h1>rasputin.dnsalias.com</h1>
		<% = session("page_message") %><BR>

		<FORM METHOD=POST ACTION="donewcomment.asp" name=newcommentform>
		<TABLE>
		<TR>
			<TD>Comment Title:<BR><TEXTAREA NAME="comment_title" ROWS="3" COLS="40"><% = comment_title %></TEXTAREA></TD>
		</TR>
		<TR>
			<TD>Comment:<BR><TEXTAREA NAME="comment" ROWS="10" COLS="40"><% = comment %></TEXTAREA></TD>
		</TR>
		<TR>
			<TD><INPUT TYPE="submit" value="Add Comment"><INPUT TYPE="button" value="Cancel" onClick="window.document.location.replace('default.asp')"></TD>
		</TR>
		</TABLE>
		</FORM>
	</div>

<div id="navAlpha">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>


<div id="navBeta"><%
	server.execute "/quotes/getrandomquote.asp"
%></div>

<!-- BlueRobot was here. -->

</body>
</html>
<%
%>