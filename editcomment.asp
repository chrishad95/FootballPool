<%
server.execute "/cookiecheck.asp"
if session("username") = "" then
	session("page_message") = "You must login."
	response.redirect "/login.asp"
	response.end
end if
myname = session("username")
comment = request("comment")
comment_tsp = request("comment_tsp")

if comment_tsp = "" then
	session("page_message") = "Invalid comment timestamp."
	response.redirect "/default.asp"
	response.end
end if
dim cn
set cn = server.createobject("adodb.connection")
cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"


sql = "select char(referral_tsp) as referral_tsp, username, comment_text,comment_title, char(revised_tsp) as revised_tsp from site.comments where char(comment_tsp) = '" & comment_tsp & "'"


set rs = cn.execute(sql)
if rs.eof then
	response.redirect "default.asp"
	response.end
end if

referral_tsp = rs("referral_tsp")
author = rs("username")
comment = rs("comment_text")
revised_tsp = rs("revised_tsp")
comment_title = rs("comment_title")


if myname <> author then

	session("page_message") = "Authorization error."
	response.redirect "default.asp"
	response.end
end if


'sql = "create table blog.comments_revised (comment_tsp timestamp, referral_tsp timestamp, revised_tsp timestamp, username varchar(30), comment_text long varchar)"
'cn.execute sql
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">

<html>
<head>
	<title>Edit Comment - rasputin.dnsalias.com</title>
	<style type="text/css" media="screen">@import "/style4.css";</style>
	
</head>

<body>


	<div class="content">
		<h1>rasputin.dnsalias.com</h1>

		<FORM METHOD=POST ACTION="doeditcomment.asp">
		<INPUT TYPE="hidden" name=comment_tsp value='<% = request("comment_tsp") %>'>
		<TABLE>
		<% if referral_tsp = comment_tsp then %>
		<TR>
			<TD>Comment Title:<BR><TEXTAREA NAME="comment_title" ROWS="3" COLS="40"><% = comment_title %></TEXTAREA></TD>
		</TR>
		<% end if %>
		<TR>
			<TD>Comment:<BR><TEXTAREA NAME="comment" ROWS="10" COLS="40"><% = comment %></TEXTAREA></TD>
		</TR>
		<TR>
			<TD><INPUT TYPE="submit" value="Edit Comment"><INPUT TYPE="button" value="Cancel" onClick="window.document.location.replace('default.asp')"></TD>
		</TR>
		</TABLE>
		</FORM>
	</div>

<div id="navAlpha">
<% server.execute "/nav.asp" %>
</div>


<div id="navBeta"><%
	server.execute "/quotes/getrandomquote.asp"
%></div>

<!-- BlueRobot was here. -->

</body>
</html>
<%


function displayRSS2(ByVal strSource, ByVal strXSL) 

    Dim xmlRSSSource, xmlStyle 


    ' Use the XMLHTTPConnection object to grab the feed
    Set xmlHTTP = CreateObject("Microsoft.XMLHTTP")
    xmlHTTP.Open "GET", strSource, False
    xmlHTTP.Send


    Set xmlRSSSource = Server.CreateObject("MSXML2.DOMDocument.4.0")
    xmlRSSSource.async = False 
    xmlRSSSource.resolveExternals = False
	
	Set regEx = server.createobject("vbscript.RegExp")            ' Create regular expression.
	regEx.Pattern = "<\/?!?(param|meta|doctype|div|font)[^>]*>"           ' Set pattern.	
	regex.global = true
	regEx.IgnoreCase = True            ' Make case insensitive.
	str_text = regEx.Replace(xmlHTTP.ResponseText, "")

	'response.write str_text
	'exit function

    xmlRSSSource.loadXML(str_text)
   ' xmlRSSSource.load(strSource)
    If xmlRSSSource.parseError.errorCode <> 0 Then 
      Dim myError
      Set myError = xmlRSSSource.parseError
      displayRSS2 =  "<HTML><BODY><PRE>Error in Feed: " + myError.reason + xmlRSSSource.parseError.srcText+"</PRE></BODY>"
    Else 
      Set xmlStyle = Server.CreateObject("MSXML2.DOMDocument.4.0")
      xmlStyle.async = False 
      xmlStyle.load(server.mappath(strXSL)) 
      displayRSS2 =    xmlRSSSource.transformNode(xmlStyle)
      Set xmlStyle = Nothing
    End If
    Set xmlRSSSource = Nothing 
End function


function getroot(filename)
	dim idx
	idx = instrrev(filename, "/")
	getroot = left(filename, idx)
end function
function gettail(filename)
	dim idx
	idx = instrrev(filename, "/")
	gettail = mid(filename, idx + 1)
end function

sub getcomments(photo_path)
	set cn = server.createobject("adodb.connection")
	cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

	'sql = "delete from photo_comments where photo_path='" & photo_path & "'"
	'cn.execute sql

	sql = "select username,photo_path,comment,comment_time,char(comment_time) as comment_tsp  from photo_comments where photo_path='" & photo_path & "' order by comment_time asc"
	set rs = cn.execute(sql)
	while not rs.eof
		username = rs("username")
		comment = rs("comment")
		comment_time = rs("comment_time")

		%>
		<hr>
		<B><% = username %></B> says:<BR>
		<blockquote>
		<% = replace(comment,vbcrlf,"<BR>") %><BR>
		</blockquote>
		<%
		if myname = username then
		%><A HREF='editcomment.asp?comment_tsp=<% = rs("comment_tsp") %>'>Edit Comment</A><%
		end if

		rs.movenext
	wend

end sub
%>
