Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.ComponentModel
Imports System.Data
Imports System.Data.SqlClient
Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Web.UI.HtmlControls
Imports System.Web.Mail
Imports System.Text
Imports System.Threading
Imports System.Security.Cryptography
Imports System.Text.RegularExpressions
Imports System.Xml
Imports System.Xml.Xsl
Imports System.IO
Imports System.Math

Namespace Rasputin
    Public Class FootballUtility

        Private myconnstring As String = System.Configuration.ConfigurationSettings.AppSettings("connString")
        Private isInitialized As Boolean


        Public Sub initialize()
        End Sub

        Public Sub MakeSystemLog(log_title As String, log_text As String)
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "insert into fb_journal_entries (username,journal_type,entry_title,entry_text) values ('', 'FOOTBALL', @entry_title, @entry_text)"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(New SQLParameter("entry_title", SQLDbType.varchar, 200)).value = log_title & " - " & system.datetime.now
                    cmd.parameters.add(New SQLParameter("entry_text", SQLDbType.text, 32700)).value = log_text
                    cmd.executenonquery()
                End Using
            Catch ex As exception
                Throw (ex)
            End Try
        End Sub

        Public Function GetErrors() As dataset
            Dim res As New dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim dr As SQLDataReader
                    Dim oda As SQLDataAdapter
                    Dim parm1 As SQLParameter

                    Dim ds As dataset
                    Dim drow As datarow
                    Dim dt As datatable

                    sql = "select top 50 * from fb_journal_entries where journal_type='FOOTBALL' order by entry_tsp desc"
                    cmd = New SQLCommand(sql, con)
                    oda = New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using
            Catch ex As exception
                makesystemlog("error in geterrors", ex.tostring())
            End Try

            Return res
        End Function

        Public Function authenticate(username As String, password As String) As Boolean
            Dim res As Boolean = False
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim oda As SQLDataAdapter
                    Dim parm1 As SQLParameter

                    Dim salt As String = ""
                    Dim valid_username As String = ""

                    ' do not bother unless they are validated
                    sql = "select username, salt from fb_users where (upper(username) = @email or upper(email) = @email) and validated='Y'"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("email")).value = username.toupper()

                    Dim dt As New datatable()
                    Dim da As New sqldataadapter()
                    da.selectcommand = cmd
                    da.fill(dt)

                    If dt.rows.count > 0 Then
                        If dt.rows(0)("salt") Is dbnull.value Then
                        Else
                            salt = dt.rows(0)("salt")
                        End If
                        valid_username = dt.rows(0)("username")
                    End If

                    sql = "select count(*) from fb_users where username=@username and password=@password and validated='Y'"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username")).value = valid_username
                    cmd.parameters.add(New SQLParameter("@password", SQLDbType.varchar)).value = hashpassword(salt & password)

                    Dim usercount As Integer = 0
                    usercount = cmd.executescalar()

                    If usercount > 0 Then
                        res = True
                        sql = "update fb_users set login_count=login_count + 1, last_seen = CURRENT_TIMESTAMP where username=@username"

                        cmd = New SQLCommand(sql, con)
                        cmd.parameters.add(GetParm("username")).value = valid_username

                        cmd.executenonquery()
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetNewsItems() As ArrayList
            Return GetNewsItems(0, 10)
        End Function

        Public Function GetNewsItems(ByVal start As Integer, ByVal count As Integer) As ArrayList
            Dim res As New ArrayList()
            Try
                Using con As New SqlConnection(myconnstring)
                    con.Open()
                    Dim sql As String
                    Dim cmd As SqlCommand

                    sql = "select * from (select a.*, row_number() over(order by item_tsp desc) [rowNumber] from fb_news_items a)q where q.rowNumber between @start and @end"

                    cmd = New SqlCommand(sql, con)
                    cmd.Parameters.Add(GetParm("start")).Value = start
                    cmd.Parameters.Add(GetParm("end")).Value = start + count

                    Dim da As New SqlDataAdapter()
                    da.SelectCommand = cmd
                    Dim dt As New DataTable()
                    da.Fill(dt)
                    For Each r As DataRow In dt.Rows
                        Dim h As New Hashtable()
                        For Each c As DataColumn In dt.Columns
                            h.Add(c.ColumnName, r(c))
                        Next
                        res.Add(h)
                    Next

                End Using
            Catch ex As Exception
                Throw (ex)
            End Try
            Return res
        End Function

        Public Function ChangePassword(username As String, password As String, newpassword As String) As Boolean
            Dim res As Boolean = False
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim cmd As SQLCommand
                    Dim sql As String

                    sql = "update fb_users set password=@newpassword where username = @username and password=@password "

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username")).value = username
                    cmd.parameters.add(GetParm("newpassword")).value = hashpassword(newpassword)
                    cmd.parameters.add(GetParm("password")).value = hashpassword(password)

                    Dim rows_affected As Integer = 0

                    rows_affected = cmd.executenonquery()
                    If rows_affected > 0 Then
                        res = True
                        makesystemlog("Changed Password", username & " has changed their password successfully.")
                    Else
                        makesystemlog("Changed Password", username & " has failed to change their password. (Incorrect password)")
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetCommentsFeed(username As String) As dataset
            Dim res As New dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim dr As SQLDataReader
                    Dim oda As SQLDataAdapter
                    Dim parm1 As SQLParameter

                    Dim ds As dataset
                    Dim drow As datarow
                    Dim dt As datatable

                    'con = new SQLConnection(myconnstring)


                    sql = "select  * from fb_comments where ref_id is null order by comment_tsp DESC"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username")).value = username

                    oda = New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res

        End Function

        Public Function GetCommentsFeed(pool_id As Integer, username As String) As dataset
            Dim res As New dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim dr As SQLDataReader
                    Dim oda As SQLDataAdapter
                    Dim parm1 As SQLParameter

                    Dim ds As dataset
                    Dim drow As datarow
                    Dim dt As datatable

                    'con = new SQLConnection(myconnstring)


                    sql = "select  * from fb_comments where ref_id is null order by comment_tsp DESC"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters("@USERNAME").value = username

                    oda = New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res

        End Function

        Public Function createPool(POOL_OWNER As String, POOL_NAME As String, POOL_DESC As String, ELIGIBILITY As String, POOL_LOGO As String, POOL_BANNER As String, participate As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = ""
                    Dim cmd As SQLCommand

                    sql = "select count(*) from fb_pools where pool_owner=@pool_owner and pool_name=@pool_name"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_owner")).value = pool_owner
                    cmd.parameters.add(New SQLParameter("@pool_name", SQLDbType.VARCHAR, 100)).value = pool_name

                    Dim c As Integer = 0
                    c = cmd.executescalar()

                    If c = 0 Then
                        sql = "insert into fb_POOLS (POOL_OWNER, POOL_NAME, POOL_DESC, ELIGIBILITY, POOL_LOGO, POOL_BANNER) values (@pool_owner, @pool_name, @pool_desc, @eligibility, @pool_logo, @pool_banner)"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_owner")).value = pool_owner
                        cmd.parameters.add(New SQLParameter("@pool_name", SQLDbType.VARCHAR, 100)).value = pool_name
                        cmd.parameters.add(New SQLParameter("@pool_desc", SQLDbType.VARCHAR, 500)).value = pool_desc
                        cmd.parameters.add(New SQLParameter("@eligibility", SQLDbType.VARCHAR, 10)).value = eligibility
                        cmd.parameters.add(New SQLParameter("@pool_logo", SQLDbType.VARCHAR, 255)).value = pool_logo
                        cmd.parameters.add(New SQLParameter("@pool_banner", SQLDbType.VARCHAR, 255)).value = pool_banner

                        cmd.executenonquery()
                        If participate = "on" Then
                            sql = "select @@IDENTITY as pool_id"
                            cmd = New sqlcommand(sql, con)
                            Dim oda As New sqldataadapter()
                            oda.selectcommand = cmd
                            Dim ds As New dataset()
                            oda.fill(ds)
                            If ds.tables.count > 0 Then
                                If ds.tables(0).rows.count > 0 Then
                                    Dim pool_id As Integer
                                    pool_id = ds.tables(0).rows(0)("pool_id")
                                    makesystemlog("new pool created", "pool_owner:" & pool_owner & " pool_id:" & pool_id)
                                    addPlayer(pool_id, pool_owner)
                                End If
                            End If
                        End If

                        res = pool_name
                    Else
                        res = "The pool could not be created because the pool name already exists."
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
                res = ex.toString()
            End Try
            Return res
        End Function

        Public Function ListFeeds() As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    'dim con as SQLConnection
                    Dim parm1 As SQLParameter

                    Dim connstring As String
                    connstring = myconnstring

                    'con = new SQLConnection(connstring)


                    sql = "select * from fb_rss_feeds"

                    cmd = New SQLCommand(sql, con)

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)

                End Using
            Catch ex As exception
                makesystemlog("Error in ListFeeds", ex.tostring())
            End Try

            Return res
        End Function

        Public Function ListPools(pool_owner As String) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    'dim con as SQLConnection
                    Dim parm1 As SQLParameter

                    Dim connstring As String
                    connstring = myconnstring

                    'con = new SQLConnection(connstring)


                    sql = "select * from fb_pools where pool_owner=@pool_owner"

                    cmd = New SQLCommand(sql, con)

                    parm1 = GetParm("pool_owner")
                    parm1.value = pool_owner
                    cmd.parameters.add(parm1)

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetPoolID(pool_name As String, pool_owner As String) As Integer

            Dim res As Integer = -1
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select min(pool_id)  from fb_pools where pool_name=@pool_name and pool_owner=@pool_owner"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_owner")).value = pool_owner
                    cmd.parameters.add(New SQLParameter("@pool_name", SQLDbType.VARCHAR, 100)).value = pool_name

                    res = cmd.executescalar()

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetPoolDetails(pool_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_pools where pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function incrementviewcount(pool_id As Integer, comment_id As Integer) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    'dim con as SQLConnection
                    Dim parm1 As SQLParameter

                    Dim connstring As String
                    connstring = myconnstring

                    'con = new SQLConnection(connstring)


                    sql = "update fb_comments set views=views + 1 where comment_id=@comment_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.Parameters.Add(New SQLParameter("@comment_id", SQLDbType.Int))
                    cmd.Parameters("@comment_id").value = comment_id

                    Dim rowsupdated As Integer = 0
                    rowsupdated = cmd.executenonquery()
                    If rowsupdated > 0 Then
                        res = comment_id
                    Else
                        res = "views not updated"
                    End If
                End Using
            Catch ex As exception
                makesystemlog("Error in incrementviewcount", ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetCommentDetails(pool_id As Integer, comment_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    'dim con as SQLConnection
                    Dim parm1 As SQLParameter

                    Dim connstring As String
                    connstring = myconnstring

                    'con = new SQLConnection(connstring)


                    sql = "select * from fb_comments where comment_id=@comment_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.Parameters.Add(New SQLParameter("@comment_id", SQLDbType.Int))
                    cmd.Parameters("@comment_id").value = comment_id

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                makesystemlog("Error in GetCommentDetails", ex.tostring())
            End Try

            Return res
        End Function
        Public Function bbencode(html As String) As String

            Dim objRegEx As RegEx
            Dim objMatch As match

            Dim pat_arraylist As arraylist = New arraylist()
            Dim rep_arraylist As arraylist = New arraylist()
            Dim res As String = html

            pat_arraylist.add("\[b\](.+?)\[\/b\]")
            pat_arraylist.add("\[i\](.+?)\[\/i\]")
            pat_arraylist.add("\[u\](.+?)\[\/u\]")
            pat_arraylist.add("\[quote\](.+?)\[\/quote\]")
            pat_arraylist.add("\[quote\=(.+?)](.+?)\[\/quote\]")
            pat_arraylist.add("\[url\](.+?)\[\/url\]")
            pat_arraylist.add("\[url\=(.+?)\](.+?)\[\/url\]")
            pat_arraylist.add("\[img\](.+?)\[\/img\]")
            pat_arraylist.add("\[color\=(.+?)\](.+?)\[\/color\]")
            pat_arraylist.add("\[size\=(.+?)\](.+?)\[\/size\]")
            pat_arraylist.add("\[img_left\](.+?)\[\/img_left\]")
            pat_arraylist.add("\[img_right\](.+?)\[\/img_right\]")
            pat_arraylist.add("\[img_hover\](.+?)\[\/img_hover\]")
            pat_arraylist.add("\[user\](.+?)\[\/user\]")
            pat_arraylist.add("\[youtube\](.+?)\[\/youtube\]")
            pat_arraylist.add("\[del\](.+?)\[\/del\]")

            rep_arraylist.add("<b>$1</b>")
            rep_arraylist.add("<i>$1</i>")
            rep_arraylist.add("<u>$1</u>")
            rep_arraylist.add("<table class='quote'><tr><td>Quote:</td></tr><tr><td class='quote_box'>$1</td></tr></table>")
            rep_arraylist.add("<table class='quote'><tr><td>$1 said:</td></tr><tr><td class='quote_box'>$2</td></tr></table>")
            rep_arraylist.add("<a href='$1'>$1</a>")
            rep_arraylist.add("<a href='$1'>$2</a>")
            rep_arraylist.add("<img border ='0' src='$1' alt='User submitted image' title='User submitted image'/>")
            rep_arraylist.add("<span style='color:$1'>$2</span>")
            rep_arraylist.add("<span style='font-size:$1'>$2</span>")
            rep_arraylist.add("<img class='floatLeft' border='0' src='$1' alt='User submitted image' title='User submitted image'/>")
            rep_arraylist.add("<img class='floatRight' border='0' src='$1' alt='User submitted image' title='User submitted image'/>")
            rep_arraylist.add("<img class='preview' border='0' src='$1' alt='User submitted image' title='User submitted image'/>")
            rep_arraylist.add("<a href='/viewprofile.aspx?username=$1'>$1</a>")
            rep_arraylist.add("<object width=""425"" height=""350""><param name=""movie"" value=""$1""></param><param name=""wmode"" value=""transparent""></param><embed src=""$1"" type=""application/x-shockwave-flash"" wmode=""transparent"" width=""425"" height=""350""></embed></object>")
            rep_arraylist.add("<del>$1</del>")

            res = regex.replace(res, "\[code\](.+?)\[\/code\]", AddressOf convert_for_html, regexOptions.singleline Or RegexOptions.IgnoreCase)

            Dim i As Integer
            For i = 0 To rep_arraylist.count - 1
                objregex = New regex(pat_arraylist(i), regexOptions.singleline Or RegexOptions.IgnoreCase)
                res = objregex.replace(res, rep_arraylist(i))
            Next
            res = res.replace(system.environment.newline, "<br />" & system.environment.newline)

            Return res
        End Function
        Private Function convert_for_html(m As Match) As String
            Dim re As regex = New regex("\[code\](.+?)\[\/code\]", regexOptions.singleline Or RegexOptions.IgnoreCase)

            ' Get the matched string.
            Dim x As String = m.ToString()
            x = re.replace(x, "$1")
            x = x.replace("[", "&#091;")
            x = x.replace("]", "&#093;")
            Return "<table class=""code""><tr><td>Code:</td></tr><tr><td class=""code_box"">" & x & "</td></tr></table>"
        End Function

        Public Function GetGameDetails(pool_id As Integer, game_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from fb_sched sched full outer join fb_teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join fb_teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.game_id=@game_id and sched.pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@game_id", SQLDbType.int)).value = game_id

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetPoolGames(pool_owner As String, pool_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from fb_sched sched full outer join fb_teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join fb_teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id) order by sched.game_tsp"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(GetParm("pool_owner")).value = pool_owner

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function


        Public Function GetPoolTeams(pool_owner As String, pool_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select * from fb_teams where pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id) order by team_name"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(GetParm("pool_owner")).value = pool_owner

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetPoolInvitations(pool_owner As String, pool_id As String) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter


                    sql = "select * from fb_invites where pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id) order by email"

                    cmd = New SQLCommand(sql, con)

                    parm1 = GetParm("pool_owner")
                    parm1.value = pool_owner
                    cmd.parameters.add(parm1)

                    parm1 = GetParm("pool_id")
                    parm1.value = pool_id
                    cmd.parameters.add(parm1)

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)


                End Using
            Catch ex As exception
                makesystemlog("Error getting pool invites", ex.tostring())
            End Try

            Return res

        End Function

        Public Function SendNotice(pool_id As Integer, player_id As Integer, message As String, week_id As Integer) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String
                    Dim cmd As SQLCommand
                    'dim con as SQLConnection
                    Dim parm1 As SQLParameter

                    Dim connstring As String
                    connstring = myconnstring

                    'con = new SQLConnection(connstring)


                    sql = "select * from fb_players a full outer join fb_users b " _
                    & " on a.username=b.username where a.pool_id=@pool_id and a.player_id=@player_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters("@pool_id").value = pool_id
                    cmd.parameters.add(New SQLParameter("@player_id", SQLDbType.int))
                    cmd.parameters("@player_id").value = player_id

                    Dim oda As New SQLDataAdapter()
                    Dim player_ds As New DataSet()

                    oda.selectcommand = cmd
                    oda.fill(player_ds)

                    Try
                        Dim email As String = ""
                        email = player_ds.Tables(0).rows(0)("email")
                        Dim username As String = ""
                        username = player_ds.Tables(0).rows(0)("username")

                        Dim fastkey As String = getrandomstring()
                        sql = "insert into fb_fastkeys (username,pool_id,week_id,fastkey) " _
                        & " values (@username, @pool_id, @week_id, @fastkey)"

                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("username"))
                        cmd.parameters("@username").value = username

                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters("@pool_id").value = pool_id

                        cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int))
                        cmd.parameters("@week_id").value = week_id

                        cmd.parameters.add(New SQLParameter("@fastkey", SQLDbType.varchar, 30))
                        cmd.parameters("@fastkey").value = fastkey
                        Dim rowsaffected As Integer = 0

                        rowsaffected = cmd.executenonquery()
                        If rowsaffected > 0 Then


                            Dim sb As New stringbuilder()
                            sb.append("This is just a friendly reminder from <a href=""http://www.smackpools.com"">http://www.smackpools.com</a> to make your football picks for Week #" & week_id & ".  <br><br>" & system.environment.newline)
                            sb.append("Here is your fastpick link.<br><br>" & system.environment.newline)
                            sb.append("Go to:<br /> <a href=""http://www.smackpools.com/football/makepicks.aspx?pool_id=" & pool_id & "&week_id=" & week_id & "&player_name=" & username & "&fastkey=" & fastkey & """>http://www.smackpools.com/football/makepicks.aspx?pool_id=" & pool_id & "&week_id=" & week_id & "&player_name=" & username & "&fastkey=" & fastkey & "</a> <br />to make your picks.<br /><br />" & system.environment.newline & system.environment.newline)
                            sb.append("<br/><b>DO NOT FORWARD THIS EMAIL</b></BR> If you forward this email to someone else they will be able to use the fastpick link to change your picks for this week.  <br><br>" & system.environment.newline)
                            sb.append("<br>Message from the pool administrator:<br>" & system.environment.newline)
                            sb.append(bbencode(message))
                            sendemail(email, "Football Pool Week #" & week_id, sb.ToString())
                        End If

                    Catch ex As exception
                        makesystemlog("Error sending notice", ex.tostring())
                    End Try
                End Using
            Catch ex As exception
                makesystemlog("Error in SendNotice", ex.tostring())
            End Try
            Return res
        End Function


        Private Function getrandomstring()
            'Need to create random password.		
            Dim validcharacters As String
            validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
            Dim c As Char
            Thread.Sleep(30)
            Dim fixRand As New Random()
            Dim randomstring As stringbuilder = New stringbuilder(20)
            Dim i As Integer
            For i = 0 To 29
                randomstring.append(validcharacters.substring(fixRand.Next(0, validcharacters.length), 1))
            Next

            Return randomstring.tostring()
        End Function

        Public Function GetPoolPlayers(pool_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    'dim con as SQLConnection
                    Dim parm1 As SQLParameter

                    Dim connstring As String
                    connstring = myconnstring

                    'con = new SQLConnection(connstring)


                    sql = "select * from fb_players where pool_id=@pool_id order by username"

                    cmd = New SQLCommand(sql, con)

                    parm1 = GetParm("pool_id")
                    parm1.value = pool_id
                    cmd.parameters.add(parm1)

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using

            Catch ex As exception
                makesystemlog("Error getting pool players", ex.tostring())
            End Try

            Return res
        End Function

        Public Function ds_to_arraylist(ds As dataset) As System.Collections.Arraylist
            Dim res As New System.Collections.Arraylist()
            Try
                If ds.tables.count > 0 Then
                    If ds.tables(0).rows.count > 0 Then
                        For Each drow As datarow In ds.tables(0).rows
                            Dim ht As New System.Collections.Hashtable()
                            For Each col As datacolumn In ds.tables(0).columns
                                ht.add(col.ColumnName, drow(col))
                            Next
                            res.add(ht)
                        Next
                    End If
                End If
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function Getfiles(path As String) As system.collections.arraylist
            Dim res As New system.collections.arraylist()
            Try
                Dim temp As String()
                If System.IO.Directory.Exists(path) Then
                    temp = system.io.directory.getfiles(path)
                    For Each f As String In temp
                        f = system.io.path.getfilename(f)
                        res.add(f)
                    Next
                End If
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetPoolOptions(pool_id As Integer) As system.Collections.Hashtable

            Dim res As New system.Collections.Hashtable()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_options where pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    Dim ds As New DataSet()
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(ds)

                    res.add("LONEWOLFEPICK", "off")
                    res.add("WINWEEKPOINT", "off")
                    res.add("HIDENPROWS", "off")
                    res.add("TEAMRECORDS", "off")
                    res.add("AUTOHOMEPICKS", "off")
                    res.add("HIDESTANDINGS", "off")
                    res.add("HIDECOMMENTS", "off")

                    If ds.tables.count > 0 Then
                        If ds.tables(0).rows.count > 0 Then
                            For Each option_row As datarow In ds.tables(0).rows
                                res(option_row("OPTIONNAME")) = option_row("OPTIONVALUE")
                            Next
                        End If
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function getTeamRecord(pool_id As Integer, team_id As Integer) As String
            Dim res As String = ""
            Try

                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim cmd As SQLCommand
                    Dim sql As String

                    sql = "select a.game_id, b.away_score, b.home_score, c.team_id as away_id, d.team_id as home_id from fb_sched a full outer join fb_scores b on a.pool_id=b.pool_id and a.game_id=b.game_id full outer join fb_teams c on a.pool_id=c.pool_id and a.away_id=c.team_id full outer join fb_teams d on a.pool_id=d.pool_id and a.home_id=d.team_id where a.pool_id=@pool_id and (d.team_id=@team_id or c.team_id=@team_id)"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add("pool_id", SQLDbType.int).value = pool_id
                    cmd.parameters.add("@team_id", SQLDbType.int).value = team_id


                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    Dim ds As New dataset()
                    oda.fill(ds)


                    Dim wins As Integer = 0
                    Dim losses As Integer = 0
                    Dim ties As Integer = 0

                    For Each drow As datarow In ds.tables(0).rows
                        If drow("away_score") Is dbnull.value Or drow("home_score") Is dbnull.value Then
                        Else

                            If drow("away_score") = drow("home_score") Then
                                ties = ties + 1
                            End If
                            If drow("away_score") > drow("home_score") Then
                                ' away won the game
                                If drow("away_id") = team_id Then
                                    wins = wins + 1
                                Else
                                    losses = losses + 1
                                End If

                            End If
                            If drow("away_score") < drow("home_score") Then
                                ' home won the game
                                If drow("home_id") = team_id Then
                                    wins = wins + 1
                                Else
                                    losses = losses + 1
                                End If

                            End If
                        End If
                    Next
                    res = "" & wins & "-" & losses
                    If ties > 0 Then
                        res = res & "-" & ties
                    End If
                End Using
            Catch ex As exception
                makesystemlog("Error in getTeamRecord", ex.tostring())
            End Try
            Return res
        End Function

        Public Function UpdatePool(POOL_ID As Integer, POOL_OWNER As String, POOL_NAME As String, POOL_DESC As String, ELIGIBILITY As String, POOL_LOGO As String, POOL_BANNER As String, scorer As String) As String
            Dim res As String = ""
            If pool_name.trim() = "" Then
                Return "The pool name cannot be blank."
            End If
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = ""
                    Dim cmd As SQLCommand

                    ' find any pools owned by this user that already have this name and are not this pool (pool_id)
                    sql = "select count(*) from fb_pools where pool_name=@pool_name and pool_owner=@pool_owner and pool_id<>@pool_id"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@pool_name", SQLDbType.varchar, 100)).value = pool_name
                    cmd.parameters.add(GetParm("pool_owner")).value = pool_owner

                    Dim count As Integer = 0
                    count = cmd.executescalar()

                    If count = 0 Then
                        sql = "update fb_pools set POOL_NAME=@pool_name, POOL_DESC=@pool_desc, POOL_TSP=@pool_tsp, ELIGIBILITY=@eligibility, POOL_LOGO=@pool_logo, POOL_BANNER=@pool_banner , scorer=@scorer where POOL_ID=@pool_id and pool_owner=@pool_owner"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(New SQLParameter("@pool_name", SQLDbType.VARCHAR, 100))
                        cmd.parameters.add(New SQLParameter("@pool_desc", SQLDbType.VARCHAR, 3000))
                        cmd.parameters.add(New SQLParameter("@pool_tsp", SQLDbType.datetime))
                        cmd.parameters.add(New SQLParameter("@eligibility", SQLDbType.VARCHAR, 10))
                        cmd.parameters.add(New SQLParameter("@pool_logo", SQLDbType.VARCHAR, 255))
                        cmd.parameters.add(New SQLParameter("@pool_banner", SQLDbType.VARCHAR, 255))
                        cmd.parameters.add(New SQLParameter("scorer", SQLDbType.VARCHAR, 30))

                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters.add(GetParm("pool_owner"))

                        cmd.parameters("@pool_id").VAlue = POOL_ID
                        cmd.parameters("@pool_owner").value = POOL_OWNER
                        cmd.parameters("@pool_name").value = POOL_NAME
                        cmd.parameters("@pool_desc").value = POOL_DESC
                        cmd.parameters("@pool_tsp").Value = system.datetime.now
                        cmd.parameters("@eligibility").value = ELIGIBILITY
                        cmd.parameters("@pool_logo").value = POOL_LOGO
                        cmd.parameters("@pool_banner").value = POOL_BANNER
                        cmd.parameters("scorer").value = scorer
                        cmd.executenonquery()
                        res = pool_name
                    Else
                        res = "The pool details were not changed becuase a pool already exists with this name."
                    End If
                End Using
            Catch ex As exception
                res = ex.toString()
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function CreateTeam(TEAM_NAME As String, TEAM_SHORTNAME As String, URL As String, POOL_ID As Integer, pool_owner As String) As String
            Dim res As String = ""
            Try
                If isowner(pool_id, pool_owner) Then
                    Using con As New SQLConnection(myconnstring)
                        con.open()
                        Dim sql As String = ""
                        Dim cmd As SQLCommand

                        sql = "select count(*) from fb_teams where pool_id=@pool_id and (upper(team_name) = @team_name or upper(team_shortname) = @team_shortname)"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(New SQLParameter("@team_name", sqLDbType.VARCHAR, 40)).value = team_name.toUpper()
                        cmd.parameters.add(New SQLParameter("@team_shortname", SQLDbType.VARCHAR, 5)).value = team_shortname.toupper()

                        Dim teamcount As Integer = 0
                        teamcount = cmd.executescalar()

                        If teamcount = 0 Then

                            sql = "insert into fb_teams(TEAM_NAME, TEAM_SHORTNAME, URL, POOL_ID) values ( @team_name, @team_shortname, @url, @pool_id)"
                            cmd = New SQLCommand(sql, con)

                            cmd.parameters.add(New SQLParameter("@team_name", sqLDbType.VARCHAR, 40)).value = team_name
                            cmd.parameters.add(New SQLParameter("@team_shortname", SQLDbType.VARCHAR, 5)).value = team_shortname
                            cmd.parameters.add(New SQLParameter("@url", sqldBtYPe.VARCHAR, 200)).value = url
                            cmd.parameters.add(GetParm("pool_id")).value = pool_id
                            cmd.executenonquery()
                            res = "Team: " & team_name & " was created."
                        Else
                            res = "Team already exists with this name."
                        End If
                    End Using
                End If
            Catch ex As exception
                If ex.message.tostring().indexof("duplicate rows") >= 0 Then
                    res = "Team already exists for this pool."
                Else
                    res = ex.message
                    Dim st As New System.Diagnostics.StackTrace()
                    makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
                End If

            End Try
            Return res
        End Function

        Public Function InvitePreviousPlayer(POOL_ID As Integer, username As String, player_name As String)

            Dim res As String = ""
            Try
                If isowner(pool_id:=pool_id, pool_owner:=username) Then
                    Dim invite_key As String = createinvitekey()
                    Dim email As String = GetEmailAddress(player_name:=player_name)
                    res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
                    If res = email Then
                        sendinvite(email:=email, invite_key:=invite_key, pool_id:=pool_id, username:=username)
                    End If
                    res = "SUCCESS"
                End If
            Catch ex As exception
                If ex.message.tostring().indexof("duplicate rows") >= 0 Then
                    res = "duplicate row error."
                Else
                    res = ex.message
                    makesystemlog("Error in InvitePreviousPlayer", ex.tostring())
                End If

            End Try
            Return res
        End Function


        Public Function InvitePlayer(POOL_ID As Integer, username As String, email As String)

            Dim res As String = ""
            Try
                If isowner(pool_id:=pool_id, pool_owner:=username) Then
                    Dim invite_key As String = createinvitekey()

                    res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
                    If res = email Then
                        sendinvite(email:=email, invite_key:=invite_key, pool_id:=pool_id, username:=username)
                    End If
                    res = "SUCCESS"
                Else
                    If isplayer(pool_id:=pool_id, player_name:=username) Then
                        Dim pool_ds As New system.data.dataset()
                        pool_ds = getpooldetails(pool_id:=pool_id)

                        If pool_ds.tables.count > 0 Then
                            If pool_ds.tables(0).rows.count > 0 Then
                                If pool_ds.tables(0).rows(0)("ELIGIBILITY") = "OPEN" Then

                                    Dim invite_key As String = createinvitekey()

                                    res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
                                    If res = email Then
                                        sendinvite(email:=email, invite_key:=invite_key, pool_id:=pool_id, username:=username)
                                    End If
                                    res = "SUCCESS"
                                End If
                            End If
                        End If
                    End If
                End If

            Catch ex As exception
                If ex.message.tostring().indexof("duplicate rows") >= 0 Then
                    res = ex.message
                    Dim st As New System.Diagnostics.StackTrace()
                    makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
                End If
            End Try
            Return res
        End Function

        Public Sub SendInvite(email As String, invite_key As String, pool_id As String, username As String)

            Dim sb As New stringbuilder()
            Dim pool_ds As New system.data.dataset()
            pool_ds = getpooldetails(pool_id:=pool_id)


            If pool_ds.tables.count > 0 Then
                If pool_ds.tables(0).rows.count > 0 Then

                    If Not pool_ds.tables(0).rows(0)("pool_banner") Is dbnull.value Then
                        Dim banner_image As String = getbannerimage(pool_id)
                        sb.append("<img src=""" & banner_image & """><br />" & system.environment.newline)

                    End If
                    If username <> pool_ds.tables(0).rows(0)("pool_owner") Then

                        sb.append("You have been invited by " _
                         & username _
                         & " to participate in the pool<br /><br />" _
                         & pool_ds.tables(0).rows(0)("pool_name") _
                         & "<br /><br />created by " _
                         & pool_ds.tables(0).rows(0)("pool_owner") _
                         & ".  <br><br>" & system.environment.newline)
                    Else

                        sb.append("You have been invited " _
                         & " to participate in the pool<br /><br />" _
                         & pool_ds.tables(0).rows(0)("pool_name") _
                         & "<br /><br />created by " _
                         & pool_ds.tables(0).rows(0)("pool_owner") _
                         & ".  <br><br>" & system.environment.newline)
                    End If
                    Dim desc As String = ""
                    If Not pool_ds.tables(0).rows(0)("pool_desc") Is dbnull.value Then
                        desc = pool_ds.tables(0).rows(0)("pool_desc")
                    End If

                    sb.append("<h3>Description:</h3>" _
                     & bbencode(desc) _
                     & "<br><br>" & system.environment.newline)

                    sb.append("To accept the invitation please visit the following link.<br><br>" & system.environment.newline)
                    sb.append("Go to:<br /> <a href=""http://www.smackpools.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & """>http://www.smackpools.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & "</a> <br /><br /><br />" & system.environment.newline & system.environment.newline)

                    sb.append("You will need an account with this site (and be logged in) to accept the invitation.  If you don't have an account you should get one <a href=""http://www.smackpools.com/football/register.aspx"">here</a> first.<br /><br />" & system.environment.newline)

                    sb.append("Note: If you already have an account on rasputin.dnsalias.com, you can use your username and password from that site.<br /><br />" & system.environment.newline)

                    sb.append("Thanks,<br />" & system.environment.newline & "Chris<br><br>" & system.environment.newline)

                    sendemail(email, "Invitation to " & pool_ds.tables(0).rows(0)("pool_name"), sb.tostring())
                End If
            End If
        End Sub

        Public Function CreateInviteKey()

            'Need to create random password.
            Dim validcharacters As String

            validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"

            Dim c As Char
            Thread.Sleep(30)

            Dim fixRand As New Random()
            Dim randomstring As stringbuilder = New stringbuilder(20)


            Dim i As Integer
            For i = 0 To 29

                randomstring.append(validcharacters.substring(fixRand.Next(0, validcharacters.length), 1))


            Next

            Return randomstring.tostring()
        End Function


        Public Function CreateInvite(POOL_ID As Integer, EMAIL As String, INVITE_KEY As String, INVITE_TSP As datetime) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "insert into fb_invites(POOL_ID, EMAIL, INVITE_KEY, INVITE_TSP) values (@pool_id, @email, @invite_key, @invite_tsp)"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(GetParm("email"))
                    cmd.parameters.add(New SQLParameter("@INVITE_KEY", SQLDbType.VARCHAR, 40))
                    cmd.parameters.add(New SQLParameter("@INVITE_TSP", SQLDbType.datetime))
                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@EMAIL").value = EMAIL
                    cmd.parameters("@INVITE_KEY").value = INVITE_KEY
                    cmd.parameters("@INVITE_TSP").value = INVITE_TSP
                    cmd.executenonquery()
                    res = email
                End Using
            Catch ex As exception
                res = ex.toString()
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function DeleteInvite(POOL_ID As Integer, EMAIL As String) As String
            Dim res As String = "FAILURE"
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "delete from fb_invites where pool_id=@pool_id and email=@email"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(GetParm("email"))
                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@EMAIL").value = EMAIL

                    cmd.executenonquery()
                    res = "SUCCESS"
                End Using
            Catch ex As exception
                res = ex.toString()
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function ImportGame(game_id As Integer, POOL_ID As Integer, pool_owner As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String = ""

                        sql = "select a.*, b.team_name as home_team, c.team_name as away_team, b.team_shortname as home_team_shortname, c.team_shortname as away_team_shortname from fb_copy_scheds a left join fb_copy_teams b on a.home_id=b.team_id left join fb_copy_teams c on a.away_id=c.team_id where a.game_id=@game_id"


                        Dim cmd As SQLCommand = New SQLCommand(sql, con)
                        Dim rowsupdated As Integer

                        cmd.parameters.add(New SQLParameter("@game_id", SQLDbType.int))
                        cmd.parameters("@game_id").value = game_id

                        Dim game_ds As New dataset()
                        Dim oda As New SQLDataAdapter()
                        oda.selectcommand = cmd
                        oda.fill(game_ds)
                        Try
                            Dim game_tsp As datetime
                            Dim home_teamname As String
                            Dim away_teamname As String

                            Dim home_team_id As Integer
                            Dim away_team_id As Integer

                            Dim week_id As Integer
                            game_tsp = game_ds.tables(0).rows(0)("game_tsp")
                            home_teamname = game_ds.tables(0).rows(0)("home_team")
                            away_teamname = game_ds.tables(0).rows(0)("away_team")
                            home_team_id = game_ds.tables(0).rows(0)("home_id")
                            away_team_id = game_ds.tables(0).rows(0)("away_id")
                            week_id = game_ds.tables(0).rows(0)("week_id")
                            sql = "select * from fb_teams where pool_id=@pool_id and team_name in (@away, @home)"
                            cmd = New SQLCommand(sql, con)

                            cmd.parameters.add(GetParm("pool_id"))
                            cmd.parameters.add(New SQLParameter("@away", SQLDbType.varchar))
                            cmd.parameters.add(New SQLParameter("@home", SQLDbType.varchar))

                            cmd.parameters("@pool_id").value = pool_id
                            cmd.parameters("@home").value = home_teamname
                            cmd.parameters("@away").value = away_teamname

                            Dim teams_ds As New dataset()
                            oda.selectcommand = cmd
                            oda.fill(teams_ds)

                            Dim pool_home_id As Integer
                            Dim pool_away_id As Integer

                            Dim temprows As datarow()
                            temprows = teams_ds.tables(0).select("team_name='" & home_teamname & "'")
                            If temprows.length = 0 Then
                                makesystemlog("debug", "team not found for pool_id.  team_name:" & home_teamname)
                                ImportTeam(home_team_id, pool_id, pool_owner)
                            End If

                            temprows = teams_ds.tables(0).select("team_name='" & away_teamname & "'")
                            If temprows.length = 0 Then
                                makesystemlog("debug", "team not found for pool_id.  team_name:" & away_teamname)
                                ImportTeam(away_team_id, pool_id, pool_owner)
                            End If

                            oda.fill(teams_ds)

                            temprows = teams_ds.tables(0).select("team_name='" & home_teamname & "'")
                            If temprows.length = 0 Then
                                makesystemlog("debug", "team not found again for pool_id.  team_name:" & home_teamname)
                            Else
                                pool_home_id = temprows(0)("team_id")
                            End If

                            temprows = teams_ds.tables(0).select("team_name='" & away_teamname & "'")
                            If temprows.length = 0 Then
                                makesystemlog("debug", "team not found again for pool_id.  team_name:" & away_teamname)
                            Else
                                pool_away_id = temprows(0)("team_id")
                            End If

                            sql = "insert into fb_sched (pool_id, week_id, home_id, away_id, game_tsp) values (@pool_id, @week_id, @home_id, @away_id, @game_tsp)"
                            cmd = New SQLCommand(sql, con)

                            cmd.parameters.add(GetParm("pool_id"))
                            cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@home_id", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@away_id", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@game_tsp", SQLDbType.datetime))

                            cmd.parameters("@pool_id").value = pool_id
                            cmd.parameters("@week_id").value = week_id
                            cmd.parameters("@home_id").value = pool_home_id
                            cmd.parameters("@away_id").value = pool_away_id
                            cmd.parameters("@game_tsp").value = game_tsp
                            rowsupdated = cmd.executenonquery()


                        Catch ex As exception
                            makesystemlog("Error in importgame", ex.tostring())
                        End Try


                        If rowsupdated > 0 Then
                        Else
                            res = "Game was not imported."
                        End If

                    Else
                        res = "No Pools found for " & pool_owner
                    End If
                End Using
            Catch ex As exception
                If ex.message.tostring().indexof("duplicate rows") >= 0 Then
                    res = "Team already exists for this pool."
                Else
                    res = ex.message
                    makesystemlog("Error in Import Team", ex.tostring())
                End If
            End Try
            Return res
        End Function

        Public Function ImportTeam(TEAM_ID As Integer, POOL_ID As Integer, pool_owner As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String = ""

                        sql = "insert into fb_teams (pool_id, team_name, team_shortname) select " & pool_id & ", team_name, team_shortname from fb_copy_teams where team_id=@team_id"

                        Dim cmd As SQLCommand = New SQLCommand(sql, con)
                        Dim rowsupdated As Integer

                        cmd.parameters.add(GetParm("team_id"))
                        cmd.parameters("@TEAM_ID").value = TEAM_ID
                        rowsupdated = cmd.executenonquery()

                        If rowsupdated > 0 Then
                        Else
                            res = "Team was not imported."
                        End If

                    Else
                        res = "No Pools found for " & pool_owner
                    End If
                End Using
            Catch ex As exception
                If ex.message.tostring().indexof("duplicate rows") >= 0 Then
                    res = "Team already exists for this pool."
                Else
                    res = ex.message
                    Dim st As New System.Diagnostics.StackTrace()
                    makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
                End If
            End Try
            Return res
        End Function

        Public Function DeleteGame(game_id As Integer, pool_id As Integer, pool_owner As String) As String
            Dim res As String = "Failed to delete game completely."
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String = ""
                        Dim rowsupdated As Integer = 0
                        Dim cmd As SQLCommand

                        sql = "delete from fb_games where pool_id=@pool_id and game_id=@game_id"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(New SQLParameter("@game_id", SQLDbType.int)).value = game_id
                        rowsupdated = cmd.executenonquery()

                        If rowsupdated > 0 Then
                            res = "Successfully deleted game:" & game_id
                        Else
                            res = "Zero games found for game:" & game_id
                        End If

                        sql = "delete from fb_picks where pool_id=@pool_id and game_id=@game_id"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(New SQLParameter("@game_id", SQLDbType.int)).value = game_id
                        rowsupdated = cmd.executenonquery()

                        If rowsupdated > 0 Then
                            res = res & " Successfully deleted " & rowsupdated & " picks for game:" & game_id
                        Else
                            res = res & " Zero picks deleted for game:" & game_id
                        End If

                        sql = "delete from fb_scores where pool_id=@pool_id and game_id=@game_id"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(New SQLParameter("@game_id", SQLDbType.int)).value = game_id
                        rowsupdated = cmd.executenonquery()

                        If rowsupdated > 0 Then
                            res = res & " Successfully deleted " & rowsupdated & " scores for game:" & game_id
                        Else
                            res = res & " Zero scores deleted for game:" & game_id
                        End If

                        sql = "delete from fb_tiebreakers where pool_id=@pool_id and game_id=@game_id"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(New SQLParameter("@game_id", SQLDbType.int)).value = game_id
                        rowsupdated = cmd.executenonquery()
                        If rowsupdated > 0 Then
                            res = res & " Successfully deleted " & rowsupdated & " tiebreakers for game:" & game_id
                        Else
                            res = res & " Zero tiebreakers deleted for game:" & game_id
                        End If
                    Else
                        res = "Invalid pool/owner."
                    End If

                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function DeleteTeam(TEAM_ID As Integer, POOL_ID As Integer, pool_owner As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String = ""
                        Dim rowsupdated As Integer = 0
                        Dim cmd As SQLCommand

                        sql = "delete from fb_teams where pool_id=@pool_id and team_id=@team_id"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(GetParm("team_id")).value = team_id
                        rowsupdated = cmd.executenonquery()

                        If rowsupdated > 0 Then
                            res = "Successfully deleted " & rowsupdated & " teams for team:" & team_id
                        Else
                            res = res & "Zero teams deleted for team:" & team_id
                        End If

                        sql = "select game_id from fb_games where pool_id=@pool_id and (away_id=@team_id or home_id=@team_id)"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(GetParm("team_id")).value = team_id

                        Dim da As New SQLDataAdapter()
                        da.selectcommand = cmd
                        Dim ds As New dataset()
                        da.fill(ds)

                        Try
                            For Each drow As datarow In ds.tables(0).rows
                                res = res & deletegame(drow("game_id"), pool_id, pool_owner)
                            Next
                        Catch
                        End Try

                    Else
                        res = res & "Invalid pool/owner."
                    End If
                End Using
            Catch ex As exception
                res = res & ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function UpdateTeam(TEAM_ID As Integer, TEAM_NAME As String, TEAM_SHORTNAME As String, URL As String, POOL_ID As Integer, pool_owner As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String = ""

                        sql = "update fb_teams set TEAM_NAME=@TEAM_NAME, TEAM_SHORTNAME=@TEAM_SHORTNAME, URL=@URL where POOL_ID=@POOL_ID and TEAM_ID=@TEAM_ID"
                        Dim cmd As SQLCommand = New SQLCommand(sql, con)
                        Dim rowsupdated As Integer

                        cmd.parameters.add(New SQLParameter("@TEAM_NAME", SQLDbType.VARCHAR, 40)).value = team_name
                        cmd.parameters.add(New SQLParameter("@TEAM_SHORTNAME", SQLDbType.VARCHAR, 5)).value = team_shortname
                        cmd.parameters.add(New SQLParameter("@URL", SQLDbType.VARCHAR, 200)).value = url
                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(GetParm("team_id")).value = team_id
                        rowsupdated = cmd.executenonquery()

                        If rowsupdated > 0 Then
                            res = team_name
                        Else
                            res = "Team was not updated."
                        End If

                    Else
                        res = "No Pools found for " & pool_owner
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetTiebreakers(pool_id As Integer, pool_owner As String) As dataset
            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String
                        Dim cmd As SQLCommand

                        sql = "select * from fb_tiebreakers where pool_id=@pool_id"

                        cmd = New SQLCommand(sql, con)
                        cmd.parameters.add(GetParm("pool_id")).value = pool_id

                        Dim oda As New SQLDataAdapter()
                        oda.selectcommand = cmd
                        oda.fill(res)

                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function ListWeeks(pool_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select distinct week_id from fb_sched where pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetPreviousPlayers(pool_owner As String) As System.Collections.Arraylist

            Dim res As New System.Collections.Arraylist()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select distinct username from fb_players a where a.pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner)"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_owner")).value = pool_owner

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    Dim ds As New dataset()
                    oda.fill(ds)
                    If ds.tables.count > 0 Then
                        If ds.tables(0).rows.count > 0 Then
                            For Each drow As datarow In ds.tables(0).rows
                                res.add(drow("username"))
                            Next
                        End If
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function


        Public Function GetPlayers(pool_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_players where pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)

                    parm1 = GetParm("pool_id")
                    parm1.value = pool_id
                    cmd.parameters.add(parm1)

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function AddGames(POOL_ID As Integer, pool_owner As String, games_text As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim lines As String()
                        lines = games_text.split(system.environment.newline)
                        Dim res_total As String = ""
                        Dim success As Boolean = True

                        For Each line As String In lines
                            If line.trim() <> "" Then
                                Dim elements As String()
                                elements = line.split(",")
                                Dim myres As String
                                Try
                                    myres = creategame(week_id:=elements(0), _
                                     away_id:=lookupteam(pool_id:=pool_id, team_name:=elements(1)), _
                                     home_id:=lookupteam(pool_id:=pool_id, team_name:=elements(2)), _
                                     game_tsp:=elements(3), _
                                     pool_id:=pool_id, _
                                     game_url:="", _
                                     pool_owner:=pool_owner)
                                Catch ex As exception
                                    success = False
                                    makesystemlog("error adding game from batch", ex.tostring())
                                    res_total = res_total & "Error adding game: " & line & system.environment.newline
                                End Try
                            End If
                        Next
                        If success Then
                            res = pool_owner
                        Else
                            res = res_total
                        End If

                    Else
                        res = "invalid pool_id for " & pool_owner
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function lookupteam(pool_id As Integer, team_name As String) As String
            Dim res As String = "NO TEAM FOUND"
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "select team_id from fb_teams where (team_name=@team_name or UPPER(team_shortname)=@team_shortname) and pool_id=@pool_id"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@TEAM_NAME", SQLDbType.VARCHAR, 40))
                    cmd.parameters.add(New SQLParameter("@TEAM_shortname", SQLDbType.VARCHAR))
                    cmd.parameters.add(GetParm("pool_id"))

                    cmd.parameters("@TEAM_NAME").value = TEAM_NAME
                    cmd.parameters("@TEAM_shortname").value = TEAM_NAME.toupper()
                    cmd.parameters("@POOL_ID").value = POOL_ID

                    Dim oda As New SQLDataAdapter()
                    Dim ds As New dataset()
                    oda.selectcommand = cmd
                    oda.fill(ds)

                    If ds.tables.count > 0 Then
                        If ds.tables(0).rows.count > 0 Then
                            res = ds.tables(0).rows(0)("team_id")
                        End If
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("Error looking up team", ex.tostring())
            End Try
            Return res
        End Function

        Public Function CreateGame(WEEK_ID As Integer, HOME_ID As Integer, AWAY_ID As Integer, GAME_TSP As datetime, GAME_URL As String, POOL_ID As Integer, pool_owner As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If away_id = home_id Then
                        res = "The game could not be created because a team cannot play itself."
                    Else

                        If isowner(pool_owner:=pool_owner, pool_id:=pool_id) Then

                            Dim sql As String = "insert into fb_sched (WEEK_ID, HOME_ID, AWAY_ID, GAME_TSP, GAME_URL, POOL_ID) values (@WEEK_ID, @HOME_ID, @AWAY_ID, @GAME_TSP, @GAME_URL, @POOL_ID)"

                            Dim cmd As SQLCommand = New SQLCommand(sql, con)

                            cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@HOME_ID", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@AWAY_ID", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@GAME_TSP", SQLDbType.datetime))
                            cmd.parameters.add(New SQLParameter("@GAME_URL", SQLDbType.VARCHAR, 300))
                            cmd.parameters.add(GetParm("pool_id"))
                            cmd.parameters("@WEEK_ID").value = WEEK_ID
                            cmd.parameters("@HOME_ID").value = HOME_ID
                            cmd.parameters("@AWAY_ID").value = AWAY_ID
                            cmd.parameters("@GAME_TSP").value = GAME_TSP
                            cmd.parameters("@GAME_URL").value = GAME_URL
                            cmd.parameters("@POOL_ID").value = POOL_ID
                            cmd.executenonquery()
                            res = pool_owner
                        Else
                            res = "invalid pool_id for " & pool_owner
                        End If
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function MakeComment(POOL_ID As Integer, USERNAME As String, COMMENT_TEXT As String, COMMENT_TITLE As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String

                    Dim cmd As SQLCommand
                    sql = "insert into fb_comments(pool_id, USERNAME, COMMENT_TEXT, COMMENT_TSP,  COMMENT_TITLE, views) values (1,@username, @comment_text, @comment_tsp, @comment_title, 0)"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters.add(New SQLParameter("@COMMENT_TEXT", SQLDbType.text))
                    cmd.parameters.add(New SQLParameter("@COMMENT_TSP", SQLDbType.datetime))
                    cmd.parameters.add(New SQLParameter("@COMMENT_TITLE", SQLDbType.VARCHAR, 200))
                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@COMMENT_TEXT").value = COMMENT_TEXT
                    cmd.parameters("@COMMENT_TSP").value = system.datetime.now
                    cmd.parameters("@COMMENT_TITLE").value = COMMENT_TITLE
                    cmd.executenonquery()
                    res = username
                End Using

            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function


        Public Function MakeComment(POOL_ID As Integer, USERNAME As String, COMMENT_TEXT As String, COMMENT_TITLE As String, ref_id As Integer) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String

                    Dim cmd As SQLCommand


                    sql = "insert into fb_comments(pool_id,USERNAME, COMMENT_TEXT, COMMENT_TSP,  COMMENT_TITLE, ref_id, views) values (1,@username, @comment_text, @comment_tsp, @comment_title, @ref_id, 0)"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters.add(New SQLParameter("@COMMENT_TEXT", SQLDbType.text))
                    cmd.parameters.add(New SQLParameter("@COMMENT_TSP", SQLDbType.datetime))
                    cmd.parameters.add(New SQLParameter("@COMMENT_TITLE", SQLDbType.VARCHAR, 200))
                    cmd.parameters.add(New SQLParameter("@ref_id", SQLDbType.int))
                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@COMMENT_TEXT").value = COMMENT_TEXT
                    cmd.parameters("@COMMENT_TSP").value = system.datetime.now
                    cmd.parameters("@COMMENT_TITLE").value = COMMENT_TITLE
                    cmd.parameters("@ref_id").value = ref_id
                    cmd.executenonquery()
                    res = username
                End Using

            Catch ex As exception
                res = ex.message
                makesystemlog("Error in MakeComment", ex.tostring())
            End Try
            Return res
        End Function

        Public Function UpdateComment(pool_id As Integer, comment_id As Integer, COMMENT_TEXT As String, COMMENT_TITLE As String) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String

                    Dim cmd As SQLCommand


                    sql = "update fb_comments set comment_title=@comment_title, comment_text=@comment_text where comment_id=@comment_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@COMMENT_TITLE", SQLDbType.VARCHAR, 200))
                    cmd.parameters.add(New SQLParameter("@COMMENT_TEXT", SQLDbType.text))
                    cmd.parameters.add(New SQLParameter("@comment_id", SQLDbType.int))
                    cmd.parameters("@COMMENT_TEXT").value = COMMENT_TEXT
                    cmd.parameters("@COMMENT_TITLE").value = COMMENT_TITLE
                    cmd.parameters("@comment_id").value = comment_id
                    cmd.executenonquery()
                    res = comment_id

                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("Error in UpdateComment", ex.tostring())
            End Try
            Return res
        End Function


        Public Function UpdateGame(GAME_ID As Integer, WEEK_ID As Integer, HOME_ID As Integer, AWAY_ID As Integer, GAME_TSP As datetime, GAME_URL As String, POOL_ID As Integer, pool_owner As String) As String
            Dim res As String
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String = "update fb_sched set WEEK_ID=@WEEK_ID, HOME_ID=@HOME_ID, AWAY_ID=@AWAY_ID, GAME_TSP=@GAME_TSP, GAME_URL=@GAME_URL where GAME_ID=@GAME_ID and pool_id=@pool_id"
                        Dim cmd As SQLCommand = New SQLCommand(sql, con)

                        cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@HOME_ID", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@AWAY_ID", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@GAME_TSP", SQLDbType.datetime))
                        cmd.parameters.add(New SQLParameter("@GAME_URL", SQLDbType.VARCHAR, 300))
                        cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters("@GAME_ID").value = GAME_ID
                        cmd.parameters("@WEEK_ID").value = WEEK_ID
                        cmd.parameters("@HOME_ID").value = HOME_ID
                        cmd.parameters("@AWAY_ID").value = AWAY_ID
                        cmd.parameters("@GAME_TSP").value = GAME_TSP
                        cmd.parameters("@GAME_URL").value = GAME_URL
                        cmd.parameters("@POOL_ID").value = POOL_ID

                        cmd.executenonquery()
                        res = pool_owner
                    Else
                        res = "Invalid pool_id."
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function isScorer(pool_id As Integer, username As String) As Boolean
            Dim res As Boolean = False
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select count(*)  from fb_pools where scorer=@scorer and pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)

                    parm1 = New SQLParameter("@scorer", SQLDbType.varchar, 50)
                    parm1.value = username
                    cmd.parameters.add(parm1)

                    parm1 = GetParm("pool_id")
                    parm1.value = pool_id
                    cmd.parameters.add(parm1)
                    Dim pool_count As Integer = 0
                    pool_count = cmd.executescalar()
                    If pool_count > 0 Then
                        res = True
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res

        End Function
        Public Function getBannerImage(pool_id As Integer) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select pool_banner from fb_pools where pool_id=@pool_id"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    res = cmd.executescalar()
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function isNotOwner(pool_id As Integer, pool_owner As String) As Boolean
            Return (Not isowner(pool_id, pool_owner))
        End Function

        Public Function isOwner(pool_id As Integer, pool_owner As String) As Boolean
            Dim res As Boolean = False
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select count(*)  from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)

                    parm1 = GetParm("pool_owner")
                    parm1.value = pool_owner
                    cmd.parameters.add(parm1)

                    parm1 = GetParm("pool_id")
                    parm1.value = pool_id
                    cmd.parameters.add(parm1)
                    Dim pool_count As Integer = 0
                    pool_count = cmd.executescalar()
                    If pool_count > 0 Then
                        res = True
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res

        End Function

        Public Function SetFeed(pool_id As Integer, feed_id As Integer) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "update fb_pools set feed_ID=@feed_id where pool_id=@pool_id"

                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@FEED_ID", SQLDbType.int))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@FEED_ID").value = FEED_ID

                    Dim rowsaffected As Integer = 0
                    rowsaffected = cmd.executenonquery()

                    If rowsaffected > 0 Then
                        res = pool_id
                    Else
                        res = "Feed was not set"
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("error in SetFeed", ex.toString())
            End Try
            Return res
        End Function

        Public Function SetOption(pool_id As Integer, optionname As String, optionvalue As String) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String = "update fb_options set optionvalue=@optionvalue where pool_id=@pool_id and optionname=@optionname"

                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@OPTIONVALUE", SQLDbType.varchar, 255))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(New SQLParameter("@OPTIONNAME", SQLDbType.varchar, 30))
                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@OPTIONVALUE").value = OPTIONVALUE
                    cmd.parameters("@OPTIONNAME").value = OPTIONNAME

                    Dim rowsaffected As Integer = 0
                    rowsaffected = cmd.executenonquery()

                    If rowsaffected > 0 Then
                        res = pool_id
                    Else
                        sql = "insert into fb_options (optionvalue, pool_id, optionname) values (@optionvalue, @pool_id, @optionname)"


                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(New SQLParameter("@OPTIONVALUE", SQLDbType.varchar, 255))
                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters.add(New SQLParameter("@OPTIONNAME", SQLDbType.varchar, 30))
                        cmd.parameters("@POOL_ID").value = POOL_ID
                        cmd.parameters("@OPTIONVALUE").value = OPTIONVALUE
                        cmd.parameters("@OPTIONNAME").value = OPTIONNAME
                        rowsaffected = cmd.executenonquery()
                        If rowsaffected > 0 Then
                            res = pool_id
                        Else
                            res = "Failed to update option"
                        End If
                    End If
                    If optionname = "AUTOHOMEPICKS" Then
                        updatescoretsp(pool_id)
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Sub UpdateScoreTsp(pool_id As Integer)
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "update fb_pools set updatescore_tsp = CURRENT_TIMESTAMP where pool_id=@pool_id"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.executenonquery()

                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
        End Sub

        Public Function GetFeed(pool_id As Integer, xslfile As String) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_rss_feeds where feed_id=(select feed_id from fb_pools where pool_id=@pool_id)"

                    cmd = New SQLCommand(sql, con)
                    parm1 = GetParm("pool_id")
                    parm1.value = pool_id
                    cmd.parameters.add(parm1)

                    Dim oda As New SQLDataAdapter()
                    Dim ds As New dataset()
                    oda.selectcommand = cmd
                    oda.fill(ds)
                    If ds.Tables.Count > 0 Then
                        If ds.Tables(0).rows.count > 0 Then
                            res = GetRSSFeed(feed_url:=ds.Tables(0).rows(0)("feed_url"), xslfile:=xslfile)
                        End If
                    End If
                End Using

            Catch ex As exception
                makesystemlog("error in GetFeed", ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetRSSFeed(feed_url As String, xslfile As String) As String


            ' Using a live RSS feed... could also use a cached XML file.
            Dim strXmlSrc As String = feed_url
            'Dim strXmlSrc As String = Server.MapPath("megatokyo.xml")

            ' Path to our XSL file.  Changing the XSL file changes the
            ' look of the HTML output.  Try toggling the commenting on the
            ' following two lines to give it a try.
            Dim strXslFile As String = xslfile
            'Dim strXslFile As String = Server.MapPath("megatokyo2.xsl")

            ' Load our XML file into the XmlDocument object.
            Dim myXmlDoc As XmlDocument = New XmlDocument()
            myXmlDoc.Load(strXmlSrc)

            ' Load our XSL file into the XslTransform object.
            Dim myXslDoc As XslTransform = New XslTransform()
            myXslDoc.Load(strXslFile)

            ' Create a StringBuilder and then point a StringWriter at it.
            ' We'll use this to hold the HTML output by the Transform method.
            Dim myStringBuilder As StringBuilder = New StringBuilder()
            Dim myStringWriter As StringWriter = New StringWriter(myStringBuilder)

            ' Call the Transform method of the XslTransform object passing it
            ' our input via the XmlDocument and getting output via the StringWriter.
            myXslDoc.Transform(myXmlDoc, Nothing, myStringWriter)

            ' Since I've got the page set to cache, I tag on a little
            ' footer indicating when the page was actually built.
            'myStringBuilder.Append(vbCrLf & "<p><em>Cached at: " & Now() & "</em></p>" & vbCrLf)

            ' Take our resulting HTML and display it via an ASP.NET
            ' literal control.
            Return myStringBuilder.ToString

        End Function

        Public Function UpdateTiebreaker(POOL_ID As Integer, WEEK_ID As Integer, GAME_ID As Integer, pool_owner As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    If isowner(pool_id:=pool_id, pool_owner:=pool_owner) Then
                        Dim sql As String = "update fb_tiebreakers set GAME_ID=@GAME_ID, tb_tsp=@tb_tsp where pool_id=@pool_id and week_id=@week_id"

                        Dim cmd As SQLCommand = New SQLCommand(sql, con)

                        cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@TB_TSP", SQLDbType.datetime))
                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                        cmd.parameters("@POOL_ID").value = POOL_ID
                        cmd.parameters("@WEEK_ID").value = WEEK_ID
                        cmd.parameters("@GAME_ID").value = GAME_ID
                        cmd.parameters("@TB_TSP").value = system.datetime.now

                        Dim rowsaffected As Integer = 0
                        rowsaffected = cmd.executenonquery()

                        If rowsaffected = 0 Then

                            sql = "insert into fb_tiebreakers(POOL_ID, WEEK_ID, GAME_ID, TB_TSP) values (@pool_id, @week_id, @game_id, @tb_tsp)"
                            cmd = New SQLCommand(sql, con)

                            cmd.parameters.add(GetParm("pool_id"))
                            cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@TB_TSP", SQLDbType.datetime))
                            cmd.parameters("@POOL_ID").value = POOL_ID
                            cmd.parameters("@WEEK_ID").value = WEEK_ID
                            cmd.parameters("@GAME_ID").value = GAME_ID
                            cmd.parameters("@TB_TSP").value = system.datetime.now
                            rowsaffected = cmd.executenonquery()
                        End If
                        If rowsaffected > 0 Then
                            res = pool_owner
                        Else
                            res = "Tie breaker was not set"
                        End If

                    Else
                        res = "invalid pool_id"
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function isvalidfastkey(fastkey As String, pool_id As Integer, week_id As Integer, player_name As String) As Boolean
            Dim res As Boolean = False

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select count(*) from fb_fastkeys where username=@username and week_id=@week_id and fastkey=@fastkey and pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                    cmd.parameters.add(New SQLParameter("@FASTKEY", SQLDbType.CHAR, 30))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters("@USERNAME").value = player_name
                    cmd.parameters("@WEEK_ID").value = WEEK_ID
                    cmd.parameters("@FASTKEY").value = FASTKEY
                    cmd.parameters("@POOL_ID").value = POOL_ID

                    Dim fk_count As Integer = 0
                    fk_count = cmd.executescalar()
                    If fk_count > 0 Then
                        res = True
                    Else
                        makesystemlog("invalid fastkey", "fastkey=" & fastkey & ", week_id=" & week_id & ", pool_id=" & pool_id & ", player_name=" & player_name)

                    End If


                    Return res
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try


            Return res
        End Function

        Public Function GetUsername(s As String) As String
            Dim res As String = ""
            If s.contains("@") Then
                res = GetUsernameForEmail(s)
            Else
                Try
                    Using con As New SQLConnection(myconnstring)
                        con.open()
                        Dim sql As String = "select username from fb_users where UPPER(username)=@username"
                        Dim cmd As SQLCommand = New SQLCommand(sql, con)

                        cmd.parameters.add(getParm("username")).value = s.toupper()
                        res = cmd.executescalar()
                    End Using
                Catch ex As exception
                    res = ""
                    Dim st As New System.Diagnostics.StackTrace()
                    makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
                End Try
            End If
            Return res
        End Function

        Public Function GetUsernameForEmail(email As String) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "select username from fb_users where UPPER(email)=@email"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@email", SQLDbType.VARCHAR, 50)).value = email.toupper()
                    res = cmd.executescalar()
                End Using
            Catch ex As exception
                res = ""
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetEmailAddress(player_name As String) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "select email from fb_users where username=@username"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters("@USERNAME").value = player_name
                    res = cmd.executescalar()
                End Using
            Catch ex As exception
                res = ""
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function NotifyPlayer(player_name As String, subject As String, body As String, pool_id As String) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "select email from fb_users where username=@username"

                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters("@USERNAME").value = player_name

                    Dim email As String = ""
                    email = cmd.executescalar()

                    Dim pool_name As String
                    sql = "select pool_name from fb_pools where pool_id=@pool_id"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters("@pool_id").value = pool_id
                    pool_name = cmd.executescalar()
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("error updating pick", ex.toString())
            End Try
            Return res

        End Function

        Public Function UpdatePick(POOL_ID As Integer, GAME_ID As Integer, USERNAME As String, TEAM_ID As Integer, MOD_USER As String) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim updatetime As datetime = datetime.now

                    sql = "insert into fb_picks_history (POOL_ID, GAME_ID, USERNAME, TEAM_ID, MOD_USER, MOD_TSP) values (@pool_id, @game_id, @username, @team_id, @mod_user, @mod_tsp)"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters.add(GetParm("team_id"))
                    cmd.parameters.add(New SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
                    cmd.parameters.add(New SQLParameter("@MOD_TSP", SQLDbType.datetime))

                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@GAME_ID").value = GAME_ID
                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@TEAM_ID").value = TEAM_ID
                    cmd.parameters("@MOD_USER").value = MOD_USER
                    cmd.parameters("@MOD_TSP").value = updatetime

                    cmd.executenonquery()

                    sql = "update fb_picks set TEAM_ID=@team_id, mod_user=@mod_user, mod_tsp=@mod_tsp where pool_id=@pool_id and GAME_ID=@game_id and username=@username and team_id <> @team_id"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("team_id"))
                    cmd.parameters.add(New SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
                    cmd.parameters.add(New SQLParameter("@MOD_TSP", SQLDbType.datetime))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                    cmd.parameters.add(GetParm("username"))

                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@GAME_ID").value = GAME_ID
                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@MOD_USER").value = MOD_USER
                    cmd.parameters("@MOD_TSP").value = updatetime
                    cmd.parameters("@TEAM_ID").value = TEAM_ID
                    Dim rowsaffected As Integer = 0
                    rowsaffected = cmd.executenonquery()

                    sql = "select count(*) from fb_picks where pool_id=@pool_id and game_id=@game_id and username=@username"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                    cmd.parameters.add(GetParm("username"))

                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@GAME_ID").value = GAME_ID
                    cmd.parameters("@USERNAME").value = USERNAME
                    Dim picksfound As Integer = 0
                    picksfound = cmd.executescalar()

                    If rowsaffected = 0 And picksfound = 0 Then

                        sql = "insert into fb_picks(POOL_ID, GAME_ID, USERNAME, TEAM_ID, MOD_USER, MOD_TSP) values (@pool_id, @game_id, @username, @team_id, @mod_user, @mod_tsp)"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                        cmd.parameters.add(GetParm("username"))
                        cmd.parameters.add(GetParm("team_id"))
                        cmd.parameters.add(New SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
                        cmd.parameters.add(New SQLParameter("@MOD_TSP", SQLDbType.datetime))
                        cmd.parameters("@POOL_ID").value = POOL_ID
                        cmd.parameters("@GAME_ID").value = GAME_ID
                        cmd.parameters("@USERNAME").value = USERNAME
                        cmd.parameters("@TEAM_ID").value = TEAM_ID
                        cmd.parameters("@MOD_USER").value = MOD_USER
                        cmd.parameters("@MOD_TSP").value = system.datetime.now
                        rowsaffected = cmd.executenonquery()

                    End If
                    If rowsaffected > 0 Or picksfound > 0 Then
                        res = username
                    Else
                        res = "Failed to update pick."
                    End If
                End Using

            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function PicksCanBeSeen(pool_id As Integer, week_id As Integer) As Boolean
            Dim res As Boolean = False
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select min(game_tsp) as game_tsp from fb_sched a where a.pool_id=@pool_id and a.week_id=@week_id "

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int)).value = week_id

                    Dim checkdate As datetime = system.datetime.now
                    checkdate = checkdate.addminutes(30)

                    ' this is a problem when the select returns null
                    Dim gamedate As datetime

                    Dim ds As New DataSet()
                    Dim oda As New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(ds)
                    If ds.tables.Count > 0 Then
                        If ds.Tables(0).rows.count > 0 Then
                            If ds.Tables(0).rows(0)("game_tsp") Is dbnull.Value Then
                                gamedate = checkdate.AddHours(1)
                            Else
                                gamedate = ds.Tables(0).rows(0)("game_tsp")
                            End If
                        End If
                    End If
                    If datetime.compare(gamedate, checkdate) > 0 Then
                        res = False
                    Else
                        res = True
                    End If
                End Using


            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function isPlayer(pool_id As Integer, player_name As String) As Boolean
            Dim res As Boolean = False
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select count(*) from fb_players where pool_id=@pool_id and username=@username"

                    cmd = New SQLCommand(sql, con)

                    parm1 = GetParm("pool_id")
                    parm1.value = pool_id
                    cmd.parameters.add(parm1)
                    parm1 = GetParm("username")
                    parm1.value = player_name
                    cmd.parameters.add(parm1)

                    Dim playercount As Integer = 0
                    playercount = cmd.executescalar()
                    If playercount > 0 Then
                        res = True
                    End If
                End Using

            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function ChangeNickname(pool_id As Integer, username As String, nickname As String) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "update fb_players set NICKNAME=@nickname WHERE pool_id=@pool_id AND username=@username"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@NICKNAME", SQLDbType.VARCHAR, 100))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(GetParm("username"))

                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@NICKNAME").value = NICKNAME

                    Dim rowsaffected As Integer = 0

                    rowsaffected = cmd.executenonquery()


                    If rowsaffected > 0 Then
                        res = username
                    Else
                        res = "Failed to update nickname."
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("error in ChangeNickname", ex.toString())
            End Try
            Return res
        End Function

        Public Function GetGamesForWeek(pool_id As Integer, week_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select a.game_id,a.week_id,a.away_id,a.home_id,a.game_tsp,b.team_name as away_team, b.team_shortname as away_shortname, b.url as away_url, c.team_name as home_team, c.team_shortname as home_shortname, c.url as home_url from fb_sched a full outer join fb_teams b on a.pool_id=b.pool_id and a.away_id=b.team_id full outer join fb_teams c on a.pool_id=c.pool_id and a.home_id=c.team_id  where a.pool_id=@pool_id and a.week_id=@week_id order by  a.game_tsp"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    parm1 = New SQLParameter("week_id", SQLDbType.int)
                    parm1.value = week_id
                    cmd.parameters.add(parm1)

                    Dim oda As New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using
            Catch ex As exception
                makesystemlog("Error in GetGamesForWeek", ex.tostring())
            End Try

            Return res
        End Function


        Public Function GetDefaultWeek(pool_id As Integer) As Integer

            Dim res As Integer = 0
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select min(week_id) as week_id from fb_sched where pool_id=@pool_id and  game_tsp > dateadd(day,-1, current_timestamp)"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    Dim ds As New dataset()
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(ds)
                    If ds.tables.count > 0 Then
                        If ds.tables(0).rows.count > 0 Then
                            If ds.tables(0).rows(0)("week_id") Is dbnull.value Then
                                res = 1
                            Else
                                res = ds.tables(0).rows(0)("week_id")
                            End If
                        End If
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetTiebreakertext(pool_id As Integer, week_id As Integer) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select tb.*, sched.*, away.team_name as away_team, home.team_name as home_team from fb_tiebreakers tb full outer join fb_sched sched on tb.pool_id=sched.pool_id and tb.game_id=sched.game_id full outer join fb_teams away on away.pool_id=sched.pool_id and away.team_id=sched.away_id full outer join fb_teams home on home.pool_id=sched.pool_id and home.team_id=sched.home_id where tb.pool_id=@pool_id and tb.week_id=@week_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    parm1 = New SQLParameter("@week_id", SQLDbType.int)
                    parm1.value = week_id
                    cmd.parameters.add(parm1)

                    Dim oda As New SQLDataAdapter()
                    Dim ds As New dataset()
                    oda.selectcommand = cmd
                    oda.fill(ds)
                    Try
                        res = ds.tables(0).rows(0)("away_team") & " at " & ds.tables(0).rows(0)("home_team")
                    Catch
                        res = "Tie Breaker Game Not Set"
                    End Try
                End Using

            Catch ex As exception
                makesystemlog("error in gettiebreakertext", ex.tostring())
            End Try

            Return res

        End Function

        Public Function SubmitPicks(r As httprequest, pool_id As Integer, player_name As String) As String

            Try
                Dim p
                For Each p In r.Params
                    If p.tostring().startswith("game_") Then
                        Dim game_id As Integer
                        game_id = p.replace("game_", "")
                        Dim team_id As Integer
                        team_id = r(p)
                        Dim res As String = ""
                        res = updatepick(pool_id:=pool_id, username:=player_name, game_id:=game_id, team_id:=team_id, mod_user:=player_name)
                    End If
                Next
            Catch ex As exception
                makesystemlog("error in submitpicks", ex.tostring())
            End Try
            Try
                If r("tiebreaker") <> "" Then
                    Dim tbvalue As Integer
                    tbvalue = r("tiebreaker")
                    updatetiebreaker(pool_id:=pool_id, week_id:=r("week_id"), username:=player_name, score:=tbvalue, mod_user:=player_name)
                End If
            Catch ex As exception
                makesystemlog("error in submitpicks", ex.tostring())
            End Try
        End Function

        Private Function UpdateTiebreaker(POOL_ID As Integer, USERNAME As String, score As Integer, week_ID As Integer) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "update fb_tiebreaker set SCORE=@score where username=@username and WEEK_ID=@week_id and  pool_id=@pool_id "
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@SCORE", SQLDbType.int))
                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@WEEK_ID").value = WEEK_ID
                    cmd.parameters("@SCORE").value = SCORE
                    cmd.parameters("@POOL_ID").value = POOL_ID

                    Dim rowsaffected As Integer = 0
                    rowsaffected = cmd.executenonquery()

                    If rowsaffected = 0 Then

                        sql = "insert into fb_tiebreaker(USERNAME, WEEK_ID, SCORE, POOL_ID) values (@username, @week_id, @score, @pool_id)"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("username"))
                        cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@SCORE", SQLDbType.int))
                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters("@USERNAME").value = USERNAME
                        cmd.parameters("@WEEK_ID").value = WEEK_ID
                        cmd.parameters("@SCORE").value = SCORE
                        cmd.parameters("@POOL_ID").value = POOL_ID

                        rowsaffected = cmd.executenonquery()

                    End If
                    If rowsaffected > 0 Then
                        res = username
                    Else
                        res = "Failed to update tiebreaker."
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("error updating pick", ex.toString())
            End Try
            Return res
        End Function


        Public Function UpdateTiebreaker(POOL_ID As Integer, USERNAME As String, score As Integer, week_ID As Integer, mod_user As String) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "update fb_tiebreaker set SCORE=@score , mod_user=@mod_user where username=@username and WEEK_ID=@week_id and  pool_id=@pool_id "
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@SCORE", SQLDbType.int))
                    cmd.parameters.add(New SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters("@MOD_USER").value = mod_user
                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@WEEK_ID").value = WEEK_ID
                    cmd.parameters("@SCORE").value = SCORE
                    cmd.parameters("@POOL_ID").value = POOL_ID

                    Dim rowsaffected As Integer = 0
                    rowsaffected = cmd.executenonquery()

                    If rowsaffected = 0 Then

                        sql = "insert into fb_tiebreaker(USERNAME, WEEK_ID, SCORE, POOL_ID, mod_user) values (@username, @week_id, @score, @pool_id, @mod_user)"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("username"))
                        cmd.parameters.add(New SQLParameter("@WEEK_ID", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@SCORE", SQLDbType.int))
                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters.add(New SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
                        cmd.parameters("@MOD_USER").value = mod_user
                        cmd.parameters("@USERNAME").value = USERNAME
                        cmd.parameters("@WEEK_ID").value = WEEK_ID
                        cmd.parameters("@SCORE").value = SCORE
                        cmd.parameters("@POOL_ID").value = POOL_ID

                        rowsaffected = cmd.executenonquery()

                    End If
                    If rowsaffected > 0 Then
                        res = username
                    Else
                        res = "Failed to update tiebreaker."
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("error updating pick", ex.toString())
            End Try
            Return res
        End Function

        Public Function UpdateGameScore(game_id As Integer, away_score As Integer, home_score As Integer, pool_id As Integer, username As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = ""
                    Dim cmd As SQLCommand

                    sql = "select count(*) from fb_scores where away_score=@away_score and home_score=@home_score and game_id=@game_id and pool_id=@pool_id"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@AWAY_SCORE", SQLDbType.int))
                    cmd.parameters.add(New SQLParameter("@HOME_SCORE", SQLDbType.int))
                    cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                    cmd.parameters.add(GetParm("pool_id"))

                    cmd.parameters("@GAME_ID").value = GAME_ID
                    cmd.parameters("@AWAY_SCORE").value = AWAY_SCORE
                    cmd.parameters("@HOME_SCORE").value = HOME_SCORE
                    cmd.parameters("@POOL_ID").value = POOL_ID

                    Dim rowcount As Integer = 0
                    rowcount = cmd.executescalar()

                    If rowcount <> 1 Then

                        sql = "insert into fb_scores_history (away_score, home_score, game_id, pool_id, mod_user, mod_tsp) values (@away_score, @home_score, @game_id, @pool_id, @mod_user, CURRENT_TIMESTAMP)"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("pool_id")).value = pool_id
                        cmd.parameters.add(New SQLParameter("@mod_user", SQLDbType.varchar, 30)).value = username
                        cmd.parameters.add(New SQLParameter("@AWAY_SCORE", SQLDbType.int)).value = away_score
                        cmd.parameters.add(New SQLParameter("@HOME_SCORE", SQLDbType.int)).value = home_score
                        cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int)).value = game_id

                        Dim rowsupdated As Integer = 0

                        rowsupdated = cmd.executenonquery()

                        sql = "update fb_scores set AWAY_SCORE=@away_score, HOME_SCORE=@home_score where game_id=@game_id and pool_id=@pool_id"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(New SQLParameter("@AWAY_SCORE", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@HOME_SCORE", SQLDbType.int))
                        cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                        cmd.parameters.add(GetParm("pool_id"))

                        cmd.parameters("@GAME_ID").value = GAME_ID
                        cmd.parameters("@AWAY_SCORE").value = AWAY_SCORE
                        cmd.parameters("@HOME_SCORE").value = HOME_SCORE
                        cmd.parameters("@POOL_ID").value = POOL_ID

                        rowsupdated = 0

                        rowsupdated = cmd.executenonquery()

                        If rowsupdated > 0 Then
                            res = "SUCCESS"
                        Else
                            sql = "insert into fb_scores(GAME_ID, AWAY_SCORE, HOME_SCORE, pool_id) values (@game_id, @away_score, @home_score, @pool_id)"
                            cmd = New SQLCommand(sql, con)

                            cmd.parameters.add(New SQLParameter("@GAME_ID", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@AWAY_SCORE", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("@HOME_SCORE", SQLDbType.int))
                            cmd.parameters.add(GetParm("pool_id"))

                            cmd.parameters("@GAME_ID").value = GAME_ID
                            cmd.parameters("@AWAY_SCORE").value = AWAY_SCORE
                            cmd.parameters("@HOME_SCORE").value = HOME_SCORE
                            cmd.parameters("@POOL_ID").value = POOL_ID

                            rowsupdated = cmd.executenonquery()
                            If rowsupdated < 1 Then
                                res = "Score was not updated."
                            Else
                                res = "SUCCESS"
                            End If
                        End If
                        updatescoretsp(pool_id)
                    Else
                        res = "SUCCESS"
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetAllPicksForWeek(pool_id As Integer, week_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select a.pool_id, a.game_id, a.username, a.team_id, b.team_shortname as pick_name, c.game_tsp from fb_picks a full outer join fb_teams b on a.team_id=b.team_id and a.pool_id=b.pool_id full outer join fb_sched c on a.game_id=c.game_id and a.pool_id=c.pool_id where a.pool_id=@pool_id and a.game_id in (select game_id from fb_sched where pool_id=@pool_id and week_id=@week_id)"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int)).value = week_id

                    Dim oda As New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using
            Catch ex As exception
                makesystemlog("Error getting pool GetAllPicksForWeek", ex.tostring())
            End Try

            Return res

        End Function

        Public Function GetTiebreaker(pool_id As Integer, week_id As Integer) As String


            Dim res As String = "NOTSET"
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select game_id from fb_tiebreakers where pool_id=@pool_id and week_id=@week_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int)).value = week_id

                    Dim game_id As Integer
                    game_id = cmd.executescalar()
                    res = game_id
                End Using
            Catch ex As exception
                makesystemlog("Error in GetTiebreaker", ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetPlayerTiebreakers(pool_id As Integer, week_id As Integer) As dataset
            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_tiebreaker where pool_id=@pool_id and week_id=@week_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int)).value = week_id

                    Dim oda As New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using

            Catch ex As exception
                makesystemlog("Error in GetPlayerTiebreakers", ex.tostring())
            End Try

            Return res


        End Function

        Public Function ShowThreads() As dataset
            Return New system.data.dataset()
        End Function

        Public Function ShowThreads(count As Integer) As datatable

            Dim temp_table As New system.data.datatable("Threads")
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim temp_col As system.Data.DataColumn
                    Dim temp_row As system.Data.DataRow

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "thread_id"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "thread_title"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "thread_author"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.DateTime")
                    temp_col.ColumnName = "thread_tsp"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)


                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "last_poster"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "replies"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "views"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    Dim sql As String
                    Dim cmd As SQLCommand

                    If count > 0 Then
                        sql = "select top " & count
                    Else
                        sql = "select "
                    End If

                    sql = sql & " comment_id as thread_id, comment_title as thread_title, username as thread_author, " _
                     & " comment_tsp as thread_tsp, username as last_poster, 0 as replies, views " _
                     & " from fb_comments where ref_id is null order by thread_tsp desc"

                    cmd = New SQLCommand(sql, con)

                    Dim dr As SQLDataReader
                    dr = cmd.executereader()
                    While dr.read()

                        temp_row = temp_table.newrow()
                        temp_row("thread_id") = dr("thread_id")
                        temp_row("thread_title") = dr("thread_title")
                        temp_row("thread_author") = dr("thread_author")
                        temp_row("thread_tsp") = dr("thread_tsp")
                        temp_row("last_poster") = dr("last_poster")
                        temp_row("replies") = dr("replies")
                        temp_row("views") = dr("views")

                        temp_table.rows.add(temp_row)

                    End While
                    dr.close()


                    If temp_table.rows.count > 0 Then
                        For i As Integer = 0 To temp_table.rows.count - 1
                            sql = "select count(*) from fb_comments where ref_id=@ref_id"
                            cmd = New SQLCommand(sql, con)
                            cmd.parameters.add(New SQLParameter("@ref_id", SQLDbType.int)).value = temp_table.rows(i)("thread_id")

                            temp_table.rows(i)("replies") = cmd.executescalar()

                            sql = "select * from fb_comments where (comment_id=@ref_id or ref_id=@ref_id) order by comment_tsp desc"
                            cmd = New SQLCommand(sql, con)
                            cmd.parameters.add(New SQLParameter("@ref_id", SQLDbType.int)).value = temp_table.rows(i)("thread_id")

                            dr = cmd.executereader()
                            If dr.read() Then
                                temp_table.rows(i)("thread_tsp") = dr("comment_tsp")
                                temp_table.rows(i)("last_poster") = dr("username")
                            End If
                            dr.close()
                        Next
                    End If
                End Using

            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return temp_table
        End Function

        Public Function GetComments(pool_id As Integer, thread_id As Integer, count As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    If count <= 0 Then
                        count = 1000000
                    End If

                    sql = "select top " & count & " a.pool_id, a.username, a.comment_text, a.comment_tsp, a.comment_id, a.ref_id, a.comment_title, a.views, b.nickname from fb_comments a full outer join fb_players b on a.pool_id=b.pool_id and a.username=b.username where (a.comment_id=@comment_id or a.ref_id=@comment_id) order by comment_tsp asc"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(New SQLParameter("@comment_id", SQLDbType.int)).value = thread_id

                    Dim oda As New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res

        End Function

        Public Function GetScoresForWeek(pool_id As Integer, week_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select a.game_id, a.away_score, a.home_score from fb_scores a full outer join fb_sched b on a.pool_id=b.pool_id where a.pool_id=@pool_id and b.week_id=@week_id"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int)).value = week_id

                    Dim oda As New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res

        End Function

        Public Function GetWeeklyStats(pool_id As Integer) As dataset
            Dim temp_ds As New system.Data.DataSet()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = ""
                    Dim cmd As SQLCommand
                    Dim oda As System.Data.SQLClient.SQLDataAdapter

                    sql = "select t.pool_id, t.username, t.nickname, t.game_id, t.away_score, t.home_score, c.team_id, d.week_id, d.home_id, d.away_id from (select a.pool_id, a.username, a.nickname, b.game_id, b.away_score, b.home_score from fb_players a , fb_scores b where a.pool_id=@pool_id and a.pool_id =b.pool_id and not b.away_score is null) as t full outer join fb_picks c on t.pool_id=c.pool_id and t.game_id=c.game_id and t.username=c.username full outer join fb_sched d on d.pool_id=t.pool_id and d.game_id=t.game_id where (c.pool_id=@pool_id or c.pool_id is null) and not t.away_score is null order by t.username, d.week_id"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    oda = New SQLDataAdapter()
                    oda.selectcommand = cmd
                    Dim ds As New dataset()
                    oda.fill(ds)

                    Dim temp_table As New system.Data.DataTable("Weekly_Stats")

                    Dim temp_col As system.Data.DataColumn
                    Dim temp_row As system.Data.DataRow

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "username"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "nickname"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "week_id"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "wins"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "losses"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "home_picks"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "away_picks"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Double")
                    temp_col.ColumnName = "win_pct"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Double")
                    temp_col.ColumnName = "home_picks_pct"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Double")
                    temp_col.ColumnName = "away_picks_pct"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Double")
                    temp_col.ColumnName = "performance_pct"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    Dim players_ds As New dataset()
                    players_ds = getplayers(pool_id)
                    Dim weeks_ds As New dataset()
                    weeks_ds = listweeks(pool_id)

                    For Each player_row As datarow In players_ds.tables(0).rows
                        For Each week_id_row As datarow In weeks_ds.tables(0).rows

                            Dim temprows As datarow()
                            temprows = ds.tables(0).select("username='" & player_row("username") & "' and week_id=" & week_id_row("week_id"))
                            If temprows.length > 0 Then
                                temp_row = temp_table.newrow()
                                temp_row("week_id") = week_id_row("week_id")
                                temp_row("wins") = 0
                                temp_row("losses") = 0
                                temp_row("win_pct") = 0
                                temp_row("home_picks") = 0
                                temp_row("away_picks") = 0
                                temp_row("home_picks_pct") = 0
                                temp_row("away_picks_pct") = 0
                                temp_row("performance_pct") = 0
                                temp_row("username") = player_row("username")
                                temp_row("nickname") = player_row("nickname")

                                For Each drow As datarow In temprows
                                    If drow("team_id") Is dbnull.value Then
                                        temp_row("losses") = temp_row("losses") + 1
                                    Else
                                        If drow("away_id") = drow("team_id") Then
                                            temp_row("away_picks") = temp_row("away_picks") + 1
                                            If drow("away_score") > drow("home_score") Then
                                                temp_row("wins") = temp_row("wins") + 1
                                            Else
                                                temp_row("losses") = temp_row("losses") + 1
                                            End If
                                        End If
                                        If drow("home_id") = drow("team_id") Then
                                            temp_row("home_picks") = temp_row("home_picks") + 1
                                            If drow("home_score") > drow("away_score") Then
                                                temp_row("wins") = temp_row("wins") + 1
                                            Else
                                                temp_row("losses") = temp_row("losses") + 1
                                            End If
                                        End If
                                    End If
                                Next
                                temp_table.rows.add(temp_row)
                            End If
                        Next
                    Next
                    For i As Integer = 0 To temp_table.rows.count - 1
                        With temp_table.rows(i)

                            .item("win_pct") = system.convert.todouble(.item("wins")) / system.convert.todouble(.item("wins") + .item("losses"))
                            .item("home_picks_pct") = 1.0 * .item("home_picks") / .item("home_picks") + .item("away_picks")
                            .item("away_picks_pct") = 1.0 * .item("away_picks") / .item("home_picks") + .item("away_picks")
                        End With
                    Next
                    temp_ds.tables.add(temp_table)
                End Using
            Catch ex As exception
                makesystemlog("error", ex.tostring())
            End Try

            Return temp_ds
        End Function

        Public Function GetStandingsForWeek(pool_id As Integer, week_id As Integer) As dataset

            Dim temp_ds As New system.Data.DataSet()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = ""
                    Dim cmd As SQLCommand
                    Dim oda As System.Data.SQLClient.SQLDataAdapter

                    Dim temp_table As New system.Data.DataTable("Scores")

                    Dim temp_col As system.Data.DataColumn
                    Dim temp_row As system.Data.DataRow

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "username"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "nickname"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "wins"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "losses"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "home"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "away"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "weekwins"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "lwp"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "totalscore"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "rank"
                    temp_col.ReadOnly = False
                    temp_table.Columns.Add(temp_col)


                    ' table for keeping track of the weekly scores
                    Dim week_table As New system.Data.DataTable("Weeks")
                    Dim tempweek_row As system.Data.DataRow


                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.String")
                    temp_col.ColumnName = "username"
                    temp_col.ReadOnly = False
                    week_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "week_id"
                    temp_col.ReadOnly = False
                    week_table.Columns.Add(temp_col)

                    temp_col = New system.Data.DataColumn()
                    temp_col.DataType = system.Type.GetType("System.Int32")
                    temp_col.ColumnName = "score"
                    temp_col.ReadOnly = False
                    week_table.Columns.Add(temp_col)


                    Dim picks_ds As New dataset()

                    sql = "select t.pool_id, t.username, t.nickname, t.game_id, t.away_score, t.home_score, c.team_id, d.week_id, d.home_id, d.away_id from (select a.pool_id, a.username, a.nickname, b.game_id, b.away_score, b.home_score from fb_players a , fb_scores b where a.pool_id=@pool_id and b.pool_id=@pool_id and not b.away_score is null) as t full outer join fb_picks c on t.pool_id=c.pool_id and t.game_id=c.game_id and t.username=c.username full outer join fb_sched d on d.pool_id=t.pool_id and d.game_id=t.game_id where (c.pool_id=@pool_id or c.pool_id is null) and not d.away_id is null and d.week_id <=@week_id and not d.home_id is null and not t.away_score is null order by t.username, d.week_id"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(New SQLParameter("@POOL_ID2", SQLDbType.int))
                    cmd.parameters.add(New SQLParameter("@POOL_ID3", SQLDbType.int))
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int))
                    cmd.parameters("@POOL_ID").value = pool_id
                    cmd.parameters("@POOL_ID2").value = pool_id
                    cmd.parameters("@POOL_ID3").value = pool_id
                    cmd.parameters("@week_id").value = week_id

                    oda = New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.fill(picks_ds)

                    Dim options_ht As New system.collections.hashtable()
                    options_ht = getPoolOptions(pool_id:=pool_id)

                    Dim weeks_ds As dataset
                    weeks_ds = listweeks(pool_id:=pool_id)

                    Dim players_ds As New dataset()
                    players_ds = getpoolplayers(pool_id:=pool_id)

                    For Each player_row As datarow In players_ds.Tables(0).rows

                        temp_row = temp_table.newrow()
                        temp_row("wins") = 0
                        temp_row("losses") = 0
                        temp_row("totalscore") = 0
                        temp_row("home") = 0
                        temp_row("away") = 0
                        temp_row("lwp") = 0
                        temp_row("weekwins") = 0
                        temp_row("username") = player_row("username")
                        temp_row("nickname") = player_row("nickname")
                        temp_table.rows.add(temp_row)

                        For Each week_id_row As datarow In weeks_ds.Tables(0).rows
                            tempweek_row = week_table.NewRow()
                            tempweek_row("username") = player_row("username")
                            tempweek_row("score") = 0
                            tempweek_row("week_id") = week_id_row("week_id")
                            week_table.rows.add(tempweek_row)
                        Next
                    Next

                    Dim players_ht As New system.Collections.Hashtable()
                    For i As Integer = 0 To temp_table.Rows.Count - 1
                        players_ht.Add(temp_table.Rows(i)("username"), i)
                    Next

                    For Each drow As datarow In picks_ds.tables(0).rows
                        Dim player_idx As Integer = players_ht(drow("username"))

                        If drow("team_id") Is dbnull.Value Then
                            If options_ht("AUTOHOMEPICKS") = "on" And drow("away_score") < drow("home_score") Then
                                temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1
                            Else
                                temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                            End If
                        Else
                            If drow("team_id") = drow("away_id") Then
                                temp_table.Rows(player_idx)("away") = temp_table.Rows(player_idx)("away") + 1
                            End If
                            If drow("team_id") = drow("home_id") Then
                                temp_table.Rows(player_idx)("home") = temp_table.Rows(player_idx)("home") + 1
                            End If

                            If drow("away_score") = drow("home_score") Then
                                temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                            Else
                                If drow("away_score") > drow("home_score") Then
                                    If drow("team_id") = drow("away_id") Then
                                        temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1

                                        For i As Integer = 0 To week_table.rows.Count - 1
                                            If week_table.Rows(i)("username") = drow("username") And week_table.Rows(i)("week_id") = drow("week_id") Then
                                                week_table.Rows(i)("score") = week_table.Rows(i)("score") + 1
                                            End If
                                        Next


                                        Dim lwp_rows As datarow()
                                        lwp_rows = picks_ds.tables(0).Select("team_id=" & drow("team_id") & " and game_id=" & drow("game_id"))
                                        If lwp_rows.length = 1 Then
                                            temp_table.Rows(player_idx)("lwp") = temp_table.Rows(player_idx)("lwp") + 1
                                        End If
                                    Else
                                        temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                                    End If
                                End If
                                If drow("away_score") < drow("home_score") Then
                                    If drow("team_id") = drow("home_id") Then
                                        temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1

                                        For i As Integer = 0 To week_table.rows.Count - 1
                                            If week_table.Rows(i)("username") = drow("username") And week_table.Rows(i)("week_id") = drow("week_id") Then
                                                week_table.Rows(i)("score") = week_table.Rows(i)("score") + 1
                                            End If
                                        Next

                                        Dim lwp_rows As datarow()
                                        lwp_rows = picks_ds.tables(0).Select("team_id=" & drow("team_id") & " and game_id=" & drow("game_id"))
                                        If lwp_rows.length = 1 Then
                                            temp_table.Rows(player_idx)("lwp") = temp_table.Rows(player_idx)("lwp") + 1
                                        End If
                                    Else
                                        temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                                    End If
                                End If
                            End If
                        End If
                    Next 'drow

                    If options_ht("WINWEEKPOINT") = "on" Then

                        For Each week_id_row As datarow In weeks_ds.Tables(0).rows
                            Dim score_rows As datarow()
                            score_rows = week_table.Select("week_id=" & week_id_row("week_id"), "score desc")
                            Dim highscore As Integer = 0
                            For Each drow As datarow In score_rows
                                If highscore < drow("score") Then
                                    highscore = drow("score")
                                End If
                            Next
                            'makesystemlog("test: highscore", "week_id=" & week_id_row("week_id") & " highscore=" & highscore)
                            If highscore > 0 Then
                                score_rows = week_table.Select("week_id=" & week_id_row("week_id") & " and score=" & highscore, "username asc")
                                If score_rows.length = 1 Then
                                    For Each drow As datarow In score_rows
                                        temp_table.Rows(players_ht(drow("username")))("weekwins") = temp_table.Rows(players_ht(drow("username")))("weekwins") + 1
                                    Next
                                Else
                                    ' more than one player got the same high score
                                    ' have to use the tie breaker
                                    ' damn it
                                    Dim tiebreaker_picks_ds As New DataSet()
                                    tiebreaker_picks_ds = GetPlayerTiebreakers(pool_id:=pool_id, week_id:=week_id_row("week_id"))
                                    Dim scoresforweek_ds As New DataSet()
                                    scoresforweek_ds = getscoresforweek(pool_id:=pool_id, week_id:=week_id_row("week_id"))

                                    Dim highscoreusers As New system.Collections.Hashtable()

                                    For Each drow As datarow In score_rows
                                        Dim playertbrows As datarow()
                                        playertbrows = tiebreaker_picks_ds.tables(0).Select("username='" & drow("username") & "'")
                                        If playertbrows.length > 0 Then
                                            highscoreusers.add(playertbrows(0)("username"), playertbrows(0)("score"))
                                        End If
                                    Next

                                    Dim bestscore As Integer = 0
                                    Dim allscoresforweek As datarow()
                                    Try
                                        allscoresforweek = scoresforweek_ds.tables(0).Select("game_id=" & gettiebreaker(pool_id:=pool_id, week_id:=week_id_row("week_id")))
                                        If allscoresforweek.length > 0 Then
                                            bestscore = allscoresforweek(0)("away_score") + allscoresforweek(0)("home_score")
                                        End If
                                    Catch
                                    End Try

                                    Dim lower As New system.Collections.Hashtable()
                                    Dim higher As New system.Collections.Hashtable()

                                    If bestscore > 0 Then
                                        For Each k As Object In highscoreusers.keys
                                            If highscoreusers(k) <= bestscore Then
                                                lower.add(k, highscoreusers(k))
                                            Else
                                                higher.add(k, highscoreusers(k))
                                            End If
                                        Next
                                        If lower.count > 0 Then
                                            Dim check_score As Integer = 0
                                            For Each k As Object In lower.keys
                                                If lower(k) > check_score Then
                                                    check_score = lower(k)
                                                End If
                                            Next
                                            For Each k As Object In lower.keys
                                                If lower(k) = check_score Then
                                                    temp_table.Rows(players_ht(k))("weekwins") = temp_table.Rows(players_ht(k))("weekwins") + 1
                                                End If
                                            Next
                                        Else

                                            Dim check_score As Integer = 100000
                                            For Each k As Object In higher.keys
                                                If higher(k) < check_score Then
                                                    check_score = higher(k)
                                                End If
                                            Next
                                            For Each k As Object In higher.keys
                                                If higher(k) = check_score Then
                                                    temp_table.Rows(players_ht(k))("weekwins") = temp_table.Rows(players_ht(k))("weekwins") + 1
                                                End If
                                            Next
                                        End If
                                    End If
                                End If
                            End If
                        Next


                    End If

                    For i As Integer = 0 To temp_table.Rows.Count - 1
                        temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("wins")
                        If options_ht("LONEWOLFEPICK") = "on" Then
                            temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("totalscore") + temp_table.Rows(i)("lwp")
                        End If
                        If options_ht("WINWEEKPOINT") = "on" Then
                            temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("totalscore") + temp_table.Rows(i)("weekwins")
                        End If
                    Next

                    Dim ranked_rows As datarow()

                    ranked_rows = temp_table.select("1=1", "totalscore desc")
                    Dim top_score As Integer = 0
                    Try
                        top_score = ranked_rows(0)("totalscore")
                    Catch ex As exception
                        makesystemlog("error getting top_score", ex.tostring())
                    End Try

                    For i As Integer = 0 To temp_table.rows.count - 1
                        temp_table.rows(i)("rank") = top_score - temp_table.rows(i)("totalscore")
                    Next
                    temp_ds.tables.add(temp_table)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return temp_ds


        End Function

        Public Function isInteger(s As String) As Boolean
            Dim rx As New Regex("^-?\d+$")
            Return rx.IsMatch(s)
        End Function


        Public Function GetStandings(pool_id As Integer) As dataset

            Dim temp_ds As New system.Data.DataSet()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = ""
                    Dim cmd As SQLCommand
                    Dim oda As System.Data.SQLClient.SQLDataAdapter

                    sql = "select count(*) from fb_pools where pool_id=@pool_id and (updatescore_tsp > standings_tsp or standings_tsp is null)"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    Dim c As Integer = 0
                    c = cmd.executescalar()

                    If c > 0 Then

                        Dim temp_table As New system.Data.DataTable("Scores")

                        Dim temp_col As system.Data.DataColumn
                        Dim temp_row As system.Data.DataRow

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.String")
                        temp_col.ColumnName = "username"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.String")
                        temp_col.ColumnName = "nickname"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "wins"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "losses"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "home"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "away"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "weekwins"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "lwp"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "totalscore"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "rank"
                        temp_col.ReadOnly = False
                        temp_table.Columns.Add(temp_col)


                        ' table for keeping track of the weekly scores
                        Dim week_table As New system.Data.DataTable("Weeks")
                        Dim tempweek_row As system.Data.DataRow


                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.String")
                        temp_col.ColumnName = "username"
                        temp_col.ReadOnly = False
                        week_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "week_id"
                        temp_col.ReadOnly = False
                        week_table.Columns.Add(temp_col)

                        temp_col = New system.Data.DataColumn()
                        temp_col.DataType = system.Type.GetType("System.Int32")
                        temp_col.ColumnName = "score"
                        temp_col.ReadOnly = False
                        week_table.Columns.Add(temp_col)




                        Dim picks_ds As New dataset()

                        sql = "select t.pool_id, t.username, t.nickname, t.game_id, t.away_score, t.home_score, c.team_id, d.week_id, d.home_id, d.away_id from (select a.pool_id, a.username, a.nickname, b.game_id, b.away_score, b.home_score from fb_players a , fb_scores b where a.pool_id=@pool_id and b.pool_id=@pool_id and not b.away_score is null) as t full outer join fb_picks c on t.pool_id=c.pool_id and t.game_id=c.game_id and t.username=c.username full outer join fb_sched d on d.pool_id=t.pool_id and d.game_id=t.game_id where (c.pool_id=@pool_id or c.pool_id is null) and not d.away_id is null and not d.home_id is null and not t.away_score is null order by t.username, d.week_id"
                        cmd = New SQLCommand(sql, con)
                        cmd.parameters.add(GetParm("pool_id")).value = pool_id

                        oda = New SQLDataAdapter()
                        oda.SelectCommand = cmd
                        oda.fill(picks_ds)

                        Dim options_ht As New system.collections.hashtable()
                        options_ht = getPoolOptions(pool_id:=pool_id)

                        Dim weeks_ds As dataset
                        weeks_ds = listweeks(pool_id:=pool_id)

                        Dim players_ds As New dataset()
                        players_ds = getpoolplayers(pool_id:=pool_id)

                        For Each player_row As datarow In players_ds.Tables(0).rows

                            temp_row = temp_table.newrow()
                            temp_row("wins") = 0
                            temp_row("losses") = 0
                            temp_row("totalscore") = 0
                            temp_row("home") = 0
                            temp_row("away") = 0
                            temp_row("lwp") = 0
                            temp_row("weekwins") = 0
                            temp_row("username") = player_row("username")
                            temp_row("nickname") = player_row("nickname")
                            temp_table.rows.add(temp_row)

                            For Each week_id_row As datarow In weeks_ds.Tables(0).rows
                                tempweek_row = week_table.NewRow()
                                tempweek_row("username") = player_row("username")
                                tempweek_row("score") = 0
                                tempweek_row("week_id") = week_id_row("week_id")
                                week_table.rows.add(tempweek_row)
                            Next
                        Next

                        Dim players_ht As New system.Collections.Hashtable()
                        For i As Integer = 0 To temp_table.Rows.Count - 1
                            players_ht.Add(temp_table.Rows(i)("username"), i)
                        Next

                        For Each drow As datarow In picks_ds.tables(0).rows
                            Dim player_idx As Integer = players_ht(drow("username"))

                            If drow("team_id") Is dbnull.Value Then
                                If options_ht("AUTOHOMEPICKS") = "on" And drow("away_score") < drow("home_score") Then
                                    temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1
                                Else
                                    temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                                End If
                            Else
                                If drow("team_id") = drow("away_id") Then
                                    temp_table.Rows(player_idx)("away") = temp_table.Rows(player_idx)("away") + 1
                                End If
                                If drow("team_id") = drow("home_id") Then
                                    temp_table.Rows(player_idx)("home") = temp_table.Rows(player_idx)("home") + 1
                                End If

                                If drow("away_score") = drow("home_score") Then
                                    temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                                Else
                                    If drow("away_score") > drow("home_score") Then
                                        If drow("team_id") = drow("away_id") Then
                                            temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1

                                            For i As Integer = 0 To week_table.rows.Count - 1
                                                If week_table.Rows(i)("username") = drow("username") And week_table.Rows(i)("week_id") = drow("week_id") Then
                                                    week_table.Rows(i)("score") = week_table.Rows(i)("score") + 1
                                                End If
                                            Next


                                            Dim lwp_rows As datarow()
                                            lwp_rows = picks_ds.tables(0).Select("team_id=" & drow("team_id") & " and game_id=" & drow("game_id"))
                                            If lwp_rows.length = 1 Then
                                                temp_table.Rows(player_idx)("lwp") = temp_table.Rows(player_idx)("lwp") + 1
                                            End If
                                        Else
                                            temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                                        End If
                                    End If
                                    If drow("away_score") < drow("home_score") Then
                                        If drow("team_id") = drow("home_id") Then
                                            temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1

                                            For i As Integer = 0 To week_table.rows.Count - 1
                                                If week_table.Rows(i)("username") = drow("username") And week_table.Rows(i)("week_id") = drow("week_id") Then
                                                    week_table.Rows(i)("score") = week_table.Rows(i)("score") + 1
                                                End If
                                            Next

                                            Dim lwp_rows As datarow()
                                            lwp_rows = picks_ds.tables(0).Select("team_id=" & drow("team_id") & " and game_id=" & drow("game_id"))
                                            If lwp_rows.length = 1 Then
                                                temp_table.Rows(player_idx)("lwp") = temp_table.Rows(player_idx)("lwp") + 1
                                            End If
                                        Else
                                            temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1
                                        End If
                                    End If
                                End If
                            End If
                        Next 'drow

                        If options_ht("WINWEEKPOINT") = "on" Then

                            For Each week_id_row As datarow In weeks_ds.Tables(0).rows
                                Dim score_rows As datarow()
                                score_rows = week_table.Select("week_id=" & week_id_row("week_id"), "score desc")
                                Dim highscore As Integer = 0
                                For Each drow As datarow In score_rows
                                    If highscore < drow("score") Then
                                        highscore = drow("score")
                                    End If
                                Next
                                'makesystemlog("test: highscore", "week_id=" & week_id_row("week_id") & " highscore=" & highscore)
                                If highscore > 0 Then
                                    score_rows = week_table.Select("week_id=" & week_id_row("week_id") & " and score=" & highscore, "username asc")
                                    If score_rows.length = 1 Then
                                        For Each drow As datarow In score_rows
                                            temp_table.Rows(players_ht(drow("username")))("weekwins") = temp_table.Rows(players_ht(drow("username")))("weekwins") + 1
                                        Next
                                    Else
                                        ' more than one player got the same high score
                                        ' have to use the tie breaker
                                        ' damn it
                                        Dim tiebreaker_picks_ds As New DataSet()
                                        tiebreaker_picks_ds = GetPlayerTiebreakers(pool_id:=pool_id, week_id:=week_id_row("week_id"))
                                        Dim scoresforweek_ds As New DataSet()
                                        scoresforweek_ds = getscoresforweek(pool_id:=pool_id, week_id:=week_id_row("week_id"))

                                        Dim highscoreusers As New system.Collections.Hashtable()

                                        For Each drow As datarow In score_rows
                                            Dim playertbrows As datarow()
                                            playertbrows = tiebreaker_picks_ds.tables(0).Select("username='" & drow("username") & "'")
                                            If playertbrows.length > 0 Then
                                                highscoreusers.add(playertbrows(0)("username"), playertbrows(0)("score"))
                                            End If
                                        Next

                                        Dim bestscore As Integer = 0
                                        Dim allscoresforweek As datarow()
                                        Try
                                            allscoresforweek = scoresforweek_ds.tables(0).Select("game_id=" & gettiebreaker(pool_id:=pool_id, week_id:=week_id_row("week_id")))
                                            If allscoresforweek.length > 0 Then
                                                bestscore = allscoresforweek(0)("away_score") + allscoresforweek(0)("home_score")
                                            End If
                                        Catch
                                        End Try

                                        Dim lower As New system.Collections.Hashtable()
                                        Dim higher As New system.Collections.Hashtable()

                                        If bestscore > 0 Then
                                            For Each k As Object In highscoreusers.keys
                                                If highscoreusers(k) <= bestscore Then
                                                    lower.add(k, highscoreusers(k))
                                                Else
                                                    higher.add(k, highscoreusers(k))
                                                End If
                                            Next
                                            If lower.count > 0 Then
                                                Dim check_score As Integer = 0
                                                For Each k As Object In lower.keys
                                                    If lower(k) > check_score Then
                                                        check_score = lower(k)
                                                    End If
                                                Next
                                                For Each k As Object In lower.keys
                                                    If lower(k) = check_score Then
                                                        temp_table.Rows(players_ht(k))("weekwins") = temp_table.Rows(players_ht(k))("weekwins") + 1
                                                    End If
                                                Next
                                            Else

                                                Dim check_score As Integer = 100000
                                                For Each k As Object In higher.keys
                                                    If higher(k) < check_score Then
                                                        check_score = higher(k)
                                                    End If
                                                Next
                                                For Each k As Object In higher.keys
                                                    If higher(k) = check_score Then
                                                        temp_table.Rows(players_ht(k))("weekwins") = temp_table.Rows(players_ht(k))("weekwins") + 1
                                                    End If
                                                Next
                                            End If
                                        End If
                                    End If
                                End If
                            Next


                        End If

                        For i As Integer = 0 To temp_table.Rows.Count - 1
                            temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("wins")
                            If options_ht("LONEWOLFEPICK") = "on" Then
                                temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("totalscore") + temp_table.Rows(i)("lwp")
                            End If
                            If options_ht("WINWEEKPOINT") = "on" Then
                                temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("totalscore") + temp_table.Rows(i)("weekwins")
                            End If
                        Next


                        temp_ds.tables.add(temp_table)
                        sql = "delete from fb_standings where pool_id=@pool_id"
                        cmd = New SQLCommand(sql, con)
                        cmd.parameters.add(New SQLParameter("pool_id", SQLDbType.int))
                        cmd.parameters("pool_id").value = pool_id
                        cmd.executenonquery()

                        Dim ranked_rows As datarow()

                        ranked_rows = temp_table.select("1=1", "totalscore desc")
                        Dim top_score As Integer = 0
                        Try
                            top_score = ranked_rows(0)("totalscore")
                        Catch ex As exception
                            makesystemlog("error getting top_score", ex.tostring())
                        End Try

                        For Each inrow As datarow In ranked_rows
                            Dim current_rank As Integer = top_score - inrow("totalscore")

                            sql = "insert into fb_standings (pool_id, username, wins, losses, home, away, weekwins, lwp, totalscore, rank) values (@pool_id, @username, @wins, @losses, @home, @away, @weekwins, @lwp, @totalscore, @rank)"
                            cmd = New SQLCommand(sql, con)

                            cmd.parameters.add(New SQLParameter("pool_id", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("username", SQLDbType.varchar, 50))
                            cmd.parameters.add(New SQLParameter("wins", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("losses", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("home", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("away", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("weekwins", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("lwp", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("totalscore", SQLDbType.int))
                            cmd.parameters.add(New SQLParameter("rank", SQLDbType.int))

                            cmd.parameters("pool_id").value = pool_id
                            cmd.parameters("username").value = inrow("username")
                            cmd.parameters("wins").value = inrow("wins")
                            cmd.parameters("losses").value = inrow("losses")
                            cmd.parameters("home").value = inrow("home")
                            cmd.parameters("away").value = inrow("away")
                            cmd.parameters("weekwins").value = inrow("weekwins")
                            cmd.parameters("lwp").value = inrow("lwp")
                            cmd.parameters("totalscore").value = inrow("totalscore")
                            cmd.parameters("rank").value = current_rank

                            cmd.executenonquery()

                        Next

                        sql = "update fb_pools set standings_tsp = CURRENT_TIMESTAMP where pool_id=@pool_id"
                        cmd = New SQLCommand(sql, con)
                        cmd.parameters.add(New SQLParameter("pool_id", SQLDbType.int))
                        cmd.parameters("pool_id").value = pool_id
                        cmd.executenonquery()

                    End If
                    sql = "select a.*, b.nickname from fb_standings a full outer join fb_players b on a.pool_id=b.pool_id and a.username=b.username where a.pool_id=@pool_id"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(New SQLParameter("pool_id", SQLDbType.int)).value = pool_id

                    oda = New SQLDataAdapter()
                    oda.selectcommand = cmd
                    temp_ds = New dataset()
                    oda.fill(temp_ds)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return temp_ds

        End Function

        Public Function GetPlayerScoresForWeek(pool_id As Integer, week_id As Integer) As dataset


            Dim temp_ds As New system.Data.DataSet()
            Try
                Dim temp_table As New system.Data.DataTable("Picks")
                Dim temp_col As system.Data.DataColumn
                Dim temp_row As system.Data.DataRow

                temp_col = New system.Data.DataColumn()
                temp_col.DataType = system.Type.GetType("System.String")
                temp_col.ColumnName = "username"
                temp_col.ReadOnly = False
                temp_table.Columns.Add(temp_col)

                temp_col = New system.Data.DataColumn()
                temp_col.DataType = system.Type.GetType("System.String")
                temp_col.ColumnName = "nickname"
                temp_col.ReadOnly = False
                temp_table.Columns.Add(temp_col)

                temp_col = New system.Data.DataColumn()
                temp_col.DataType = system.Type.GetType("System.Int32")
                temp_col.ColumnName = "score"
                temp_col.ReadOnly = False
                temp_table.Columns.Add(temp_col)

                Dim games_ds As New dataset()
                games_ds = GetGamesForWeek(pool_id:=pool_id, week_id:=week_id)

                Dim players_ds As New dataset()
                players_ds = getplayers(pool_id:=pool_id)

                Dim picks_ds As New dataset()
                picks_ds = GetAllPicksForWeek(pool_id:=pool_id, week_id:=week_id)

                Dim scores_ds As New dataset()
                scores_ds = GetScoresForWeek(pool_id:=pool_id, week_id:=week_id)

                For Each pdrow As datarow In players_ds.tables(0).rows

                    temp_row = temp_table.newrow()
                    temp_row("score") = 0
                    temp_row("username") = pdrow("username")
                    temp_row("nickname") = pdrow("nickname")

                    For Each gdrow As datarow In games_ds.tables(0).rows

                        Dim pick_name As String = ""

                        Dim temprows As datarow()
                        temprows = picks_ds.tables(0).select("game_id=" & gdrow("game_id") & " and username='" & pdrow("username") & "'")
                        If temprows.length > 0 Then
                            pick_name = temprows(0)("pick_name")
                        Else
                            pick_name = "NP"
                        End If
                        temprows = scores_ds.tables(0).select("game_id='" & gdrow("game_id") & "'")
                        If temprows.length > 0 Then
                            If temprows(0)("away_score") > temprows(0)("home_score") Then
                                If pick_name = gdrow("away_shortname") Then
                                    temp_row("score") = temp_row("score") + 1
                                    'makesystemlog("debug playerscores", "player=" & pdrow("username") & " - pick_name=" & pick_name & " - awayshortname=" & gdrow("away_shortname"))

                                End If
                            ElseIf temprows(0)("away_score") < temprows(0)("home_score") Then
                                If pick_name = gdrow("home_shortname") Then
                                    temp_row("score") = temp_row("score") + 1
                                    'makesystemlog("debug playerscores", "player=" & pdrow("username") & " - pick_name=" & pick_name & " - homeshortname=" & gdrow("home_shortname"))
                                End If
                            End If
                        End If

                    Next 'gdrow
                    temp_table.rows.add(temp_row)
                Next 'pdrow

                temp_ds.tables.add(temp_table)

                'temp_ds.WriteXml (savefiledialog1.FileName)
            Catch ex As exception
                makesystemlog("Error in GetPlayerScoresForWeek", ex.tostring())
            End Try

            Return temp_ds

        End Function

        Public Function GetPicksForWeek(pool_id As Integer, week_id As Integer, player_name As String) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select * from fb_picks  where pool_id=@pool_id and username=@username and game_id in (select game_id from fb_sched where pool_id=@pool_id and week_id=@week_id)"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(GetParm("username")).value = player_name
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int)).value = week_id

                    Dim oda As New SQLDataAdapter()
                    oda.SelectCommand = cmd
                    oda.Fill(res)
                End Using
            Catch ex As exception
                makesystemlog("Error getting pool picksforweek", ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetPick(pool_id As Integer, game_id As Integer, player_name As String) As Integer

            Dim res As Integer = 0
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select team_id from fb_picks  where pool_id=@pool_id and username=@username and game_id=@game_id"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@game_id", SQLDbType.int)).value = game_id
                    cmd.parameters.add(GetParm("username")).value = player_name
                    res = cmd.executescalar()
                End Using
            Catch ex As exception
                makesystemlog("Error in GetPick", ex.tostring())
            End Try

            Return res
        End Function


        Public Function gettiebreakervalue(pool_id As Integer, week_id As Integer, player_name As String) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select score from fb_tiebreaker  where pool_id=@pool_id and week_id=@week_id and username=@username"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@week_id", SQLDbType.int)).value = week_id
                    cmd.parameters.add(GetParm("username")).value = player_name

                    Dim oda As New SQLDataAdapter()
                    Dim ds As New dataset()
                    oda.selectcommand = cmd
                    oda.fill(ds)
                    Try
                        res = ds.tables(0).rows(0)("score")
                    Catch
                        res = ""
                    End Try
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res

        End Function


        Public Function GetMyPools(player_name As String) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_pools where pool_owner=@pool_owner or pool_id in (select pool_id from fb_players where username=@player_name)"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_owner")).value = player_name
                    cmd.parameters.add(New SQLParameter("@player_name", SQLDbType.varchar, 50)).value = player_name

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetImportGames() As dataset
            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select a.*, b.team_name as home_team, c.team_name as away_team from fb_copy_scheds a left join fb_copy_teams b on a.home_id=b.team_id left join fb_copy_teams c on a.away_id=c.team_id order by game_tsp asc"
                    cmd = New SQLCommand(sql, con)

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetImportPreviousTeams(pool_owner As String) As dataset
            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    sql = "select distinct team_name, team_shortname from fb_teams where pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner) order by team_name"
                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_owner")).value = pool_owner
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function


        Public Function GetImportTeams() As dataset
            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    sql = "select distinct team_name, team_shortname from fb_copy_teams order by team_name"
                    cmd = New SQLCommand(sql, con)
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function GetSchedule(pool_id As Integer) As dataset

            Dim res As New system.data.dataset()
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from fb_sched sched full outer join fb_teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join fb_teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.pool_id in (select pool_id from fb_pools where pool_id=@pool_id) order by sched.game_tsp"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(res)
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function validateEmail(key As String, username As String) As Boolean
            Dim res As Boolean = False
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_users where username=@username and validate_key=@validate_key"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("username"))
                    cmd.parameters.add(New SQLParameter("@validate_key", SQLDbType.VARCHAR, 50))

                    cmd.parameters("@username").value = username
                    cmd.parameters("@validate_key").value = key

                    Dim invites_ds As New dataset()
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(invites_ds)
                    If invites_ds.tables(0).rows.count > 0 Then
                        sql = "update fb_users set validated='Y', validate_key='' where username=@username"
                        cmd = New SQLCommand(sql, con)
                        cmd.parameters.add(GetParm("username")).value = username
                        cmd.executenonQuery()

                        res = True
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function validatekey(invite_key As String, email As String, pool_id As Integer) As Boolean
            Dim res As Boolean = False

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand
                    Dim parm1 As SQLParameter

                    sql = "select * from fb_invites where email=@email and pool_id=@pool_id and invite_key=@invite_key"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("email"))
                    cmd.parameters.add(GetParm("pool_id"))
                    cmd.parameters.add(New SQLParameter("@INVITE_KEY", SQLDbType.VARCHAR, 40))

                    cmd.parameters("@POOL_ID").value = POOL_ID
                    cmd.parameters("@EMAIL").value = EMAIL
                    cmd.parameters("@INVITE_KEY").value = INVITE_KEY

                    Dim invites_ds As New dataset()
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(invites_ds)
                    If invites_ds.tables(0).rows.count > 0 Then
                        res = True
                    End If
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function AcceptInvitation(invite_key As String, email As String, pool_id As Integer, player_name As String) As String
            Dim res As String = ""

            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select * from fb_pools a full outer join fb_users b on a.pool_owner=b.username where pool_id=@pool_id"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    Dim pool_ds As New dataset()
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(pool_ds)

                    Dim pool_name As String = ""
                    Try
                        pool_name = pool_ds.tables(0).rows(0)("pool_name")
                    Catch
                    End Try
                    Dim pool_owner_email As String = ""
                    Try
                        pool_owner_email = pool_ds.tables(0).rows(0)("email")
                    Catch
                    End Try

                    res = addPlayer(pool_id, player_name)

                    If res = player_name Then
                        sql = "delete from fb_invites where email=@email and pool_id=@pool_id and invite_key=@invite_key"

                        cmd = New SQLCommand(sql, con)
                        cmd.parameters.add(GetParm("email"))
                        cmd.parameters.add(GetParm("pool_id"))
                        cmd.parameters.add(New SQLParameter("@INVITE_KEY", SQLDbType.VARCHAR, 40))

                        cmd.parameters("@POOL_ID").value = POOL_ID
                        cmd.parameters("@EMAIL").value = EMAIL
                        cmd.parameters("@INVITE_KEY").value = INVITE_KEY
                        cmd.executenonquery()
                        updatescoretsp(pool_id)

                        res = email

                        Dim sb As New stringbuilder()
                        sb.append("Your invitation has been accepted.<br />")
                        sb.append("Pool Name: " & pool_name & "<br />")
                        sb.append("Player Name: " & player_name & "<br />")
                        sendemail(emailaddress:=pool_owner_email, subject:="Invitation accepted", body:=sb.tostring())

                    Else
                        res = "Invalid input info."
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try

            Return res
        End Function

        Public Function addPlayer(pool_id As Integer, username As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "insert into fb_players (pool_id, username) values (@pool_id, @username)"

                    cmd = New SQLCommand(sql, con)
                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(GetParm("username")).value = username
                    cmd.executenonquery()
                    updatescoretsp(pool_id)
                    res = username
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function ResetPassword(username As String) As String
            Dim res As String
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim temppassword As String
                    temppassword = CreateTempPassword()

                    Dim sql As String
                    Dim cmd As SQLCommand

                    sql = "select *  from fb_users where upper(username) = @username or upper(email) = @username"
                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username")).value = username.toupper()
                    Dim oda As New sqldataadapter()
                    oda.selectcommand = cmd
                    Dim ds As New dataset()
                    oda.fill(ds)

                    Dim realUsername As String = ""
                    Dim email As String = ""
                    Try
                        realUsername = ds.tables(0).rows(0)("username")
                        email = ds.tables(0).rows(0)("email")
                    Catch
                    End Try

                    If realUsername <> "" Then
                        sql = "update fb_users set temp_password=@password where username=@username"
                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(New SQLParameter("@password", SQLDbType.varchar, 50)).value = hashpassword(temppassword)
                        cmd.parameters.add(GetParm("username")).value = realUsername
                        cmd.executeNonQuery()


                        Dim sb As stringbuilder = New stringbuilder()
                        sb.append("A request has been received to reset your password.  The following password is temporary.  If this message is in error, and you have not requested to reset your password, then you do not have to do anything.  <br/><br/>Your password will still work normally.  <br/><br/>If you did request to have your password reset, when you login using this password it will become your permanent password until you choose to change it.<br /><br />")
                        sb.append("Username: " & realUsername & "<br/>")
                        sb.append("Password: " & temppassword & "<br/>")

                        SendEmail(email, "Your password has been reset.", sb.tostring())
                    End If
                    res = realUsername
                    makesystemlog("Password reset", "Input Username: " & username & " Real Username:" & realUsername)
                End Using
            Catch ex As exception
                res = "An error occurred.  The password may not have been reset."
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Private Function CreateTempPassword()
            Dim temppassword As String

            Dim validcharacters As String
            validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"

            Dim c As Char
            System.Threading.Thread.Sleep(30)

            Dim fixRand As New Random()
            Dim randomstring As stringbuilder = New stringbuilder(20)

            Dim i As Integer
            For i = 0 To 7
                randomstring.append(validcharacters.substring(fixRand.Next(0, validcharacters.length), 1))
            Next
            temppassword = randomstring.ToString()
            Return temppassword

        End Function

        Private Function SendEmail(emailaddress As String, Subject As String, Body As String) As String
            Dim res As String = ""
            Try

                Dim myMessage As mailmessage

                myMessage = New MailMessage

                myMessage.BodyFormat = MailFormat.Html
                myMessage.From = "support@smackpools.com"
                myMessage.To = emailaddress
                myMessage.Subject = subject
                myMessage.Body = body

                SmtpMail.SmtpServer = "mrelay.perfora.net"
                SmtpMail.Send(myMessage)
                res = emailaddress

            Catch ex As exception
                res = ex.message
                MakeSystemLog("Failed to send email.", "Info:" & system.environment.newline & "Email: " & emailaddress & system.environment.newline & "Subject:" & subject & system.environment.newline & "Body:" & system.environment.newline & body & system.environment.newline & ex.tostring())
            End Try
            Return res
        End Function

        Public Function validusername(u As String) As Boolean
            Dim res As Boolean = True

            If u.ToUpper() = "SYSTEM" Then
                res = False
            End If
            If u.ToUpper() = "RASPUTIN" Then
                res = False
            End If

            Dim i As Integer
            Dim validcharacters As String
            validcharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"

            Dim c As String

            For i = 0 To u.length - 1
                c = u.substring(i, 1)
                If validcharacters.indexof(c) < 0 Then
                    res = False
                End If
            Next
            Return res
        End Function


        Public Function RegisterUser(username As String, password As String, email As String) As String

            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim usercount As Integer

                    Dim validate_key As String

                    Dim cmd As SQLCommand
                    Dim dr As SQLDataReader
                    Dim parm1 As SQLParameter

                    Dim sql As String


                    sql = "select count(*) from fb_users where UPPER(username) = @username or UPPER(email) = @email"

                    cmd = New SQLCommand(sql, con)

                    parm1 = GetParm("username")
                    parm1.value = username.toupper()
                    cmd.parameters.add(parm1)

                    parm1 = New SQLParameter("@email", SQLDbType.varchar, 50)
                    parm1.value = email.toupper()
                    cmd.parameters.add(parm1)

                    usercount = cmd.ExecuteScalar()

                    If usercount > 0 Then
                        res = "Username and/or email is already registered."
                    Else



                        Dim validcharacters As String
                        validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"

                        Dim c As Char
                        Thread.Sleep(30)

                        Dim fixRand As New Random()
                        Dim randomstring As stringbuilder = New stringbuilder(20)

                        Dim i As Integer
                        For i = 0 To 29
                            randomstring.append(validcharacters.substring(fixRand.Next(0, validcharacters.length), 1))
                        Next
                        validate_key = randomstring.ToString()

                        sql = "insert into fb_users (username,email,password,validate_key) values (@username, @email, @password,@validate_key)"

                        cmd = New SQLCommand(sql, con)

                        parm1 = GetParm("username")
                        parm1.value = username
                        cmd.parameters.add(parm1)

                        parm1 = New SQLParameter("@email", SQLDbType.varchar, 50)
                        parm1.value = email
                        cmd.parameters.add(parm1)

                        cmd.parameters.add(New SQLParameter("@password", SQLDbType.VarChar, 50)).value = hashpassword(password)

                        parm1 = New SQLParameter("@validate_key", SQLDbType.varchar, 40)
                        parm1.value = validate_key
                        cmd.parameters.add(parm1)

                        cmd.executenonquery()


                        Dim sb As New stringbuilder()

                        sb.append("You have registered to use the www.smackpools.com website.  <br><br>" & system.environment.newline)
                        sb.append("Username: " & username & " <br><br>" & system.environment.newline)
                        sb.append("Password: " & password & " <br><br>" & system.environment.newline)
                        sb.append("To verify that this is a valid email address you must go to the URL below before you can login using your username and password. <br><br>" & system.environment.newline)
                        sb.append("Here is your validation link.<br><br>" & system.environment.newline)
                        sb.append("<a href=""http://www.smackpools.com/football/validate_registration.aspx?username=" & username & "&validate_key=" & validate_key & """>http://www.smackpools.com/football/validate_registration.aspx?username=" & username & "&validate_key=" & validate_key & "</a> <br /><br /><br />" & system.environment.newline & system.environment.newline & "Thanks,<br />" & system.environment.newline & "Chris")


                        sendemail(emailaddress:=email, subject:="www.smackpools.com registration verification", body:=sb.tostring())
                        res = email
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                MakeSystemLog("error in registeruser", ex.tostring())
            End Try
            Return res
        End Function

        Public Function resendinvite(pool_id As Integer, email As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()

                    Dim cmd As SQLCommand
                    Dim dr As SQLDataReader
                    Dim sql As String


                    sql = "select a.pool_id, a.email, a.invite_key, b.pool_owner, b.pool_name, b.pool_desc from fb_invites a full outer join fb_pools b on a.pool_id=b.pool_id where a.pool_id=@pool_id and a.email=@email"

                    cmd = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id
                    cmd.parameters.add(New SQLParameter("@email", SQLDbType.varchar, 50)).value = email

                    Dim oda As New SQLDataAdapter()
                    Dim invite_ds As New dataset()
                    oda.selectcommand = cmd
                    oda.fill(invite_ds)
                    If invite_ds.tables.count < 1 Then
                        res = "invalid pool_id"
                    Else
                        If invite_ds.tables(0).rows.count < 1 Then
                            res = "invalid pool_id"
                        Else
                            sendinvite(email:=email, _
                            invite_key:=invite_ds.tables(0).rows(0)("invite_key"), _
                            pool_id:=pool_id, _
                            username:=invite_ds.tables(0).rows(0)("pool_owner"))
                            res = email

                        End If
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("error in resendinvite", ex.tostring())
            End Try
            Return res
        End Function

        Public Function sendmessage(email As String, msg As String, username As String) As String
            Dim res As String = ""
            Try
                Dim sb As New stringbuilder()

                sb.append("The following message was sent from the website:  <br><br>" & system.environment.newline)

                sb.append("Username: " & username & " <br><br>" & system.environment.newline)

                sb.append("Email: " & email & " <br><br>" & system.environment.newline)

                sb.append("System Time: " & system.datetime.now & " <br><br>" & system.environment.newline)

                sb.append("Message:  <br><br>" & system.environment.newline)

                sb.append(msg & " <br><br>" & system.environment.newline)

                Dim myMessage As mailmessage

                myMessage = New MailMessage

                myMessage.BodyFormat = MailFormat.Html
                myMessage.From = email
                myMessage.To = "chrishad95@yahoo.com"
                myMessage.Subject = "Webpage forward"
                myMessage.Body = sb.tostring()

                myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserver", "smtp.mail.yahoo.com")
                myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserverport", 25)
                myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusing", 2)
                myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1)
                myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusername", "chrishad95")
                myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendpassword", "househorse89")

                ' Doesn't have to be local... just enter your
                ' SMTP server's name or ip address!


                SmtpMail.SmtpServer = "smtp.mail.yahoo.com"
                SmtpMail.Send(myMessage)

                res = email
            Catch ex As exception
                res = ex.message
                makesystemlog("error in sendmessage", ex.tostring())
            End Try
            Return res
        End Function

        Private Function hashpassword(password As String) As String
            'Encrypt the password
            Dim md5Hasher As New MD5CryptoServiceProvider()

            Dim hashedBytes As Byte()
            Dim encoder As New UTF8Encoding()

            hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(password))
            Dim sb As StringBuilder = New StringBuilder(hashedbytes.length * 2)
            For i As Integer = 0 To hashedbytes.length - 1
                sb.append(hashedbytes(i).toString("X2"))
            Next

            Return sb.ToString().tolower()

        End Function

        Public Function Login(username As String, password As String) As String
            Dim res As String = ""
            Try
                If authenticate(username, password) Then
                    res = getusername(username)
                Else
                    ' failed to authenticate with username and normal password, try temp password
                    Using con As New SQLConnection(myconnstring)
                        con.open()
                        Dim usercount As Integer = 0

                        Dim cmd As SQLCommand
                        Dim sql As String

                        sql = "select username from fb_users where (UPPER(username) = @username  or upper(email) = @username) and temp_password=@password and validated='Y'"

                        cmd = New SQLCommand(sql, con)

                        cmd.parameters.add(GetParm("username")).value = username.toupper()
                        cmd.parameters.add(New SQLParameter("@password", SQLDbType.varchar, 50)).value = hashpassword(password)

                        Dim dt As New datatable()
                        Dim oda As New SQLDataAdapter()
                        oda.selectcommand = cmd
                        oda.fill(dt)
                        If dt.rows.count > 0 Then
                            res = dt.rows(0)("username")
                            sql = "update fb_users set password=temp_password, login_count=login_count + 1, last_seen = current_timestamp where username=@username"
                            cmd = New SQLCommand(sql, con)
                            cmd.parameters.add(GetParm("username")).value = res
                            cmd.executenonquery()
                            makesystemlog("Updated user record", "Updated password with temporary password for user:" & res)

                            sql = "update fb_users set temp_password = ''  where username=@username"
                            cmd = New SQLCommand(sql, con)
                            cmd.parameters.add(GetParm("username")).value = res
                            cmd.executenonquery()

                        End If
                    End Using
                End If
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetAvatar(username As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "select email from fb_users where username=@username"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("username")).value = username

                    Dim ds As New system.data.dataset()
                    Dim oda As New SQLDataAdapter()
                    oda.selectcommand = cmd
                    oda.fill(ds)
                    Try
                        If Not ds.tables(0).rows(0)("email") Is dbnull.value Then
                            Dim md5Hasher As New MD5CryptoServiceProvider()

                            Dim hashedBytes As Byte()
                            Dim encoder As New UTF8Encoding()
                            hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(ds.tables(0).rows(0)("email")))
                            Dim sb As StringBuilder = New StringBuilder(hashedbytes.length * 2)
                            For i As Integer = 0 To hashedbytes.length - 1
                                sb.Append(hashedbytes(i).toString("X2"))
                            Next
                            res = sb.ToString().ToLower()
                        End If
                    Catch ex As exception
                        makesystemlog("error in GetAvatar", ex.toString())
                    End Try
                End Using
            Catch ex As exception
                Dim st As New System.Diagnostics.StackTrace()
                makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
            End Try
            Return res
        End Function

        Public Function GetAvatar(pool_id As Integer, username As String) As String
            Return getavatar(username)
        End Function

        Public Function ChangeAvatar(pool_id As Integer, username As String, avatar As String) As String
            Dim res As String = ""
            Try
                Using con As New SQLConnection(myconnstring)
                    con.open()
                    Dim sql As String = "update fb_players set avatar=@avatar WHERE pool_id=@pool_id AND username=@username"
                    Dim cmd As SQLCommand = New SQLCommand(sql, con)

                    cmd.parameters.add(GetParm("pool_id")).value = pool_id

                    cmd.parameters.add(New SQLParameter("@avatar", SQLDbType.VARCHAR, 255))
                    cmd.parameters.add(GetParm("username"))

                    cmd.parameters("@USERNAME").value = USERNAME
                    cmd.parameters("@avatar").value = avatar

                    Dim rowsaffected As Integer = 0

                    rowsaffected = cmd.executenonquery()


                    If rowsaffected > 0 Then
                        res = "SUCCESS"
                    Else
                        res = "Failed to change avatar."
                    End If
                End Using
            Catch ex As exception
                res = ex.message
                makesystemlog("error in ChangeAvatar", ex.toString())
            End Try
            Return res
        End Function

        Private Function GetParm(t As String) As SQLParameter
            Select Case t.tolower()
                Case "pool_id"
                    Return New SQLParameter("@pool_id", SQLDbType.Int)
                Case "team_id"
                    Return New SQLParameter("@team_id", SQLDbType.Int)
                Case "username"
                    Return New SQLParameter("@username", SQLDbType.VarChar, 50)
                Case "pool_owner"
                    Return New SQLParameter("@pool_owner", SQLDbType.VarChar, 50)
                Case "email"
                    Return New SQLParameter("@email", SQLDbType.VarChar, 255)
                Case Else
                    Return New SQLParameter("@" & t, SQLDbType.VarChar)
            End Select
        End Function
    End Class


    Public Class FBMessage
        Private myconnstring As String = System.Configuration.ConfigurationSettings.AppSettings("connString")
        Private _from_user As String
        Private _to_user As String
        Private _subject As String
        Private _body As String
        Private _read_at As datetime
        Private _created_at As datetime
        Private _id As Integer

        Public Property fromUser() As String
            Get
                Return _from_user
            End Get
            Set(ByVal value As String)
                _from_user = value
            End Set
        End Property
        Public Property toUser() As String
            Get
                Return _to_user
            End Get
            Set(ByVal value As String)
                _to_user = value
            End Set
        End Property
        Public Property subject() As String
            Get
                Return _subject
            End Get
            Set(ByVal value As String)
                _subject = value
            End Set
        End Property
        Public Property body() As String
            Get
                Return _body
            End Get
            Set(ByVal value As String)
                _body = value
            End Set
        End Property
        Public Property id() As Integer
            Get
                Return _id
            End Get
            Set(ByVal value As Integer)
                _id = value
            End Set
        End Property
        Public Property created_at() As datetime
            Get
                Return _created_at
            End Get
            Set(ByVal value As datetime)
                _created_at = value
            End Set
        End Property
        Public Property read_at() As datetime
            Get
                Return _read_at
            End Get
            Set(ByVal value As datetime)
                _read_at = value
            End Set
        End Property


    End Class


    Public Class GreatGraph
        ' World coordinate boundaries.
        Public Wxmin As Single = -10.0
        Public Wxmax As Single = 10.0
        Public Wymin As Single = -10.0
        Public Wymax As Single = 10.0

        ' The collection of things (data sets and axes) to draw.
        Private m_GraphObjects As New List(Of DataSeries)

        ' Set drawing styles.
        '    Private Sub GreatGraph_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        '        Me.SetStyle( _
        '            ControlStyles.AllPaintingInWmPaint Or _
        '            ControlStyles.ResizeRedraw Or _
        '            ControlStyles.OptimizedDoubleBuffer, _
        '            True)
        '        Me.UpdateStyles()
        '    End Sub

        ' If the mouse is over a moveable data point.
        ' start moving it.
        '    Private Sub GreatGraph_MouseDown(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles Me.MouseDown
        '        ' Convert the point into world coordinates.
        '        Dim x, y As Single
        '        DeviceToWorld(Me.PointToClient(Control.MousePosition), x, y)
        '
        '        ' Start moving the data point if we can.
        '        StartMovingPoint(x, y)
        '    End Sub
        '
        '
        '    ' Display a tooltip if appropriate.
        '    ' Display a point move cursor if appropriate.
        '    Private Sub GreatGraph_MouseMove(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles Me.MouseMove
        '        ' Convert the point into world coordinates.
        '        Dim x, y As Single
        '        DeviceToWorld(Me.PointToClient(Control.MousePosition), x, y)
        '
        '        ' Display a tooltip if appropriate.
        '        SetTooltip(x, y)
        '
        '        ' Display a point move cursor if appropriate.
        '        DisplayMoveCursor(x, y)
        '    End Sub

        ' Convert a point from device to world coordinates.
        '    Friend Sub DeviceToWorld(ByVal pt As PointF, ByRef x As Single, ByRef y As Single)
        '        ' Make a transformation to map
        '        ' world to device coordinates.
        '        Dim world_rect As New RectangleF(Wxmin, Wymax, Wxmax - Wxmin, Wymin - Wymax)
        '        Dim client_points() As PointF = { _
        '            New PointF(Me.ClientRectangle.Left, Me.ClientRectangle.Top), _
        '            New PointF(Me.ClientRectangle.Right, Me.ClientRectangle.Top), _
        '            New PointF(Me.ClientRectangle.Left, Me.ClientRectangle.Bottom) _
        '        }
        '        Dim trans As Matrix = New Matrix(world_rect, client_points)
        '
        '        ' Invert the transformation.
        '        trans.Invert()
        '
        '        ' Get the mouse's position in screen coordinates
        '        ' and convert into control (device) coordinates.
        '        Dim pts() As PointF = {pt}
        '
        '        ' Convert into world coordinates.
        '        trans.TransformPoints(pts)
        '
        '        ' Set the results.
        '        x = pts(0).X
        '        y = pts(0).Y
        '    End Sub

        ' Display a tooltip if appropriate.
        '    Private Sub SetTooltip(ByVal x As Single, ByVal y As Single)
        '        ' See if a DataSeries object can display a tooltip.
        '        For Each obj As DataSeries In m_GraphObjects
        '            If obj.ShowDataTip(x, y) Then Exit Sub
        '        Next obj
        '
        '        ' No DataSeries can display a tooltip.
        '        ' Remove any previous tip.
        '        tipData.SetToolTip(Me, "")
        '    End Sub
        '
        '    ' Display a point move cursor if appropriate.
        '    Private Sub DisplayMoveCursor(ByVal x As Single, ByVal y As Single)
        '        ' See if the cursor is over a moveable point.
        '        For Each obj As DataSeries In m_GraphObjects
        '            If obj.DisplayMoveCursor(x, y) Then Exit Sub
        '        Next obj
        '
        '        ' The mouse is not over a moveable data point.
        '        ' Display the default cursor.
        '        Me.Cursor = Cursors.Default
        '    End Sub
        '
        '    ' Start moving a data point if appropriate.
        '    Private Sub StartMovingPoint(ByVal x As Single, ByVal y As Single)
        '        ' See if the cursor is over a moveable point.
        '        For Each obj As DataSeries In m_GraphObjects
        '            If obj.StartMovingPoint(x, y) Then
        '                ' Uninstall our MouseMove event handler.
        '                RemoveHandler Me.MouseMove, AddressOf GreatGraph_MouseMove
        '                Exit Sub
        '            End If
        '        Next obj
        '    End Sub

        ' After a data point is moved, reinstall our
        ' MouseMove event handler and redraw.
        '    Friend Sub DataPointMoved()
        '        AddHandler Me.MouseMove, AddressOf GreatGraph_MouseMove
        '        Me.Refresh()
        '    End Sub

        ' Draw the graph objects.
        '    Private Sub GreatGraph_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles Me.Paint
        '        e.Graphics.Clear(Me.BackColor)
        '
        '        DrawToGraphics(e.Graphics, _
        '            Me.ClientRectangle.Left, _
        '            Me.ClientRectangle.Right, _
        '            Me.ClientRectangle.Top, _
        '            Me.ClientRectangle.Bottom)
        '    End Sub

        ' Draw the graph on the Graphics object.
        Public Sub DrawToGraphics(ByVal gr As Graphics, ByVal dxmin As Single, ByVal dxmax As Single, ByVal dymin As Single, ByVal dymax As Single)
            ' Save the graphics state.
            Dim original_state As GraphicsState = gr.Save()

            ' Map the world coordinates onto the control's surface.
            Dim world_rect As New RectangleF(Wxmin, Wymax, Wxmax - Wxmin, Wymin - Wymax)
            Dim client_points() As PointF = { _
                New PointF(dxmin, dymin), _
                New PointF(dxmax, dymin), _
                New PointF(dxmin, dymax) _
            }
            gr.Transform = New Matrix(world_rect, client_points)

            ' Clip to the world coordinates.
            gr.SetClip(world_rect)

            ' Clear and draw the graph objects.
            For Each obj As DataSeries In m_GraphObjects
                obj.Draw(gr, Wxmin, Wxmax)
            Next obj

            ' Restore the original graphics state.
            gr.Restore(original_state)
        End Sub

        ' Add a new DataSeries object to the graph.
        Public Function AddDataSeries(Optional ByVal new_series As DataSeries = Nothing) As DataSeries
            If new_series Is Nothing Then new_series = New DataSeries()
            new_series.Parent = Me
            m_GraphObjects.Add(new_series)
            Return new_series
        End Function

        ' Adjust the world coordinates to have
        ' the same aspect ratio as the control.
        '    Public Sub AdjustAspect()
        '        Dim dwx As Single = Wxmax - Wxmin
        '        Dim dwy As Single = Wymax - Wymin
        '
        '        ' Compare aspect ratios.
        '        If dwy * Me.ClientSize.Width > dwx * Me.ClientSize.Height Then
        '            ' World coordinates are relatively tall and thin.
        '            ' Make them wider.
        '            Dim new_wid As Single = dwy * Me.ClientSize.Width / Me.ClientSize.Height
        '            Dim cx As Single = (Wxmax + Wxmin) / 2
        '            Wxmin = cx - new_wid / 2
        '            Wxmax = Wxmin + new_wid
        '        Else
        '            ' World coordinates are relatively short and wide.
        '            ' Make them taller.
        '            Dim new_hgt As Single = dwx * Me.ClientSize.Height / Me.ClientSize.Width
        '            Dim cy As Single = (Wymax + Wymin) / 2
        '            Wymin = cy - new_hgt / 2
        '            Wymax = Wymin + new_hgt
        '        End If
        '    End Sub
    End Class
    ' Represents a series of data points.
    Public Class DataSeries
        ' The data points.
        Public Points() As PointF = {}

        ' The GreatGraph containing this object.
        Public Parent As GreatGraph = Nothing

        ' The data series name.
        Public Name As String = ""

        ' Bar drawing.
        Public BarPen As Pen = Nothing
        Public BarBrush As Brush = Nothing
        Public BarWidthModifier As Double = 1.0

        ' Area drawing.
        Public AreaPen As Pen = Nothing
        Public AreaBrush As Brush = Nothing

        ' Line drawing.
        Public LinePen As Pen = Nothing

        ' Point drawing.
        Public PointWidth As Single = 0.05
        Public PointPen As Pen = Nothing
        Public PointBrush As Brush = Nothing

        ' Radial line drawing.
        Public RadialPen As Pen = Nothing
        Public RadialBrush As Brush = Nothing

        ' Tick mark drawing.
        Public TickPen As Pen = Nothing
        Public TickMarkWidth As Single = 1

        ' Label drawing.
        Public Labels() As String = Nothing
        Public LabelFont As Font = Nothing
        Public LabelsOnLeft As Boolean = False
        Public LabelBrush As Brush = Nothing

        ' Aggregate function drawing.
        Public AveragePen As Pen = Nothing
        Public MinimumPen As Pen = Nothing
        Public MaximumPen As Pen = Nothing

        ' Determines whether the user can change data.
        Public AllowUserChangeX As Boolean = False
        Public AllowUserChangeY As Boolean = False

        ' Determines whether we display a data value tooltip.
        Public ShowDataTips As Boolean = False

        ' The X and Y distances from the mouse
        ' to the cursor to indicate a data hit.
        Public HitDx As Single = 0.25
        Public HitDy As Single = 0.25

        ' Draw the object.
        Public Sub Draw(ByVal gr As Graphics, ByVal w_xmin As Single, ByVal w_xmax As Single)
            DrawBar(gr)
            DrawArea(gr)
            DrawRadial(gr)
            DrawLine(gr)
            DrawTickMarks(gr)
            DrawPoint(gr)
            DrawAggregates(gr, w_xmin, w_xmax)
            DrawLabels(gr)
        End Sub

#Region "Drawing Routines"
        Private Sub DrawBar(ByVal gr As Graphics)
            If BarPen Is Nothing Then Exit Sub

            Dim wid As Double = (Points(1).X - Points(0).X) * BarWidthModifier
            Dim rects() As RectangleF
            ReDim rects(Points.Length - 1)
            For i As Integer = 0 To Points.Length - 1
                If Points(i).Y > 0 Then
                    rects(i) = New RectangleF( _
                        Points(i).X - wid / 2, 0, _
                        wid, Points(i).Y)
                Else
                    rects(i) = New RectangleF( _
                        Points(i).X - wid / 2, _
                        Points(i).Y, _
                        wid, -Points(i).Y)
                End If
            Next i

            gr.FillRectangles(BarBrush, rects)
            gr.DrawRectangles(BarPen, rects)
        End Sub

        Private Sub DrawArea(ByVal gr As Graphics)
            If AreaPen Is Nothing Then Exit Sub

            Dim pts(3) As PointF
            For i As Integer = 0 To Points.Length - 2
                pts(0) = New PointF(Points(i).X, 0)
                pts(1) = Points(i)
                pts(2) = Points(i + 1)
                pts(3) = New PointF(Points(i + 1).X, 0)

                gr.FillPolygon(AreaBrush, pts)
                gr.DrawPolygon(AreaPen, pts)
            Next i
        End Sub

        Private Sub DrawLine(ByVal gr As Graphics)
            If LinePen Is Nothing Then Exit Sub
            gr.DrawLines(LinePen, Points)
        End Sub

        Private Sub DrawTickMarks(ByVal gr As Graphics)
            If TickPen Is Nothing Then Exit Sub

            For i As Integer = 0 To Points.Length - 1
                ' Get a tick mark vector.
                Dim tx, ty As Single
                GetTickVector(i, tx, ty)

                ' Draw the tick mark.
                gr.DrawLine(TickPen, _
                    Points(i).X - tx, _
                    Points(i).Y - ty, _
                    Points(i).X + tx, _
                    Points(i).Y + ty)
            Next i
        End Sub

        ' Return a tick mark vector for this point.
        Private Sub GetTickVector(ByVal i As Integer, ByRef tx As Single, ByRef ty As Single)
            ' Get the direction vector for the previous segment.
            Dim dx1, dy1, len1 As Single
            If i = 0 Then
                dx1 = Points(1).X - Points(0).X
                dy1 = Points(1).Y - Points(0).Y
            Else
                dx1 = Points(i).X - Points(i - 1).X
                dy1 = Points(i).Y - Points(i - 1).Y
            End If
            len1 = Sqrt(dx1 * dx1 + dy1 * dy1)
            dx1 /= len1
            dy1 /= len1

            ' Get the direction vector for the following segment.
            Dim dx2, dy2, len2 As Single
            If i = Points.Length - 1 Then
                dx2 = Points(i).X - Points(i - 1).X
                dy2 = Points(i).Y - Points(i - 1).Y
            Else
                dx2 = Points(i + 1).X - Points(i).X
                dy2 = Points(i + 1).Y - Points(i).Y
            End If
            len2 = Sqrt(dx2 * dx2 + dy2 * dy2)
            dx2 /= len2
            dy2 /= len2

            ' Average the vectors.
            Dim avex As Single = (dx1 + dx2) / 2
            Dim avey As Single = (dy1 + dy2) / 2
            Dim ave_len As Single = Sqrt(avex * avex + avey * avey)
            If ave_len < 0.001 Then
                avex = dx1
                avey = dy1
            Else
                avex /= ave_len
                avey /= ave_len
            End If

            ' Find the perpendicular vector of length TickMarkWidth / 2.
            tx = -avey * TickMarkWidth / 2
            ty = avex * TickMarkWidth / 2
        End Sub

        Private Sub DrawPoint(ByVal gr As Graphics)
            If PointPen Is Nothing Then Exit Sub

            ' Draw points.
            Dim rects() As RectangleF
            ReDim rects(Points.Length - 1)
            For i As Integer = 0 To Points.Length - 1
                rects(i) = New RectangleF( _
                    Points(i).X - PointWidth / 2, _
                    Points(i).Y - PointWidth / 2, _
                    PointWidth, PointWidth)
            Next i
            gr.FillRectangles(PointBrush, rects)
            gr.DrawRectangles(PointPen, rects)
        End Sub

        Private Sub DrawRadial(ByVal gr As Graphics)
            Dim origin As New PointF(0, 0)

            ' Fill the radial areas.
            If RadialBrush IsNot Nothing Then
                Dim pts(2) As PointF
                For i As Integer = 0 To Points.Length - 2
                    pts(0) = Points(i)
                    pts(1) = origin
                    pts(2) = Points(i + 1)
                    gr.FillPolygon(RadialBrush, pts)
                Next i
            End If

            ' Outline the radial areas.
            If RadialPen IsNot Nothing Then
                For i As Integer = 0 To Points.Length - 1
                    gr.DrawLine(RadialPen, origin, Points(i))
                Next i
            End If
        End Sub

        Private Sub DrawAggregates(ByVal gr As Graphics, ByVal w_xmin As Single, ByVal w_xmax As Single)
            If AveragePen Is Nothing AndAlso _
               MinimumPen Is Nothing AndAlso _
               MaximumPen Is Nothing _
                    Then Exit Sub

            ' Calculate the average, minimum, and maximum.
            Dim min As Single = Points(0).Y
            Dim max As Single = min
            Dim ave As Single = min
            For i As Integer = 1 To Points.Length - 1
                ave += Points(i).Y
                If min > Points(i).Y Then min = Points(i).Y
                If max < Points(i).Y Then max = Points(i).Y
            Next i
            ave /= Points.Length

            ' Average.
            If AveragePen IsNot Nothing Then
                gr.DrawLine(AveragePen, _
                    w_xmin, ave, _
                    w_xmax, ave)
            End If

            ' Minimum.
            If MinimumPen IsNot Nothing Then
                gr.DrawLine(MinimumPen, _
                    w_xmin, min, _
                    w_xmax, min)
            End If

            ' Maximum.
            If MaximumPen IsNot Nothing Then
                gr.DrawLine(MaximumPen, _
                    w_xmin, max, _
                    w_xmax, max)
            End If
        End Sub

        Private Sub DrawLabels(ByVal gr As Graphics)
            If Labels Is Nothing Then Exit Sub

            ' Save the original transformation.
            Dim old_transform As Matrix = gr.Transform

            ' Flip the transformation vertically.
            gr.ScaleTransform(1, -1, MatrixOrder.Prepend)

            ' Draw the labels.
            For i As Integer = 0 To Points.Length - 1
                ' Get the tick mark direction vector.
                Dim tx, ty As Single
                GetTickVector(i, tx, ty)

                ' Lengthen the tick mark vector to 
                ' add extra room for the text.
                Dim lbl_size As SizeF = gr.MeasureString(Labels(i), LabelFont)
                Dim extra_len As Single = 0.375 * Sqrt(lbl_size.Width * lbl_size.Width + lbl_size.Height * lbl_size.Height)
                Dim tick_len As Single = Sqrt(tx * tx + ty * ty)
                tx *= (1 + extra_len / tick_len)
                ty *= (1 + extra_len / tick_len)

                ' Draw the label.
                Using sf As New StringFormat()
                    sf.Alignment = StringAlignment.Center
                    sf.LineAlignment = StringAlignment.Center
                    Dim x, y As Single
                    If LabelsOnLeft Then
                        x = Points(i).X + tx
                        y = -(Points(i).Y + ty)
                    Else
                        x = Points(i).X - tx
                        y = -(Points(i).Y - ty)
                    End If
                    gr.DrawString(Labels(i), _
                        LabelFont, LabelBrush, x, y, sf)
                End Using
            Next i

            ' Restore the original transformation.
            gr.Transform = old_transform
        End Sub
#End Region ' Drawing Routines

        ' If this point is near to a data point,
        ' return the data point's index.
        Friend Function FindPointAt(ByVal x As Single, ByVal y As Single) As Integer
            For i As Integer = 0 To Points.Length - 1
                Dim dx As Single = x - Points(i).X
                Dim dy As Single = y - Points(i).Y
                If Abs(dx) <= HitDx AndAlso Abs(dy) <= HitDy Then Return i
            Next i

            ' We didn't find a point here.
            Return -1
        End Function

        ' If this point is near to a data point,
        ' set the tooltip and return True.
        '    Friend Function ShowDataTip(ByVal x As Single, ByVal y As Single) As Boolean
        '        If Not ShowDataTips Then Return False
        '
        '        ' See if there's a data point here.
        '        Dim pt_num As Integer = FindPointAt(x, y)
        '        If pt_num < 0 Then Return False
        '
        '        ' Display the tip.
        '        Parent.tipData.SetToolTip(Parent, _
        '            Name & ": (" & _
        '            Points(pt_num).X & ", " & _
        '            Points(pt_num).Y & ")")
        '        Return True
        '    End Function

        ' If (x, y) is over a moveable data point,
        ' display the appropriate move cursor and return True.
        '    Friend Function DisplayMoveCursor(ByVal x As Single, ByVal y As Single) As Boolean
        '        If (Not AllowUserChangeX) AndAlso (Not AllowUserChangeY) Then Return False
        '
        '        ' See if there's a data point here.
        '        Dim pt_num As Integer = FindPointAt(x, y)
        '        If pt_num < 0 Then Return False
        '
        '        ' Set the cursor.
        '        If AllowUserChangeX AndAlso AllowUserChangeY Then
        '            Parent.Cursor = Cursors.SizeAll
        '        ElseIf AllowUserChangeX Then
        '            Parent.Cursor = Cursors.SizeWE
        '        Else
        '            Parent.Cursor = Cursors.SizeNS
        '        End If
        '
        '        Return True
        '    End Function

        ' If (x, y) is over a moveable data point,
        ' install MouseMove and MouseUp event handlers
        ' to let the user move the point and return True.
        Private m_MovingPointNum As Integer = -1
        '    Friend Function StartMovingPoint(ByVal x As Single, ByVal y As Single) As Boolean
        '        If (Not AllowUserChangeX) AndAlso (Not AllowUserChangeY) Then Return False
        '
        '        ' See if there's a data point here.
        '        m_MovingPointNum = FindPointAt(x, y)
        '        If m_MovingPointNum < 0 Then Return False
        '
        '        ' Install our event handlers.
        '        AddHandler Parent.MouseMove, AddressOf Parent_MouseMove
        '        AddHandler Parent.MouseUp, AddressOf Parent_MouseUp
        '
        '        Return True
        '    End Function

        '    ' The user is moving a data point.
        '    Private Sub Parent_MouseMove(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs)
        '        ' Get the mouse position in world coordinates.
        '        Dim x, y As Single
        '        Parent.DeviceToWorld(New PointF(e.X, e.Y), x, y)
        '
        '        ' Move the point.
        '        If AllowUserChangeX Then Points(m_MovingPointNum).X = x
        '        If AllowUserChangeY Then Points(m_MovingPointNum).Y = y
        '
        '        ' Set a new tooltip if appropriate.
        '        ShowDataTip(x, y)
        '
        '        ' Redraw the graph.
        '        Parent.Refresh()
        '    End Sub
        '
        '    ' Stop moving the data point.
        '    ' Uninstall our MouseMove and MouseUp event handlers
        '    ' and let the parent know we moved the point.
        '    Private Sub Parent_MouseUp(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs)
        '        RemoveHandler Parent.MouseMove, AddressOf Parent_MouseMove
        '        RemoveHandler Parent.MouseUp, AddressOf Parent_MouseUp
        '
        '        Parent.DataPointMoved()
        '    End Sub

        ' Make a DataSeries representing an axis.
        Public Shared Function MakeAxis(ByVal tick_increment As Single, ByVal xmin As Single, ByVal xmax As Single, ByVal ymin As Single, ByVal ymax As Single) As DataSeries
            Dim data_series As New DataSeries
            With data_series
                Dim dx As Single = xmax - xmin
                Dim dy As Single = ymax - ymin
                Dim len As Single = Sqrt(dx * dx + dy * dy)

                ' See how many tick marks we need.
                Dim num_points As Integer = Int(len / tick_increment) + 1

                ' Get the vector between adjacent tick marks.
                dx *= tick_increment / len
                dy *= tick_increment / len

                ' Build the points.
                Dim pts(num_points - 1) As PointF
                Dim data_labels(num_points - 1) As String
                Dim x As Single = xmin
                Dim y As Single = ymin
                For i As Integer = 0 To num_points - 1
                    pts(i).X = x
                    pts(i).Y = y
                    If Abs(dx) < 0.1 Then
                        data_labels(i) = y
                    ElseIf Abs(dy) < 0.1 Then
                        data_labels(i) = x
                    End If
                    x += dx
                    y += dy
                Next i

                .Points = pts
                .TickMarkWidth = 1

                ' Only make automatic labels for vertical and horizontal axes.
                If (Abs(dx) < 0.1) OrElse (Abs(dy) < 0.1) Then
                    .Labels = data_labels
                End If

                ' Put the labels on the left for the Y axis
                ' and on the right (bottom) for the X axis.
                If Abs(dx) < 0.1 Then
                    .LabelsOnLeft = True
                ElseIf Abs(dy) < 0.1 Then
                    .LabelsOnLeft = False
                End If
            End With

            Return data_series
        End Function

        ' Make a DataSeries representing an ellipse.
        Public Shared Function MakeEllipse(ByVal cx As Single, ByVal cy As Single, ByVal rx As Single, ByVal ry As Single, ByVal num_points As Integer) As DataSeries
            Dim data_series As New DataSeries
            With data_series
                ReDim .Points(num_points - 1)
                Dim theta As Single = 0
                Dim dtheta As Single = 2 * PI / (num_points - 1)
                For i As Integer = 0 To num_points - 1
                    .Points(i).X = cx + rx * Cos(theta)
                    .Points(i).Y = cy + ry * Sin(theta)
                    theta += dtheta
                Next i
            End With

            Return data_series
        End Function
    End Class


End Namespace
