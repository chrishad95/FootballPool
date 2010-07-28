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
''''cn.open "bodyfat"


sql = "select max(week_id) as max_week_id from (select min(game_tsp), week_id from football.sched where game_tsp < current timestamp + 2 hours group by week_id ) as t"
set rs = cn.execute(sql)
week_id = rs("max_week_id")
rs.close

'sql = "create table blog.comments (comment_tsp timestamp, ref_tsp timestamp, username varchar(30), comment_text long varchar)"
'cn.execute sql

'sql = "create table blog.comments (comment_tsp timestamp, ref_tsp timestamp, revised_tsp timestamp, username varchar(30), comment_text long varchar)"
'cn.execute sql

'sql = "alter table blog.comments add revised_tsp timestamp"
'cn.execute sql

tsp = getdb2timestamp

comment = request("comment")
comment_title = request("comment_title")

sql = "insert into SITE.comments (username,comment_text,comment_title,comment_tsp,referral_tsp,revised_tsp,comment_info,comment_type) values ("
sql = sql & "'"
sql = sql & myname
sql = sql & "'"
sql = sql & ","
sql = sql & "'"
sql = sql & sqlfix(comment)
sql = sql & "'"
sql = sql & ","
sql = sql & "'"
sql = sql & sqlfix(comment_title)
sql = sql & "'"
sql = sql & ","
sql = sql & "'"
sql = sql & tsp
sql = sql & "'"
sql = sql & ","
sql = sql & "'"
sql = sql & tsp
sql = sql & "'"
sql = sql & ","
sql = sql & "'"
sql = sql & tsp
sql = sql & "'"
sql = sql & ","
sql = sql & "'"
sql = sql & week_id
sql = sql & "'"
sql = sql & ","
sql = sql & "'"
sql = sql & "FOOTBALL"
sql = sql & "'"
sql = sql & ")"

response.write sql

cn.execute sql

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
<script>window.document.location.replace('showpicks.asp')</script>