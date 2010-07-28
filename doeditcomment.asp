<%
server.execute "/cookiecheck.asp"
if session("username") = "" then
	session("page_message") = "You must login."
	response.redirect "/login.asp"
	response.end
end if
myname = session("username")

set cn = server.createobject("adodb.connection")
cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"
comment_tsp = request("comment_tsp")
comment = request("comment")
comment_title = request("comment_title")


if comment_tsp = "" then
	session("page_message") = "Invalid comment timestamp."
	response.redirect "default.asp"
	response.end
end if

sql = "select char(referral_tsp) as referral_tsp, username, comment_text, char(revised_tsp) as revised_tsp from site.comments where char(comment_tsp) = '" & comment_tsp & "'"


set rs = cn.execute(sql)
if rs.eof then
	session("page_message") = "Invalid comment timestamp. Comment timestamp not found."
	response.redirect "default.asp"
	response.end
end if

author = rs("username")
referral_tsp = rs("referral_tsp")


if myname <> author then
	session("page_message") = "Authorization error."
	response.redirect "default.asp"
	response.end
end if

tsp = getdb2timestamp

sql = "insert into site.comments_revised (username,comment_text,comment_title,comment_tsp,referral_tsp,revised_tsp) select username,comment_text,comment_title,comment_tsp,referral_tsp,'" & tsp & "' from blog.comments where comment_tsp='" & comment_tsp & "'"

'response.write sql

'cn.execute sql

sql = "update site.comments set comment_text = '" & sqlfix(comment) &  "', revised_tsp='" & tsp & "', comment_title='" & sqlfix(comment_title) &  "' where comment_tsp='" & comment_tsp & "'"


'response.write sql

cn.execute sql

'response.end

%>
<script>window.document.location.replace('showpicks.asp')</script>
<%

function sqlfix (str)
	sqlfix = replace(str,"'","''")
end function

Private Function GetDB2Timestamp()
    Randomize
    
    Dim strYear
    Dim strMonth
    Dim strDay
    Dim strHour
    Dim strMinute
    Dim strSecond

    strYear = Year(Now)
    strMonth = Month(Now)
    strDay = Day(Now)
    strHour = Hour(Now)
    strMinute = Minute(Now)
    strSecond = Second(Now)

    If Len(strMonth) = 1 Then
        strMonth = "0" & strMonth
    End If

    If Len(strDay) = 1 Then
        strDay = "0" & strDay
    End If

    If Len(strHour) = 1 Then
        strHour = "0" & strHour
    End If

    If Len(strMinute) = 1 Then
        strMinute = "0" & strMinute
    End If

    If Len(strSecond) = 1 Then
        strSecond = "0" & strSecond
    End If
    Dim upperbound
    Dim lowerbound

    upperbound = 9
    lowerbound = 0

    GetDB2Timestamp = strYear & "-" & strMonth & "-" & strDay & "-" & strHour & "." & strMinute & "." & strSecond & "." _
    & Int((upperbound - lowerbound + 1) * Rnd + lowerbound) _
    & Int((upperbound - lowerbound + 1) * Rnd + lowerbound) _
    & Int((upperbound - lowerbound + 1) * Rnd + lowerbound) _
    & Int((upperbound - lowerbound + 1) * Rnd + lowerbound) _
    & Int((upperbound - lowerbound + 1) * Rnd + lowerbound) _
    & Int((upperbound - lowerbound + 1) * Rnd + lowerbound)


End Function
%>