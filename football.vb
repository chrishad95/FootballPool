Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.ComponentModel
Imports System.Data
Imports System.Data.SQLClient
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
imports System.IO
Imports System.Math

Namespace Rasputin
	public Class FootballUtility

		private myconnstring as string = System.Configuration.ConfigurationSettings.AppSettings("connString")
		private isInitialized as boolean


		public sub initialize()
		end sub

		Public sub MakeSystemLog (log_title as string, log_text as string)
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "insert into fb_journal_entries (username,journal_type,entry_title,entry_text) values ('', 'FOOTBALL', @entry_title, @entry_text)"
				
				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("entry_title", SQLDbType.varchar, 200)).value = log_title & " - " & system.datetime.now
				cmd.parameters.add(new SQLParameter("entry_text", SQLDbType.text, 32700)).value = log_text
				cmd.executenonquery()
			end using
			catch ex as exception
				throw (ex)
			end try
		end sub 

		public function GetErrors() as dataset
			dim res as new dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim sql as string
				dim cmd as SQLCommand
				dim dr as SQLDataReader
				dim oda as SQLDataAdapter
				dim parm1 as SQLParameter
				
				dim ds as dataset
				dim drow as datarow
				dim dt as datatable
				
				sql = "select top 50 * from fb_journal_entries where journal_type='FOOTBALL' order by entry_tsp desc"
				cmd = new SQLCommand(sql,con)
				oda = new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
			catch ex as exception
				makesystemlog("error in geterrors", ex.tostring())
			end try

			return res
		end function

		public function authenticate(username as string, password as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim oda as SQLDataAdapter
				dim parm1 as SQLParameter
		
				dim salt as string = ""
				dim valid_username as string = ""

				' do not bother unless they are validated
				sql = "select username, salt from fb_users where (upper(username) = @username or upper(email) = @username) and validated='Y'"
				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar)).value = username.toupper()

				dim ds as new dataset()	
				dim da as new sqldataadapter()
				da.selectcommand = cmd
				da.fill(ds)
				if ds.tables.count > 0 then
					if ds.tables(0).rows.count > 0 then
						if ds.tables(0).rows(0)("salt") is dbnull.value then
						else
							salt = ds.tables(0).rows(0)("salt")
						end if
						valid_username = ds.tables(0).rows(0)("username")
					end if
				end if

				sql = "select count(*) from fb_users where username=@username and password=@password and validated='Y'"
				
				cmd = new SQLCommand(sql,con)
				
				cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar)).value = valid_username
				cmd.parameters.add(new SQLParameter("@password", SQLDbType.varchar)).value = hashpassword(salt & password)
				
				dim usercount as integer = 0
				usercount = cmd.executescalar()
				
				if usercount > 0 then
					res = valid_username
					sql = "update fb_users set login_count=login_count + 1, last_seen = CURRENT_TIMESTAMP where username=@username"
					
					cmd = new SQLCommand(sql,con)
					
					parm1 = new SQLParameter("@username", SQLDbType.varchar, 30)
					parm1.value = res
					cmd.parameters.add(parm1)
					
					cmd.executenonquery()
				end if
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res

		end function

		public function GetCommentsFeed(username as string) as dataset
			dim res as new dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim sql as string
				dim cmd as SQLCommand
				dim dr as SQLDataReader
				dim oda as SQLDataAdapter
				dim parm1 as SQLParameter
				
				dim ds as dataset
				dim drow as datarow
				dim dt as datatable
				
				'con = new SQLConnection(myconnstring)
				

				sql = "select  * from fb_comments where ref_id is null and ( pool_id in (select pool_id from fb_players where username=@username) or pool_id in (select pool_id from fb_pools where pool_owner=@username) ) order by comment_tsp DESC"
				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50)).value = username

				oda = new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res

		end function

		public function GetCommentsFeed(pool_id as integer, username as string) as dataset
			dim res as new dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim sql as string
				dim cmd as SQLCommand
				dim dr as SQLDataReader
				dim oda as SQLDataAdapter
				dim parm1 as SQLParameter
				
				dim ds as dataset
				dim drow as datarow
				dim dt as datatable
				
				'con = new SQLConnection(myconnstring)
				

				sql = "select  * from fb_comments where ref_id is null and pool_id=@pool_id and pool_id in (select pool_id from fb_players where username=@username) order by comment_tsp DESC"
				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getSQLParameter("POOL_ID")).value = pool_id
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters("@USERNAME").value = username
				
				oda = new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)

			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res

		end function

		public function createPool(POOL_OWNER as String, POOL_NAME as String, POOL_DESC as String, ELIGIBILITY as String, POOL_LOGO as String, POOL_BANNER as String, participate as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = ""
				dim cmd as SQLCommand

				sql = "select count(*) from fb_pools where pool_owner=@pool_owner and pool_name=@pool_name"
				cmd = new SQLCommand(sql, con)
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.VARCHAR, 50)).value = pool_owner
				cmd.parameters.add(new SQLParameter("@pool_name", SQLDbType.VARCHAR, 100)).value = pool_name

				dim c as integer = 0
				c = cmd.executescalar()
				
				if c = 0 then
					sql = "insert into fb_POOLS (POOL_OWNER, POOL_NAME, POOL_DESC, ELIGIBILITY, POOL_LOGO, POOL_BANNER) values (@pool_owner, @pool_name, @pool_desc, @eligibility, @pool_logo, @pool_banner)"
					cmd = new SQLCommand(sql, con)

					cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.VARCHAR, 50)).value = pool_owner
					cmd.parameters.add(new SQLParameter("@pool_name", SQLDbType.VARCHAR, 100)).value = pool_name
					cmd.parameters.add(new SQLParameter("@pool_desc", SQLDbType.VARCHAR, 500)).value = pool_desc
					cmd.parameters.add(new SQLParameter("@eligibility", SQLDbType.VARCHAR, 10)).value = eligibility
					cmd.parameters.add(new SQLParameter("@pool_logo", SQLDbType.VARCHAR, 255)).value = pool_logo
					cmd.parameters.add(new SQLParameter("@pool_banner", SQLDbType.VARCHAR, 255)).value = pool_banner

					cmd.executenonquery()
					if participate = "on" then
						sql = "select @@IDENTITY as pool_id"
						cmd = new sqlcommand(sql, con)
						dim oda as new sqldataadapter()
						oda.selectcommand = cmd
						dim ds as new dataset()
						oda.fill(ds)
						if ds.tables.count > 0 then
							if ds.tables(0).rows.count > 0 then
								dim pool_id as integer
								pool_id = ds.tables(0).rows(0)("pool_id")
								makesystemlog("new pool created", "pool_owner:" & pool_owner & " pool_id:" & pool_id)
								addPlayer(pool_id, pool_owner)
							end if
						end if
					end if

					res = pool_name
				else
					res = "The pool could not be created because the pool name already exists."
				end if
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
				res = ex.toString()
			end try
			return res
		end function

		Public Function ListFeeds() As dataset
			
			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				'dim con as SQLConnection
				dim parm1 as SQLParameter
				
				dim connstring as string
				connstring = myconnstring
				
				'con = new SQLConnection(connstring)
				

				sql = "select * from fb_rss_feeds"

				cmd = new SQLCommand(sql,con)

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
			end using
			catch ex as exception
				makesystemlog("Error in ListFeeds", ex.tostring())
			end try

			return res			
		End Function
		
		Public function ListPools(pool_owner as string) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				'dim con as SQLConnection
				dim parm1 as SQLParameter
				
				dim connstring as string
				connstring = myconnstring
				
				'con = new SQLConnection(connstring)
				

				sql = "select * from fb_pools where pool_owner=@pool_owner"

				cmd = new SQLCommand(sql,con)

				parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function GetPoolID(pool_name as string, pool_owner as string) as integer

			dim res as integer = -1
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				
				sql = "select min(pool_id)  from fb_pools where pool_name=@pool_name and pool_owner=@pool_owner"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.varchar, 50)).value = pool_owner
				cmd.parameters.add(new SQLParameter("@pool_name", SQLDbType.VARCHAR, 100)).value = pool_name

				res = cmd.executescalar()

			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try 
			return res
		end function

		Public function GetPoolDetails(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select * from fb_pools where pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getSQLParameter("pool_id")).value = pool_id

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function incrementviewcount(pool_id as integer, comment_id as integer) as string

			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				'dim con as SQLConnection
				dim parm1 as SQLParameter
				
				dim connstring as string
				connstring = myconnstring
				
				'con = new SQLConnection(connstring)
				

				sql = "update fb_comments set views=views + 1 where pool_id=@pool_id and comment_id=@comment_id"

				cmd = new SQLCommand(sql,con)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				cmd.Parameters.Add(New SQLParameter("@comment_id", SQLDbType.Int))
				cmd.Parameters("@comment_id").value = comment_id
				
				Dim rowsupdated As Integer = 0
				rowsupdated = cmd.executenonquery()
				If rowsupdated > 0 Then
					res = comment_id
				Else
					res = "views not updated"
				End If
			end using
			catch ex as exception
				makesystemlog("Error in incrementviewcount", ex.tostring())
			end try
			return res
		End Function
		
		Public function GetCommentDetails(pool_id as integer, comment_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				'dim con as SQLConnection
				dim parm1 as SQLParameter
				
				dim connstring as string
				connstring = myconnstring
				
				'con = new SQLConnection(connstring)
				

				sql = "select * from fb_comments where pool_id=@pool_id and comment_id=@comment_id"
				
				cmd = new SQLCommand(sql,con)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				cmd.Parameters.Add(New SQLParameter("@comment_id", SQLDbType.Int))
				cmd.Parameters("@comment_id").value = comment_id
				
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			end using
			catch ex as exception
				makesystemlog("Error in GetCommentDetails", ex.tostring())
			end try

			return res
		end function
		public function bbencode (html as string) as string
	
			dim objRegEx as RegEx
			dim objMatch as match
		
			dim pat_arraylist as arraylist = new arraylist()
			dim rep_arraylist as arraylist = new arraylist()
			dim res as string = html
			
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

			res = regex.replace(res, "\[code\](.+?)\[\/code\]", AddressOf convert_for_html, regexOptions.singleline or RegexOptions.IgnoreCase)
			
			dim i as integer
			for i = 0 to rep_arraylist.count -1
				objregex = new regex(pat_arraylist(i), regexOptions.singleline or RegexOptions.IgnoreCase)
				res = objregex.replace(res, rep_arraylist(i))
			next
			res = res.replace(system.environment.newline, "<br />" & system.environment.newline)
			
			return res
		end function
		Private Function convert_for_html(m As Match) As String
			dim re as regex = new regex("\[code\](.+?)\[\/code\]", regexOptions.singleline or RegexOptions.IgnoreCase)
			
			' Get the matched string.
			Dim x As String = m.ToString()
			x = re.replace(x,"$1")
			x = x.replace("[", "&#091;")
			x = x.replace("]", "&#093;")
			return "<table class=""code""><tr><td>Code:</td></tr><tr><td class=""code_box"">" & x &  "</td></tr></table>"
		End Function 
		
		public function GetGameDetails(pool_id as integer, game_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from fb_sched sched full outer join fb_teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join fb_teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.game_id=@game_id and sched.pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@game_id", SQLDbType.int)).value = game_id

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res) 
				
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function GetPoolGames(pool_owner as string, pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from fb_sched sched full outer join fb_teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join fb_teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id) order by sched.game_tsp"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.varchar, 50)).value = pool_owner

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
				
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function


		Public function GetPoolTeams(pool_owner as string, pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select * from fb_teams where pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id) order by team_name"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.varchar, 50)).value = pool_owner

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function GetPoolInvitations(pool_owner as string, pool_id as string) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				

				sql = "select * from fb_invites where pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id) order by email"

				cmd = new SQLCommand(sql,con)

				parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				
			end using
			catch ex as exception
				makesystemlog("Error getting pool invites", ex.tostring())
			end try

			return res

		end function
		
		Public Function SendNotice(pool_id As Integer, player_id As Integer, message As String, week_id As Integer) As String
			dim res as string  = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
			
				dim sql as string
				dim cmd as SQLCommand
				'dim con as SQLConnection
				dim parm1 as SQLParameter
				
				dim connstring as string
				connstring = myconnstring
				
				'con = new SQLConnection(connstring)
				

				sql = "select * from fb_players a full outer join fb_users b " _
				& " on a.username=b.username where a.pool_id=@pool_id and a.player_id=@player_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters("@pool_id").value = pool_id
				cmd.parameters.add(new SQLParameter("@player_id", SQLDbType.int))
				cmd.parameters("@player_id").value = player_id
				
				Dim oda As New SQLDataAdapter()
				Dim player_ds As New DataSet()
				
				oda.selectcommand = cmd
				oda.fill(player_ds)
			
				try
					Dim email As String = ""
					email = player_ds.Tables(0).rows(0)("email")
					Dim username As String = ""
					username = player_ds.Tables(0).rows(0)("username")
					
					dim fastkey as string = getrandomstring()
					sql = "insert into fb_fastkeys (username,pool_id,week_id,fastkey) " _
					& " values (@username, @pool_id, @week_id, @fastkey)"
					
					cmd = new SQLCommand(sql,con)

					cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar, 30))
					cmd.parameters("@username").value = username
					
					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters("@pool_id").value = pool_id
					
					cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int))
					cmd.parameters("@week_id").value = week_id					

					cmd.parameters.add(new SQLParameter("@fastkey", SQLDbType.varchar, 30))
					cmd.parameters("@fastkey").value = fastkey
					Dim rowsaffected As Integer = 0
					
					rowsaffected = cmd.executenonquery()
					If rowsaffected > 0 Then
						

						Dim sb As New stringbuilder()
						sb.append("This is just a friendly reminder from <a href=""http://www.smackpools.com"">http://www.smackpools.com</a> to make your football picks for Week #" & week_id & ".  <br><br>" & system.environment.newline)
						sb.append("Here is your fastpick link.<br><br>" & system.environment.newline)
						sb.append("Go to:<br /> <a href=""http://www.smackpools.com/football/makepicks.aspx?pool_id=" & pool_id & "&week_id=" & week_id & "&player_name=" & username & "&fastkey=" & fastkey & """>http://www.smackpools.com/football/makepicks.aspx?pool_id=" & pool_id & "&week_id=" & week_id & "&player_name=" & username & "&fastkey=" & fastkey & "</a> <br />to make your picks.<br /><br />" & system.environment.newline & system.environment.newline  )
						sb.append ("<br/><b>DO NOT FORWARD THIS EMAIL</b></BR> If you forward this email to someone else they will be able to use the fastpick link to change your picks for this week.  <br><br>" & system.environment.newline)
						sb.append("<br>Message from the pool administrator:<br>" & system.environment.newline)
						sb.append(bbencode(message))
						
						dim myMessage as system.Web.Mail.MailMessage = New system.Web.Mail.MailMessage()
						
						myMessage.BodyFormat = system.Web.Mail.MailFormat.Html
						myMessage.From = "chrishad95@yahoo.com"
						myMessage.To = email
						myMessage.Subject = "Football Pool Week #" & week_id 
						myMessage.Body = sb.toString()
						
						myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserver", "smtp.mail.yahoo.com")
						myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserverport", 25)
						myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusing", 2)
						myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1)
						myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusername", "chrishad95")
						myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendpassword", "househorse89")
					
						' Doesn't have to be local... just enter your
						' SMTP server's name or ip address!
						
						
						system.Web.Mail.SmtpMail.SmtpServer = "smtp.mail.yahoo.com"
						try
							SmtpMail.Send(myMessage)
						catch 		
							try
								SmtpMail.Send(myMessage)
							catch 		
								try
									SmtpMail.Send(myMessage)
								catch ex as exception
									makesystemlog("error sending notice to" & email, ex.tostring())
									res = res & "error sending notice to " & email & system.environment.newline
								end try
							end try
						end try
					End If
					
				Catch ex As exception
					makesystemlog("Error sending notice", ex.tostring())
				end try
			end using
			Catch ex As exception
				makesystemlog("Error in SendNotice", ex.tostring())
			End Try
			Return res
		End Function
		

		Private Function getrandomstring()
			'Need to create random password.		
				Dim validcharacters as String		
				validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
				dim c as char
				Thread.Sleep( 30 )
				Dim fixRand As New Random()
				dim randomstring as stringbuilder = new stringbuilder(20)
				dim i as integer
				for i = 0 to 29  
					randomstring.append(validcharacters.substring(fixRand.Next( 0, validcharacters.length ),1))
				Next
				
				return randomstring.tostring()
		End Function
		
		Public function GetPoolPlayers(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				'dim con as SQLConnection
				dim parm1 as SQLParameter
				
				dim connstring as string
				connstring = myconnstring
				
				'con = new SQLConnection(connstring)
				

				sql = "select * from fb_players where pool_id=@pool_id order by username"

				cmd = new SQLCommand(sql,con)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
				end using
				
			catch ex as exception
				makesystemlog("Error getting pool players", ex.tostring())
			end try

			return res
		end function

		public function ds_to_arraylist (ds as dataset) as System.Collections.Arraylist
			dim res as new System.Collections.Arraylist()
			try
				if ds.tables.count > 0 then
					if ds.tables(0).rows.count > 0 then
						for each drow as datarow in ds.tables(0).rows
							dim ht as new System.Collections.Hashtable()
							for each col as datacolumn in ds.tables(0).columns
								ht.add(col.ColumnName, drow(col))
							next
							res.add(ht)
						next
					end if
				end if
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public Function Getfiles(path as string) as system.collections.arraylist
			Dim res as new system.collections.arraylist()
			try
				Dim temp as String()
				if System.IO.Directory.Exists(path) then
					temp = system.io.directory.getfiles(path)
					For Each f as String In temp
						f = system.io.path.getfilename(f)
						res.add(f)
					next
				end if
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			End try
			return res
		End Function
		
		Public function GetPoolOptions(pool_id as integer) as system.Collections.Hashtable 

			Dim res As New system.Collections.Hashtable()
			try
				using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select * from fb_options where pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				dim ds as new DataSet()
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(ds)

				res.add("LONEWOLFEPICK", "off")
				res.add("WINWEEKPOINT", "off")
				res.add("HIDENPROWS", "off")
				res.add("TEAMRECORDS", "off")
				res.add("AUTOHOMEPICKS", "off")
				res.add("HIDESTANDINGS", "off")
				res.add("HIDECOMMENTS", "off")
				
				if ds.tables.count > 0 then
					if ds.tables(0).rows.count > 0 then
						for each option_row as datarow in ds.tables(0).rows
							res(option_row("OPTIONNAME")) = option_row("OPTIONVALUE")
						next
					end if
				end if 
				end using	
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		End Function
		
		Public Function getTeamRecord(pool_id as integer, team_id as integer) as String
			Dim res as String = ""
			try

				using con as new SQLConnection(myconnstring)
				con.open()
				Dim cmd as SQLCommand
				Dim sql as String

				sql = "select a.game_id, b.away_score, b.home_score, c.team_id as away_id, d.team_id as home_id from fb_sched a full outer join fb_scores b on a.pool_id=b.pool_id and a.game_id=b.game_id full outer join fb_teams c on a.pool_id=c.pool_id and a.away_id=c.team_id full outer join fb_teams d on a.pool_id=d.pool_id and a.home_id=d.team_id where a.pool_id=@pool_id and (d.team_id=@team_id or c.team_id=@team_id)"

				cmd = new SQLCommand(sql, con)

				cmd.parameters.add("pool_id", SQLDbType.int).value = pool_id
				cmd.parameters.add("@team_id", SQLDbType.int).value = team_id

	
				Dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				Dim ds as new dataset()
				oda.fill(ds)


				Dim wins as integer = 0
				Dim losses as integer = 0
				Dim ties as integer = 0

				For Each drow as datarow In ds.tables(0).rows
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
					End if
				Next
				res =  "" & wins & "-" & losses
				If ties > 0 Then
					res = res & "-" & ties
				End if
				end using
			catch ex as exception
				makesystemlog("Error in getTeamRecord", ex.tostring())
			End try
			return res
		End Function

		Public function UpdatePool(POOL_ID as INTEGER, POOL_OWNER as String, POOL_NAME as String, POOL_DESC as String, ELIGIBILITY as String, POOL_LOGO as String, POOL_BANNER as String, scorer as string) as string
			dim res as string = ""
			if pool_name.trim() = "" then
				return "The pool name cannot be blank."	
			end if
			try
				using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = ""
				dim cmd as SQLCommand
				
				' find any pools owned by this user that already have this name and are not this pool (pool_id)
				sql = "select count(*) from fb_pools where pool_name=@pool_name and pool_owner=@pool_owner and pool_id<>@pool_id"
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@pool_name", SQLDbType.varchar, 100)).value = pool_name
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.varchar, 50)).value = pool_owner

				dim count as integer = 0
				count = cmd.executescalar()

				if count = 0 then	
					sql = "update fb_pools set POOL_NAME=@pool_name, POOL_DESC=@pool_desc, POOL_TSP=@pool_tsp, ELIGIBILITY=@eligibility, POOL_LOGO=@pool_logo, POOL_BANNER=@pool_banner , scorer=@scorer where POOL_ID=@pool_id and pool_owner=@pool_owner"
					cmd = new SQLCommand(sql, con)

					cmd.parameters.add(new SQLParameter("@pool_name", SQLDbType.VARCHAR, 100))
					cmd.parameters.add(new SQLParameter("@pool_desc", SQLDbType.VARCHAR, 3000))
					cmd.parameters.add(new SQLParameter("@pool_tsp", SQLDbType.datetime))
					cmd.parameters.add(new SQLParameter("@eligibility", SQLDbType.VARCHAR, 10))
					cmd.parameters.add(new SQLParameter("@pool_logo", SQLDbType.VARCHAR, 255))
					cmd.parameters.add(new SQLParameter("@pool_banner", SQLDbType.VARCHAR, 255))
					cmd.parameters.add(new SQLParameter("scorer", SQLDbType.VARCHAR, 30))

					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.VARCHAR, 50))

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
				else
					res = "The pool details were not changed becuase a pool already exists with this name."
				end if
				end using
			catch ex as exception
				res = ex.toString()
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function CreateTeam(TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
				if isowner(pool_id, pool_owner) then
					using con as new SQLConnection(myconnstring)
						con.open()
						dim sql as string = ""
						dim cmd as SQLCommand

						sql = "select count(*) from fb_teams where pool_id=@pool_id and (upper(team_name) = @team_name or upper(team_shortname) = @team_shortname)"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@team_name", sqLDbType.VARCHAR, 40)).value = team_name.toUpper()
						cmd.parameters.add(new SQLParameter("@team_shortname", SQLDbType.VARCHAR, 5)).value = team_shortname.toupper()

						dim teamcount as integer = 0
						teamcount = cmd.executescalar()

						if teamcount = 0 then

							sql = "insert into fb_teams(TEAM_NAME, TEAM_SHORTNAME, URL, POOL_ID) values ( @team_name, @team_shortname, @url, @pool_id)"
							cmd = new SQLCommand(sql, con)

							cmd.parameters.add(new SQLParameter("@team_name", sqLDbType.VARCHAR, 40)).value = team_name
							cmd.parameters.add(new SQLParameter("@team_shortname", SQLDbType.VARCHAR, 5)).value = team_shortname
							cmd.parameters.add(new SQLParameter("@url", sqldBtYPe.VARCHAR, 200)).value = url
							cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
							cmd.executenonquery()
							res = "Team: " & team_name & " was created."
						else
							res = "Team already exists with this name."
						end if
					end using
				end if
			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = "Team already exists for this pool."
				else
					res = ex.message
					dim st as new System.Diagnostics.StackTrace() 
					makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
				end if

			end try
			return res
		end function
		
		Public function InvitePreviousPlayer(POOL_ID as INTEGER, username as string, player_name as string)

			dim res as string = ""
			try
				If isowner(pool_id:=pool_id, pool_owner:=username) then
					dim invite_key as string = createinvitekey()
					dim email as string = GetEmailAddress(player_name:=player_name)
					res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
					if res = email then
						sendinvite(email:=email, invite_key:=invite_key, pool_id:=pool_id, username:=username)
					end if
					res = "SUCCESS"
				End if
			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = "duplicate row error."
				else
					res = ex.message
					makesystemlog("Error in InvitePreviousPlayer", ex.tostring())
				end if

			end try
			return res
		end function
		
		
		Public function InvitePlayer(POOL_ID as INTEGER, username as string, email as string)

			dim res as string = ""
			try
				If isowner(pool_id:=pool_id, pool_owner:=username) then
					dim invite_key as string = createinvitekey()

					res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
					if res = email then
						sendinvite(email:=email, invite_key:=invite_key, pool_id:=pool_id, username:=username)
					end if
					res = "SUCCESS"
				Else
					If isplayer(pool_id:=pool_id, player_name:=username) Then
						Dim pool_ds as new system.data.dataset()
						pool_ds = getpooldetails(pool_id:=pool_id)

						If pool_ds.tables.count > 0 Then
							If pool_ds.tables(0).rows.count > 0 Then
								If pool_ds.tables(0).rows(0)("ELIGIBILITY") = "OPEN" Then
								
									dim invite_key as string = createinvitekey()

									res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
									if res = email then
										sendinvite(email:=email, invite_key:=invite_key, pool_id:=pool_id, username:=username)
									end if
									res = "SUCCESS"
								End if
							End if
						End if
					End if
				End if

			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = ex.message
					dim st as new System.Diagnostics.StackTrace() 
					makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
				end if
			end try
			return res
		end function
		
		Public sub SendInvite(email as string, invite_key as string, pool_id as string, username as string)

			dim sb as new stringbuilder()
			Dim pool_ds as new system.data.dataset()
			pool_ds = getpooldetails(pool_id:=pool_id)

			
			If pool_ds.tables.count > 0 Then
				If pool_ds.tables(0).rows.count > 0 Then

					if not pool_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
						dim banner_image as string = getbannerimage(pool_id)
						sb.append("<img src=""" & banner_image & """><br />"  & system.environment.newline)

					end if
					if username <> 	pool_ds.tables(0).rows(0)("pool_owner") then
	
						sb.append("You have been invited by " _
							& username _ 
							& " to participate in the pool<br /><br />" _
							& pool_ds.tables(0).rows(0)("pool_name") _ 
							& "<br /><br />created by " _ 
							& pool_ds.tables(0).rows(0)("pool_owner") _ 
							& ".  <br><br>" & system.environment.newline)
					else
					
						sb.append("You have been invited " _
							& " to participate in the pool<br /><br />" _
							& pool_ds.tables(0).rows(0)("pool_name") _ 
							& "<br /><br />created by " _ 
							& pool_ds.tables(0).rows(0)("pool_owner") _ 
							& ".  <br><br>" & system.environment.newline)
					end if
					dim desc as string = ""
					if not pool_ds.tables(0).rows(0)("pool_desc") is dbnull.value then
						desc = pool_ds.tables(0).rows(0)("pool_desc")
					end if

					sb.append("<h3>Description:</h3>" _ 
						& bbencode(desc)  _ 
						& "<br><br>"  & system.environment.newline)
					
					sb.append("To accept the invitation please visit the following link.<br><br>" & system.environment.newline)
					sb.append("Go to:<br /> <a href=""http://www.smackpools.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & """>http://www.smackpools.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & "</a> <br /><br /><br />" & system.environment.newline & system.environment.newline  )
					
					sb.append("You will need an account with this site (and be logged in) to accept the invitation.  If you don't have an account you should get one <a href=""http://www.smackpools.com/football/register.aspx"">here</a> first.<br /><br />" & system.environment.newline)

					sb.append("Note: If you already have an account on rasputin.dnsalias.com, you can user your username and password from that site.<br /><br />" & system.environment.newline)
					
					sb.append ("Thanks,<br />" & system.environment.newline & "Chris<br><br>" & system.environment.newline)
					
					sendemail(email, "Invitation to " & pool_ds.tables(0).rows(0)("pool_name"), sb.tostring())
				End if
			End if
		end sub

		Public function CreateInviteKey()

			'Need to create random password.
			Dim validcharacters as String
			
			validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
			
			dim c as char
			Thread.Sleep( 30 )
			
			Dim fixRand As New Random()
			dim randomstring as stringbuilder = new stringbuilder(20)
			
			
			dim i as integer
			for i = 0 to 29    
			
				randomstring.append(validcharacters.substring(fixRand.Next( 0, validcharacters.length ),1))
				
				
			next

			return randomstring.tostring()
		end function


		Public function CreateInvite(POOL_ID as INTEGER, EMAIL as String, INVITE_KEY as String, INVITE_TSP as datetime) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "insert into fb_invites(POOL_ID, EMAIL, INVITE_KEY, INVITE_TSP) values (@pool_id, @email, @invite_key, @invite_tsp)"
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@EMAIL", SQLDbType.VARCHAR, 255))
				cmd.parameters.add(new SQLParameter("@INVITE_KEY", SQLDbType.VARCHAR, 40))
				cmd.parameters.add(new SQLParameter("@INVITE_TSP", SQLDbType.datetime))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@EMAIL").value = EMAIL
				cmd.parameters("@INVITE_KEY").value = INVITE_KEY
				cmd.parameters("@INVITE_TSP").value = INVITE_TSP
				cmd.executenonquery()
				res = email
			end using
			catch ex as exception
				res =  ex.toString()
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function DeleteInvite(POOL_ID as INTEGER, EMAIL as String) as string
			dim res as string = "FAILURE"
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "delete from fb_invites where pool_id=@pool_id and email=@email"
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@EMAIL", SQLDbType.VARCHAR, 255))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@EMAIL").value = EMAIL

				cmd.executenonquery()
				res = "SUCCESS"
			end using
			catch ex as exception
				res =  ex.toString()
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function ImportGame(game_id as INTEGER, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim sql as string = ""

					sql = "select a.*, b.team_name as home_team, c.team_name as away_team, b.team_shortname as home_team_shortname, c.team_shortname as away_team_shortname from fb_copy_scheds a left join fb_copy_teams b on a.home_id=b.team_id left join fb_copy_teams c on a.away_id=c.team_id where a.game_id=@game_id"


					dim cmd as SQLCommand = new SQLCommand(sql, con)
					dim rowsupdated as integer

					cmd.parameters.add(new SQLParameter("@game_id", SQLDbType.int))
					cmd.parameters("@game_id").value = game_id

					dim game_ds as new dataset()
					dim oda as new SQLDataAdapter()
					oda.selectcommand = cmd
					oda.fill(game_ds)
					try
						dim game_tsp as datetime
						dim home_teamname as string
						dim away_teamname as string

						dim home_team_id as integer
						dim away_team_id as integer

						dim week_id as integer
						game_tsp = 		game_ds.tables(0).rows(0)("game_tsp")
						home_teamname = game_ds.tables(0).rows(0)("home_team")
						away_teamname = game_ds.tables(0).rows(0)("away_team")
						home_team_id = game_ds.tables(0).rows(0)("home_id")
						away_team_id = game_ds.tables(0).rows(0)("away_id")
						week_id = 		game_ds.tables(0).rows(0)("week_id")
						sql = "select * from fb_teams where pool_id=@pool_id and team_name in (@away, @home)"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id"))
						cmd.parameters.add(new SQLParameter("@away", SQLDbType.varchar))
						cmd.parameters.add(new SQLParameter("@home", SQLDbType.varchar))

						cmd.parameters("@pool_id").value = pool_id
						cmd.parameters("@home").value = home_teamname
						cmd.parameters("@away").value = away_teamname 

						dim teams_ds as new dataset()
						oda.selectcommand = cmd
						oda.fill(teams_ds)

						dim pool_home_id as integer
						dim pool_away_id as integer

						dim temprows as datarow()
						temprows = teams_ds.tables(0).select("team_name='" & home_teamname & "'")
						if temprows.length = 0 then
							makesystemlog("debug", "team not found for pool_id.  team_name:" & home_teamname)	
							ImportTeam(home_team_id, pool_id, pool_owner)
						end if

						temprows = teams_ds.tables(0).select("team_name='" & away_teamname & "'")
						if temprows.length = 0 then
							makesystemlog("debug", "team not found for pool_id.  team_name:" & away_teamname)	
							ImportTeam(away_team_id, pool_id, pool_owner)
						end if

						oda.fill(teams_ds)

						temprows = teams_ds.tables(0).select("team_name='" & home_teamname & "'")
						if temprows.length = 0 then
							makesystemlog("debug", "team not found again for pool_id.  team_name:" & home_teamname)	
						else
							pool_home_id = temprows(0)("team_id")
						end if

						temprows = teams_ds.tables(0).select("team_name='" & away_teamname & "'")
						if temprows.length = 0 then
							makesystemlog("debug", "team not found again for pool_id.  team_name:" & away_teamname)	
						else
							pool_away_id = temprows(0)("team_id")
						end if

						sql = "insert into fb_sched (pool_id, week_id, home_id, away_id, game_tsp) values (@pool_id, @week_id, @home_id, @away_id, @game_tsp)"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id"))
						cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("@home_id", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("@away_id", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("@game_tsp", SQLDbType.datetime))

						cmd.parameters("@pool_id").value = pool_id
						cmd.parameters("@week_id").value = week_id
						cmd.parameters("@home_id").value = pool_home_id
						cmd.parameters("@away_id").value = pool_away_id
						cmd.parameters("@game_tsp").value = game_tsp
						rowsupdated = cmd.executenonquery()


					catch ex as exception
						makesystemlog("Error in importgame", ex.tostring())
					end try


					if rowsupdated > 0 then
					else
						res = "Game was not imported."
					end if

				else
					res = "No Pools found for " & pool_owner
				end if
			end using
			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = "Team already exists for this pool."
				else
					res = ex.message
					makesystemlog("Error in Import Team", ex.tostring())
				end if
			end try
			return res
		end function

		Public function ImportTeam(TEAM_ID as INTEGER, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim sql as string = ""

					sql = "insert into fb_teams (pool_id, team_name, team_shortname) select " & pool_id & ", team_name, team_shortname from fb_copy_teams where team_id=@team_id"

					dim cmd as SQLCommand = new SQLCommand(sql, con)
					dim rowsupdated as integer

					cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int))
					cmd.parameters("@TEAM_ID").value = TEAM_ID
					rowsupdated = cmd.executenonquery()

					if rowsupdated > 0 then
					else
						res = "Team was not imported."
					end if

				else
					res = "No Pools found for " & pool_owner
				end if
			end using
			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = "Team already exists for this pool."
				else
					res = ex.message
					dim st as new System.Diagnostics.StackTrace() 
					makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
				end if
			end try
			return res
		end function

		public Function DeleteGame(game_id as integer, pool_id as integer, pool_owner as string) as string
			dim res as string = "Failed to delete game completely."
			try
				using con as new SQLConnection(myconnstring)
					con.open()
					if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
						dim sql as string = ""
						dim rowsupdated as integer = 0
						dim cmd as SQLCommand

						sql = "delete from fb_games where pool_id=@pool_id and game_id=@game_id"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@game_id", SQLDbType.int)).value = game_id
						rowsupdated = cmd.executenonquery()

						if rowsupdated > 0 then
							res = "Successfully deleted game:" & game_id
						else
							res = "Zero games found for game:" & game_id
						end if

						sql = "delete from fb_picks where pool_id=@pool_id and game_id=@game_id"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@game_id", SQLDbType.int)).value = game_id
						rowsupdated = cmd.executenonquery()

						if rowsupdated > 0 then
							res = res & " Successfully deleted " & rowsupdated & " picks for game:" & game_id
						else
							res = res & " Zero picks deleted for game:" & game_id
						end if

						sql = "delete from fb_scores where pool_id=@pool_id and game_id=@game_id"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@game_id", SQLDbType.int)).value = game_id
						rowsupdated = cmd.executenonquery()

						if rowsupdated > 0 then
							res = res & " Successfully deleted " & rowsupdated & " scores for game:" & game_id
						else
							res = res & " Zero scores deleted for game:" & game_id
						end if

						sql = "delete from fb_tiebreakers where pool_id=@pool_id and game_id=@game_id"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@game_id", SQLDbType.int)).value = game_id
						rowsupdated = cmd.executenonquery()
						if rowsupdated > 0 then
							res = res & " Successfully deleted " & rowsupdated & " tiebreakers for game:" & game_id
						else
							res = res & " Zero tiebreakers deleted for game:" & game_id
						end if
					else
						res = "Invalid pool/owner."
					end if

				end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function DeleteTeam(TEAM_ID as INTEGER, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
				using con as new SQLConnection(myconnstring)
					con.open()
					if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
						dim sql as string = ""
						dim rowsupdated as integer = 0
						dim cmd as SQLCommand

						sql = "delete from fb_teams where pool_id=@pool_id and team_id=@team_id"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int)).value = team_id
						rowsupdated = cmd.executenonquery()

						if rowsupdated > 0 then
							res = "Successfully deleted " & rowsupdated & " teams for team:" & team_id
						else
							res = res & "Zero teams deleted for team:" & team_id
						end if

						sql = "select game_id from fb_games where pool_id=@pool_id and (away_id=@team_id or home_id=@team_id)"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int)).value = team_id

						dim da as new SQLDataAdapter()
						da.selectcommand = cmd
						dim ds as new dataset()
						da.fill(ds)

						try
							for each drow as datarow in ds.tables(0).rows
								res = res & deletegame(drow("game_id"), pool_id, pool_owner)
							next
						catch
						end try

					else
						res = res & "Invalid pool/owner."
					end if
				end using
			catch ex as exception
				res = res & ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function UpdateTeam(TEAM_ID as INTEGER, TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim sql as string = ""

					sql = "update fb_teams set TEAM_NAME=@TEAM_NAME, TEAM_SHORTNAME=@TEAM_SHORTNAME, URL=@URL where POOL_ID=@POOL_ID and TEAM_ID=@TEAM_ID"
					dim cmd as SQLCommand = new SQLCommand(sql, con)
					dim rowsupdated as integer

					cmd.parameters.add(new SQLParameter("@TEAM_NAME", SQLDbType.VARCHAR, 40)).value = team_name
					cmd.parameters.add(new SQLParameter("@TEAM_SHORTNAME", SQLDbType.VARCHAR, 5)).value = team_shortname
					cmd.parameters.add(new SQLParameter("@URL", SQLDbType.VARCHAR, 200)).value = url
					cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
					cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int)).value = team_id
					rowsupdated = cmd.executenonquery()

					if rowsupdated > 0 then
						res = team_name
					else
						res = "Team was not updated."
					end if

				else
					res = "No Pools found for " & pool_owner
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function GetTiebreakers(pool_id as integer, pool_owner as string) as dataset
			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim sql as string
					dim cmd as SQLCommand
					
					sql = "select * from fb_tiebreakers where pool_id=@pool_id"

					cmd = new SQLCommand(sql,con)
					cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

					dim oda as new SQLDataAdapter()
					oda.selectcommand = cmd
					oda.fill(res) 
					
				end if
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function ListWeeks(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				
				sql = "select distinct week_id from fb_sched where pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function GetPreviousPlayers(pool_owner as string) as System.Collections.Arraylist

			dim res as new System.Collections.Arraylist()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select distinct username from fb_players a where a.pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner)"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.varchar)).value = pool_owner

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				dim ds as new dataset()
				oda.fill(ds)
				if ds.tables.count > 0 then
					if ds.tables(0).rows.count > 0 then
						for each drow as datarow in ds.tables(0).rows
							res.add(drow("username"))
						next
					end if
				end if
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function


		Public function GetPlayers(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select * from fb_players where pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function AddGames(POOL_ID as INTEGER, pool_owner as string, games_text as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim lines as string()
					lines = games_text.split(system.environment.newline)
					dim res_total as string = ""
					dim success as boolean = true

					for each line as string in lines
						if line.trim() <> "" then
							dim elements as string()
							elements = line.split(",")
							dim myres as string
							try
								myres = creategame(week_id:=elements(0), _
									away_id:=lookupteam(pool_id:=pool_id, team_name:=elements(1)), _
									home_id:=lookupteam(pool_id:=pool_id, team_name:=elements(2)), _
									game_tsp:= elements(3), _
									pool_id:=pool_id, _
									game_url:="", _
									pool_owner:=pool_owner)
							catch ex as exception
								success = false
								makesystemlog("error adding game from batch", ex.tostring())
								res_total = res_total  & "Error adding game: " & line & system.environment.newline
							end try
						end if
					next
					if success then
						res = pool_owner
					else
						res = res_total
					end if
					
				else
					res = "invalid pool_id for " & pool_owner
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function lookupteam(pool_id as integer, team_name as string) as string
			dim res as string = "NO TEAM FOUND"
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "select team_id from fb_teams where (team_name=@team_name or UPPER(team_shortname)=@team_shortname) and pool_id=@pool_id"
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@TEAM_NAME", SQLDbType.VARCHAR, 40))
				cmd.parameters.add(new SQLParameter("@TEAM_shortname", SQLDbType.VARCHAR))
				cmd.parameters.add(getsqlparameter("pool_id"))

				cmd.parameters("@TEAM_NAME").value = TEAM_NAME
				cmd.parameters("@TEAM_shortname").value = TEAM_NAME.toupper()
				cmd.parameters("@POOL_ID").value = POOL_ID
				
				dim oda as new SQLDataAdapter()
				dim ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(ds)

				if ds.tables.count > 0 then
					if ds.tables(0).rows.count > 0 then
						res = ds.tables(0).rows(0)("team_id")
					end if
				end if
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("Error looking up team", ex.tostring())
			end try
			return res
		end function

		Public function CreateGame(WEEK_ID as INTEGER, HOME_ID as INTEGER, AWAY_ID as INTEGER, GAME_TSP as datetime, GAME_URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if away_id = home_id then
					res = "The game could not be created because a team cannot play itself."
				else

					if isowner(pool_owner:=pool_owner, pool_id:=pool_id) then

							dim sql as string = "insert into fb_sched (WEEK_ID, HOME_ID, AWAY_ID, GAME_TSP, GAME_URL, POOL_ID) values (@WEEK_ID, @HOME_ID, @AWAY_ID, @GAME_TSP, @GAME_URL, @POOL_ID)"

							dim cmd as SQLCommand = new SQLCommand(sql, con)

							cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
							cmd.parameters.add(new SQLParameter("@HOME_ID", SQLDbType.int))
							cmd.parameters.add(new SQLParameter("@AWAY_ID", SQLDbType.int))
							cmd.parameters.add(new SQLParameter("@GAME_TSP", SQLDbType.datetime))
							cmd.parameters.add(new SQLParameter("@GAME_URL", SQLDbType.VARCHAR, 300))
							cmd.parameters.add(getsqlparameter("pool_id"))
							cmd.parameters("@WEEK_ID").value = WEEK_ID
							cmd.parameters("@HOME_ID").value = HOME_ID
							cmd.parameters("@AWAY_ID").value = AWAY_ID
							cmd.parameters("@GAME_TSP").value = GAME_TSP
							cmd.parameters("@GAME_URL").value = GAME_URL
							cmd.parameters("@POOL_ID").value = POOL_ID
							cmd.executenonquery()
							res = pool_owner
					else
						res = "invalid pool_id for " & pool_owner
					end if
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function MakeComment(POOL_ID as INTEGER, USERNAME as String, COMMENT_TEXT as String, COMMENT_TITLE as String) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string 

				dim cmd as SQLCommand 
				sql = "insert into fb_comments(POOL_ID, USERNAME, COMMENT_TEXT, COMMENT_TSP,  COMMENT_TITLE, views) values (@pool_id, @username, @comment_text, @comment_tsp, @comment_title, 0)"
				
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@COMMENT_TEXT", SQLDbType.text))
				cmd.parameters.add(new SQLParameter("@COMMENT_TSP", SQLDbType.datetime))
				cmd.parameters.add(new SQLParameter("@COMMENT_TITLE", SQLDbType.VARCHAR, 200))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@COMMENT_TEXT").value = COMMENT_TEXT
				cmd.parameters("@COMMENT_TSP").value = system.datetime.now
				cmd.parameters("@COMMENT_TITLE").value = COMMENT_TITLE
				cmd.executenonquery()
				res = username
			end using

			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function


		public function MakeComment(POOL_ID as INTEGER, USERNAME as String, COMMENT_TEXT as String, COMMENT_TITLE as String, ref_id as integer) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string 

				dim cmd as SQLCommand 


				sql = "insert into fb_comments(POOL_ID, USERNAME, COMMENT_TEXT, COMMENT_TSP,  COMMENT_TITLE, ref_id, views) values (@pool_id, @username, @comment_text, @comment_tsp, @comment_title, @ref_id, 0)"
				
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@COMMENT_TEXT", SQLDbType.text))
				cmd.parameters.add(new SQLParameter("@COMMENT_TSP", SQLDbType.datetime))
				cmd.parameters.add(new SQLParameter("@COMMENT_TITLE", SQLDbType.VARCHAR, 200))
				cmd.parameters.add(new SQLParameter("@ref_id", SQLDbType.int))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@COMMENT_TEXT").value = COMMENT_TEXT
				cmd.parameters("@COMMENT_TSP").value = system.datetime.now
				cmd.parameters("@COMMENT_TITLE").value = COMMENT_TITLE
				cmd.parameters("@ref_id").value = ref_id
				cmd.executenonquery()
				res = username
			end using

			catch ex as exception
				res = ex.message
				makesystemlog("Error in MakeComment", ex.tostring())
			end try
			return res
		end function

		Public Function UpdateComment(pool_id As Integer, comment_id As Integer, COMMENT_TEXT As String, COMMENT_TITLE As String) As String
			
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string 

				dim cmd as SQLCommand 


				sql = "update fb_comments set comment_title=@comment_title, comment_text=@comment_text where pool_id=@pool_id and comment_id=@comment_id"
				
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@COMMENT_TITLE", SQLDbType.VARCHAR, 200))
				cmd.parameters.add(new SQLParameter("@COMMENT_TEXT", SQLDbType.text))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@comment_id", SQLDbType.int))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@COMMENT_TEXT").value = COMMENT_TEXT
				cmd.parameters("@COMMENT_TITLE").value = COMMENT_TITLE
				cmd.parameters("@comment_id").value = comment_id
				cmd.executenonquery()
				res = comment_id

			end using
			catch ex as exception
				res = ex.message
				makesystemlog("Error in UpdateComment", ex.tostring())
			end try
			return res
		End Function


		Public function UpdateGame(GAME_ID as INTEGER, WEEK_ID as INTEGER, HOME_ID as INTEGER, AWAY_ID as INTEGER, GAME_TSP as datetime, GAME_URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim sql as string = "update fb_sched set WEEK_ID=@WEEK_ID, HOME_ID=@HOME_ID, AWAY_ID=@AWAY_ID, GAME_TSP=@GAME_TSP, GAME_URL=@GAME_URL where GAME_ID=@GAME_ID and pool_id=@pool_id"
					dim cmd as SQLCommand = new SQLCommand(sql, con)

					cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@HOME_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@AWAY_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@GAME_TSP", SQLDbType.datetime))
					cmd.parameters.add(new SQLParameter("@GAME_URL", SQLDbType.VARCHAR, 300))
					cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters("@GAME_ID").value = GAME_ID
					cmd.parameters("@WEEK_ID").value = WEEK_ID
					cmd.parameters("@HOME_ID").value = HOME_ID
					cmd.parameters("@AWAY_ID").value = AWAY_ID
					cmd.parameters("@GAME_TSP").value = GAME_TSP
					cmd.parameters("@GAME_URL").value = GAME_URL
					cmd.parameters("@POOL_ID").value = POOL_ID

					cmd.executenonquery()
					res = pool_owner
				else
					res = "Invalid pool_id."
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		Public function isScorer(pool_id as integer, username as string) as boolean
			dim res as boolean = false
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select count(*)  from fb_pools where scorer=@scorer and pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)

				parm1 = new SQLParameter("@scorer", SQLDbType.varchar, 50)
				parm1.value = username
				cmd.parameters.add(parm1)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				dim pool_count as integer = 0
				pool_count = cmd.executescalar()
				if pool_count > 0 then
					res = true
				end if
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res

		end function
		public function getBannerImage(pool_id as integer) as string
			dim res as string = ""
			try
				using con as new SQLConnection(myconnstring)
					con.open()
					dim sql as string
					dim cmd as SQLCommand
					dim parm1 as SQLParameter

					sql = "select pool_banner from fb_pools where pool_id=@pool_id"
					cmd = new SQLCommand(sql,con)
					cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
					res = cmd.executescalar()
				end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		Public function isNotOwner(pool_id as integer, pool_owner as string) as boolean
			return (not isowner(pool_id, pool_owner))
		end function

		Public function isOwner(pool_id as integer, pool_owner as string) as boolean
			dim res as boolean = false
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter

				sql = "select count(*)  from fb_pools where pool_owner=@pool_owner and pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)

				parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				dim pool_count as integer = 0
				pool_count = cmd.executescalar()
				if pool_count > 0 then
					res = true
				end if
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res

		end function
		
		Public Function SetFeed(pool_id As Integer, feed_id As Integer) As String
			
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "update fb_pools set feed_ID=@feed_id where pool_id=@pool_id"

				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@FEED_ID", SQLDbType.int))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@FEED_ID").value = FEED_ID
				
				dim rowsaffected as integer = 0
				rowsaffected = cmd.executenonquery()

				if rowsaffected > 0 then
					res = pool_id
				else
					res = "Feed was not set"
				end if
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("error in SetFeed", ex.toString())
			end try
			return res
		End Function
		
		Public Function SetOption(pool_id As Integer, optionname as string, optionvalue as string) As String
			
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim sql as string = "update fb_options set optionvalue=@optionvalue where pool_id=@pool_id and optionname=@optionname"

				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@OPTIONVALUE", SQLDbType.varchar, 255))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@OPTIONNAME", SQLDbType.varchar, 30))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@OPTIONVALUE").value = OPTIONVALUE
				cmd.parameters("@OPTIONNAME").value = OPTIONNAME
				
				dim rowsaffected as integer = 0
				rowsaffected = cmd.executenonquery()

				if rowsaffected > 0 then
					res = pool_id
				else
					sql = "insert into fb_options (optionvalue, pool_id, optionname) values (@optionvalue, @pool_id, @optionname)"
					
	
					cmd = new SQLCommand(sql, con)
	
					cmd.parameters.add(new SQLParameter("@OPTIONVALUE", SQLDbType.varchar, 255))
					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters.add(new SQLParameter("@OPTIONNAME", SQLDbType.varchar, 30))
					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@OPTIONVALUE").value = OPTIONVALUE
					cmd.parameters("@OPTIONNAME").value = OPTIONNAME
					rowsaffected = cmd.executenonquery()
					If rowsaffected > 0 Then
						res = pool_id
					Else
						res = "Failed to update option"
					End If
				end if
				if optionname = "AUTOHOMEPICKS" then
					updatescoretsp(pool_id)
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		End Function

		public sub UpdateScoreTsp(pool_id as integer)
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim sql as string
				dim cmd as SQLCommand

				sql = "update fb_pools set updatescore_tsp = CURRENT_TIMESTAMP where pool_id=@pool_id"
				cmd = new SQLCommand(sql, con)
	
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.executenonquery()

			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
		end sub

		Public Function GetFeed(pool_id As Integer, xslfile as string) As String
			
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select * from fb_rss_feeds where feed_id=(select feed_id from fb_pools where pool_id=@pool_id)"

				cmd = new SQLCommand(sql,con)
				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new SQLDataAdapter()
				dim ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(ds)
				If ds.Tables.Count > 0 Then
					If ds.Tables(0).rows.count > 0 Then
						res = GetRSSFeed(feed_url:=ds.Tables(0).rows(0)("feed_url"), xslfile:=xslfile)
					End If
				End If
			end using

			catch ex as exception
				makesystemlog("error in GetFeed", ex.tostring())
			end try

			return res
		End Function
		
		Public Function GetRSSFeed(feed_url As String, xslfile As String) as string
			

			' Using a live RSS feed... could also use a cached XML file.
			Dim strXmlSrc  As String = feed_url
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
			Dim myStringWriter  As StringWriter  = New StringWriter(myStringBuilder)
	
			' Call the Transform method of the XslTransform object passing it
			' our input via the XmlDocument and getting output via the StringWriter.
			myXslDoc.Transform(myXmlDoc, Nothing, myStringWriter)
	
			' Since I've got the page set to cache, I tag on a little
			' footer indicating when the page was actually built.
			'myStringBuilder.Append(vbCrLf & "<p><em>Cached at: " & Now() & "</em></p>" & vbCrLf)
	
			' Take our resulting HTML and display it via an ASP.NET
			' literal control.
			return myStringBuilder.ToString
			
		End Function
		
		Public function UpdateTiebreaker(POOL_ID as INTEGER, WEEK_ID as INTEGER, GAME_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim sql as string = "update fb_tiebreakers set GAME_ID=@GAME_ID, tb_tsp=@tb_tsp where pool_id=@pool_id and week_id=@week_id"

					dim cmd as SQLCommand = new SQLCommand(sql, con)

					cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@TB_TSP", SQLDbType.datetime))
					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@WEEK_ID").value = WEEK_ID
					cmd.parameters("@GAME_ID").value = GAME_ID
					cmd.parameters("@TB_TSP").value = system.datetime.now
					
					dim rowsaffected as integer = 0
					rowsaffected = cmd.executenonquery()

					if rowsaffected = 0 then

						sql = "insert into fb_tiebreakers(POOL_ID, WEEK_ID, GAME_ID, TB_TSP) values (@pool_id, @week_id, @game_id, @tb_tsp)"
						cmd = new SQLCommand(sql, con)

						cmd.parameters.add(getsqlparameter("pool_id"))
						cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("@TB_TSP", SQLDbType.datetime))
						cmd.parameters("@POOL_ID").value = POOL_ID
						cmd.parameters("@WEEK_ID").value = WEEK_ID
						cmd.parameters("@GAME_ID").value = GAME_ID
						cmd.parameters("@TB_TSP").value = system.datetime.now
						rowsaffected = cmd.executenonquery()
					end if
					if rowsaffected > 0 then
						res = pool_owner
					else
						res = "Tie breaker was not set"
					end if

				else
					res = "invalid pool_id"
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function isvalidfastkey(fastkey as string, pool_id as integer, week_id as integer, player_name as string) as boolean
			dim res as boolean = false

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select count(*) from fb_fastkeys where username=@username and week_id=@week_id and fastkey=@fastkey and pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 30))
				cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@FASTKEY", SQLDbType.CHAR, 30))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters("@USERNAME").value = player_name
				cmd.parameters("@WEEK_ID").value = WEEK_ID
				cmd.parameters("@FASTKEY").value = FASTKEY
				cmd.parameters("@POOL_ID").value = POOL_ID

				dim fk_count as integer = 0
				fk_count = cmd.executescalar()
				if fk_count > 0 then
					res = True
				Else
					makesystemlog("invalid fastkey", "fastkey=" & fastkey & ", week_id=" & week_id & ", pool_id=" & pool_id & ", player_name=" & player_name)
					
				end if
			
				
				return res
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try


			return res
		end function

		public function GetUsernameForEmail(email  as string) as string
			Dim res as String = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "select username from fb_users where UPPER(email)=@email"
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@email", SQLDbType.VARCHAR, 50)).value = email.toupper() 
				res = cmd.executescalar()
			end using
			catch ex as exception
				res = ""
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function GetEmailAddress(player_name as string) as string
			Dim res as String = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "select email from fb_users where username=@username"
				dim cmd as SQLCommand = new SQLCommand(sql, con)
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters("@USERNAME").value = player_name
				res = cmd.executescalar()
			end using
			catch ex as exception
				res = ""
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res 
		end function
		
		public function NotifyPlayer(player_name as string, subject as string, body as string, pool_id as string) as string
			Dim res as String = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "select email from fb_users where username=@username"

				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters("@USERNAME").value = player_name

				dim email as string = ""
				email = cmd.executescalar()

				dim pool_name as string
				sql = "select pool_name from fb_pools where pool_id=@pool_id"
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters("@pool_id").value = pool_id
				pool_name = cmd.executescalar()
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("error updating pick", ex.toString())
			end try
			return res

		end function

		public function UpdatePick(POOL_ID as INTEGER, GAME_ID as INTEGER, USERNAME as String, TEAM_ID as INTEGER, MOD_USER as string) as String
			Dim res as String = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string 
				dim cmd as SQLCommand
				dim updatetime as datetime = datetime.now

				sql = "insert into fb_picks_history (POOL_ID, GAME_ID, USERNAME, TEAM_ID, MOD_USER, MOD_TSP) values (@pool_id, @game_id, @username, @team_id, @mod_user, @mod_tsp)"
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@MOD_TSP", SQLDbType.datetime))

				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@GAME_ID").value = GAME_ID
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@TEAM_ID").value = TEAM_ID
				cmd.parameters("@MOD_USER").value = MOD_USER
				cmd.parameters("@MOD_TSP").value = updatetime

				cmd.executenonquery()

				sql = "update fb_picks set TEAM_ID=@team_id, mod_user=@mod_user, mod_tsp=@mod_tsp where pool_id=@pool_id and GAME_ID=@game_id and username=@username and team_id <> @team_id"
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@MOD_TSP", SQLDbType.datetime))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))

				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@GAME_ID").value = GAME_ID
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@MOD_USER").value = MOD_USER
				cmd.parameters("@MOD_TSP").value = updatetime
				cmd.parameters("@TEAM_ID").value = TEAM_ID
				Dim rowsaffected as integer = 0
				rowsaffected = cmd.executenonquery()

				sql = "select count(*) from fb_picks where pool_id=@pool_id and game_id=@game_id and username=@username"
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))

				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@GAME_ID").value = GAME_ID
				cmd.parameters("@USERNAME").value = USERNAME
				dim picksfound as integer = 0
				picksfound = cmd.executescalar()

				If rowsaffected = 0 and picksfound = 0 Then

					sql = "insert into fb_picks(POOL_ID, GAME_ID, USERNAME, TEAM_ID, MOD_USER, MOD_TSP) values (@pool_id, @game_id, @username, @team_id, @mod_user, @mod_tsp)"
					cmd = new SQLCommand(sql, con)

					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
					cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
					cmd.parameters.add(new SQLParameter("@MOD_TSP", SQLDbType.datetime))
					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@GAME_ID").value = GAME_ID
					cmd.parameters("@USERNAME").value = USERNAME
					cmd.parameters("@TEAM_ID").value = TEAM_ID
					cmd.parameters("@MOD_USER").value = MOD_USER
					cmd.parameters("@MOD_TSP").value = system.datetime.now
					rowsaffected = cmd.executenonquery()

				End If
				If rowsaffected > 0 or picksfound > 0 Then
					res = username
				Else
					res = "Failed to update pick."
				End if
			end using

			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function PicksCanBeSeen(pool_id as integer, week_id as integer) as boolean
			dim res as boolean = false
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select min(game_tsp) as game_tsp from fb_sched a where a.pool_id=@pool_id and a.week_id=@week_id "

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int)).value = week_id

				dim checkdate as datetime = system.datetime.now
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
						else
							gamedate = ds.Tables(0).rows(0)("game_tsp")
						End If
					End If
				End If
				if datetime.compare(gamedate, checkdate) > 0 then
					res = false
				else
					res = true
				end if
			end using

				
			Catch ex As exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function isPlayer(pool_id as integer, player_name as string) as boolean
			dim res as boolean = false
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter

				sql = "select count(*) from fb_players where pool_id=@pool_id and username=@username"

				cmd = new SQLCommand(sql,con)

				parm1 = getsqlparameter("pool_id")
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				parm1 = new SQLParameter("@username", SQLDbType.varchar, 50)
				parm1.value = player_name
				cmd.parameters.add(parm1)

				dim playercount as integer = 0
				playercount = cmd.executescalar()
				if playercount > 0 then
					res = true
				end if
			end using

			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		public function ChangeNickname(pool_id as integer, username as string, nickname as string) as string
			dim res as string = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "update fb_players set NICKNAME=@nickname WHERE pool_id=@pool_id AND username=@username"
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@NICKNAME", SQLDbType.VARCHAR, 100))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 30))

				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@NICKNAME").value = NICKNAME
				
				dim rowsaffected as integer = 0

				rowsaffected = cmd.executenonquery()


				If rowsaffected > 0 Then
					res = username
				Else
					res = "Failed to update nickname."
				End if
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("error in ChangeNickname", ex.toString())
			end try
			return res
		end function

		public function GetGamesForWeek(pool_id as integer, week_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter

				sql = "select a.game_id,a.week_id,a.away_id,a.home_id,a.game_tsp,b.team_name as away_team, b.team_shortname as away_shortname, b.url as away_url, c.team_name as home_team, c.team_shortname as home_shortname, c.url as home_url from fb_sched a full outer join fb_teams b on a.pool_id=b.pool_id and a.away_id=b.team_id full outer join fb_teams c on a.pool_id=c.pool_id and a.home_id=c.team_id  where a.pool_id=@pool_id and a.week_id=@week_id order by  a.game_tsp"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				parm1 = new SQLParameter("week_id", SQLDbType.int)
				parm1.value = week_id
				cmd.parameters.add(parm1)

				dim oda as new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
			catch ex as exception
				makesystemlog("Error in GetGamesForWeek", ex.tostring())
			end try

			return res
		end function

		
		public function GetDefaultWeek(pool_id as integer) as integer

			dim res as integer = 0
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select min(week_id) as week_id from fb_sched where pool_id=@pool_id and  game_tsp > dateadd(day,-1, current_timestamp)"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				dim ds as new dataset()
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(ds)
				if ds.tables.count > 0 then
					if ds.tables(0).rows.count > 0 then
						if ds.tables(0).rows(0)("week_id") is dbnull.value then
							res = 1
						else
							res = ds.tables(0).rows(0)("week_id")
						end if
					end if
				end if 
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try 
			return res 
		end function

		public function GetTiebreakertext(pool_id as integer, week_id as integer) as string

			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select tb.*, sched.*, away.team_name as away_team, home.team_name as home_team from fb_tiebreakers tb full outer join fb_sched sched on tb.pool_id=sched.pool_id and tb.game_id=sched.game_id full outer join fb_teams away on away.pool_id=sched.pool_id and away.team_id=sched.away_id full outer join fb_teams home on home.pool_id=sched.pool_id and home.team_id=sched.home_id where tb.pool_id=@pool_id and tb.week_id=@week_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				parm1 = new SQLParameter("@week_id", SQLDbType.int)
				parm1.value = week_id
				cmd.parameters.add(parm1)

				dim oda as new SQLDataAdapter()
				dim ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(ds)
				try
					res = ds.tables(0).rows(0)("away_team") & " at " & ds.tables(0).rows(0)("home_team") 
				catch
					res = "Tie Breaker Game Not Set"
				end try
			end using

			catch ex as exception
				makesystemlog("error in gettiebreakertext", ex.tostring())
			end try

			return res

		end function

		public function SubmitPicks(r as httprequest, pool_id as integer, player_name as string) as string
			
			try
				dim p
				for each p in r.Params
					if p.tostring().startswith("game_") then
						dim game_id as integer
						game_id = p.replace("game_","")
						dim team_id as integer
						team_id = r(p)
						dim res as string = ""
						res = updatepick(pool_id:=pool_id, username:=player_name, game_id:=game_id, team_id:=team_id, mod_user:=player_name)
					end if
				next
			catch ex as exception
				makesystemlog("error in submitpicks", ex.tostring())
			end try
			try
				if r("tiebreaker") <> "" then
					dim tbvalue as integer
					tbvalue = r("tiebreaker")
					updatetiebreaker(pool_id:=pool_id, week_id:=r("week_id"), username:=player_name, score:=tbvalue, mod_user:=player_name)
				end if
			catch ex as exception
				makesystemlog("error in submitpicks", ex.tostring())
			end try
		end function
	
		private function UpdateTiebreaker(POOL_ID as INTEGER, USERNAME as String, score as integer, week_ID as INTEGER) as String
			Dim res as String = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "update fb_tiebreaker set SCORE=@score where username=@username and WEEK_ID=@week_id and  pool_id=@pool_id "
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@SCORE", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@WEEK_ID").value = WEEK_ID
				cmd.parameters("@SCORE").value = SCORE
				cmd.parameters("@POOL_ID").value = POOL_ID

				Dim rowsaffected as integer = 0
				rowsaffected = cmd.executenonquery()

				If rowsaffected = 0 Then

					sql = "insert into fb_tiebreaker(USERNAME, WEEK_ID, SCORE, POOL_ID) values (@username, @week_id, @score, @pool_id)"
					cmd = new SQLCommand(sql, con)

					cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
					cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@SCORE", SQLDbType.int))
					cmd.parameters.add(getsqlparameter("pool_id"))
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
				End if
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("error updating pick", ex.toString())
			end try
			return res
		end function

	
		public function UpdateTiebreaker(POOL_ID as INTEGER, USERNAME as String, score as integer, week_ID as INTEGER, mod_user as string) as String
			Dim res as String = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "update fb_tiebreaker set SCORE=@score , mod_user=@mod_user where username=@username and WEEK_ID=@week_id and  pool_id=@pool_id "
				Dim cmd As SQLCommand = New SQLCommand(sql, con)
				
				cmd.parameters.add(new SQLParameter("@SCORE", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters("@MOD_USER").value = mod_user
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@WEEK_ID").value = WEEK_ID
				cmd.parameters("@SCORE").value = SCORE
				cmd.parameters("@POOL_ID").value = POOL_ID

				Dim rowsaffected as integer = 0
				rowsaffected = cmd.executenonquery()

				If rowsaffected = 0 Then

					sql = "insert into fb_tiebreaker(USERNAME, WEEK_ID, SCORE, POOL_ID, mod_user) values (@username, @week_id, @score, @pool_id, @mod_user)"
					cmd = new SQLCommand(sql, con)

					cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50))
					cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@SCORE", SQLDbType.int))
					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters.add(new SQLParameter("@MOD_USER", SQLDbType.VARCHAR, 50))
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
				End if
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("error updating pick", ex.toString())
			end try
			return res
		end function

		public function UpdateGameScore(game_id as integer, away_score as integer, home_score as integer, pool_id as integer, username as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = ""
				dim cmd as SQLCommand

				sql = "select count(*) from fb_scores where away_score=@away_score and home_score=@home_score and game_id=@game_id and pool_id=@pool_id"
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@AWAY_SCORE", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@HOME_SCORE", SQLDbType.int))
				cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
				cmd.parameters.add(getsqlparameter("pool_id"))

				cmd.parameters("@GAME_ID").value = GAME_ID
				cmd.parameters("@AWAY_SCORE").value = AWAY_SCORE
				cmd.parameters("@HOME_SCORE").value = HOME_SCORE
				cmd.parameters("@POOL_ID").value = POOL_ID

				dim rowcount as integer = 0
				rowcount = cmd.executescalar()
				
				if rowcount <> 1 then

					sql = "insert into fb_scores_history (away_score, home_score, game_id, pool_id, mod_user, mod_tsp) values (@away_score, @home_score, @game_id, @pool_id, @mod_user, CURRENT_TIMESTAMP)"
					cmd = new SQLCommand(sql, con)
	
					cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
					cmd.parameters.add(new SQLParameter("@mod_user", SQLDbType.varchar, 30)).value = username
					cmd.parameters.add(new SQLParameter("@AWAY_SCORE", SQLDbType.int)).value = away_score
					cmd.parameters.add(new SQLParameter("@HOME_SCORE", SQLDbType.int)).value = home_score
					cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int)).value = game_id
					
					dim rowsupdated as integer = 0
	
					rowsupdated = cmd.executenonquery()
	
					sql = "update fb_scores set AWAY_SCORE=@away_score, HOME_SCORE=@home_score where game_id=@game_id and pool_id=@pool_id"
					cmd = new SQLCommand(sql, con)
	
					cmd.parameters.add(new SQLParameter("@AWAY_SCORE", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@HOME_SCORE", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
					cmd.parameters.add(getsqlparameter("pool_id"))
	
					cmd.parameters("@GAME_ID").value = GAME_ID
					cmd.parameters("@AWAY_SCORE").value = AWAY_SCORE
					cmd.parameters("@HOME_SCORE").value = HOME_SCORE
					cmd.parameters("@POOL_ID").value = POOL_ID
					
					rowsupdated = 0
	
					rowsupdated = cmd.executenonquery()
	
					if rowsupdated > 0 then
						res = "SUCCESS"
					else
						sql = "insert into fb_scores(GAME_ID, AWAY_SCORE, HOME_SCORE, pool_id) values (@game_id, @away_score, @home_score, @pool_id)"
						cmd = new SQLCommand(sql, con)
	
						cmd.parameters.add(new SQLParameter("@GAME_ID", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("@AWAY_SCORE", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("@HOME_SCORE", SQLDbType.int))
						cmd.parameters.add(getsqlparameter("pool_id"))
	
						cmd.parameters("@GAME_ID").value = GAME_ID
						cmd.parameters("@AWAY_SCORE").value = AWAY_SCORE
						cmd.parameters("@HOME_SCORE").value = HOME_SCORE
						cmd.parameters("@POOL_ID").value = POOL_ID
	
						rowsupdated = cmd.executenonquery()
						if rowsupdated < 1 then
							res = "Score was not updated."
						else
							res = "SUCCESS" 
						end if
					end if
					updatescoretsp(pool_id)	
				else
					res = "SUCCESS" 
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function GetAllPicksForWeek(pool_id as integer, week_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select a.pool_id, a.game_id, a.username, a.team_id, b.team_shortname as pick_name, c.game_tsp from fb_picks a full outer join fb_teams b on a.team_id=b.team_id and a.pool_id=b.pool_id full outer join fb_sched c on a.game_id=c.game_id and a.pool_id=c.pool_id where a.pool_id=@pool_id and a.game_id in (select game_id from fb_sched where pool_id=@pool_id and week_id=@week_id)"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int)).value = week_id

				dim oda as new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
			catch ex as exception
				makesystemlog("Error getting pool GetAllPicksForWeek", ex.tostring())
			end try

			return res

		end function
		
		public function GetTiebreaker(pool_id as integer, week_id as integer) as string


			dim res as string = "NOTSET"
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select game_id from fb_tiebreakers where pool_id=@pool_id and week_id=@week_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int)).value = week_id

				dim game_id as integer
				game_id = cmd.executescalar()
				res = game_id
			end using
			catch ex as exception
				makesystemlog("Error in GetTiebreaker", ex.tostring())
			end try
			return res
		end function
		
		public function GetPlayerTiebreakers(pool_id as integer, week_id as integer) as dataset
			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter

				sql = "select * from fb_tiebreaker where pool_id=@pool_id and week_id=@week_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int)).value = week_id

				dim oda as new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
				
			catch ex as exception
				makesystemlog("Error in GetPlayerTiebreakers", ex.tostring())
			end try

			return res


		end function

		public function ShowThreads() as dataset
			return new system.data.dataset()
		end function
	
		public function ShowThreads(pool_id as integer, count as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				Dim temp_table As New system.Data.DataTable("Threads")
				Dim temp_col As system.Data.DataColumn 
				dim temp_row as system.Data.DataRow
				
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

				dim sql as string
				dim cmd as SQLCommand
				
				if count > 0 then
					sql = "select top " & count 
				else
					sql = "select "
				end if
				
				sql = sql & " comment_id as thread_id, comment_title as thread_title, username as thread_author, " _
					& " comment_tsp as thread_tsp, username as last_poster, 0 as replies, views " _
					& " from fb_comments where ref_id is null and pool_id=@pool_id"
				
				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				dim dr as SQLDataReader
				dr = cmd.executereader()
				while dr.read()

					temp_row = temp_table.newrow()
					temp_row("thread_id") = dr("thread_id")
					temp_row("thread_title") = dr("thread_title")
					temp_row("thread_author") = dr("thread_author")
					temp_row("thread_tsp") = dr("thread_tsp")
					temp_row("last_poster") = dr("last_poster")
					temp_row("replies") = dr("replies")
					temp_row("views") = dr("views")

					temp_table.rows.add(temp_row)

				end while
				dr.close()


				if temp_table.rows.count > 0 then
					for i as integer = 0 to temp_table.rows.count -1
						sql = "select count(*) from fb_comments where ref_id=@ref_id and pool_id=@pool_id"
						cmd = new SQLCommand(sql,con)
						cmd.parameters.add(new SQLParameter("@ref_id", SQLDbType.int)).value = temp_table.rows(i)("thread_id")
						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						
						temp_table.rows(i)("replies") = cmd.executescalar()

						sql = "select * from fb_comments where pool_id=@pool_id and (comment_id=@ref_id or ref_id=@ref_id) order by comment_tsp desc"
						cmd = new SQLCommand(sql,con)
						cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
						cmd.parameters.add(new SQLParameter("@ref_id", SQLDbType.int)).value = temp_table.rows(i)("thread_id")

						dr = cmd.executereader()
						if dr.read() then
							temp_table.rows(i)("thread_tsp") = dr("comment_tsp")
							temp_table.rows(i)("last_poster") = dr("username")
						end if
						dr.close()
					next
				end if

				res.tables.add(temp_table)
			end using
				
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res

		end function

		public function GetComments(pool_id as integer, thread_id as integer, count as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				if count <= 0 then
					count = 1000000
				end if

				sql = "select top " & count & " a.pool_id, a.username, a.comment_text, a.comment_tsp, a.comment_id, a.ref_id, a.comment_title, a.views, b.nickname from fb_comments a full outer join fb_players b on a.pool_id=b.pool_id and a.username=b.username where a.pool_id=@pool_id and (a.comment_id=@comment_id or a.ref_id=@comment_id) order by comment_tsp asc"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id 
				cmd.parameters.add(new SQLParameter("@comment_id", SQLDbType.int)).value = thread_id

				dim oda as new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res

		end function

		public function GetScoresForWeek(pool_id as integer, week_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select a.game_id, a.away_score, a.home_score from fb_scores a full outer join fb_sched b on a.pool_id=b.pool_id where a.pool_id=@pool_id and b.week_id=@week_id"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int)).value = week_id

				dim oda as new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res

		End Function
		
		Public Function GetWeeklyStats (pool_id as integer) as dataset
			Dim temp_ds As New system.Data.DataSet()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				Dim sql As String = ""
				dim cmd as SQLCommand
				Dim oda As System.Data.SQLClient.SQLDataAdapter
				
				sql = "select t.pool_id, t.username, t.nickname, t.game_id, t.away_score, t.home_score, c.team_id, d.week_id, d.home_id, d.away_id from (select a.pool_id, a.username, a.nickname, b.game_id, b.away_score, b.home_score from fb_players a , fb_scores b where a.pool_id=@pool_id and a.pool_id =b.pool_id and not b.away_score is null) as t full outer join fb_picks c on t.pool_id=c.pool_id and t.game_id=c.game_id and t.username=c.username full outer join fb_sched d on d.pool_id=t.pool_id and d.game_id=t.game_id where (c.pool_id=@pool_id or c.pool_id is null) and not t.away_score is null order by t.username, d.week_id"
				cmd = New SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				
				oda = new SQLDataAdapter()
				oda.selectcommand = cmd
				dim ds as new dataset()
				oda.fill(ds)
				
				Dim temp_table As New system.Data.DataTable("Weekly_Stats")
				
				Dim temp_col As system.Data.DataColumn 
				dim temp_row as system.Data.DataRow
				
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

				dim players_ds as new dataset()
				players_ds = getplayers(pool_id)
				dim weeks_ds as new dataset()
				weeks_ds = listweeks(pool_id)

				for each player_row as datarow in players_ds.tables(0).rows
					for each week_id_row as datarow in weeks_ds.tables(0).rows

						dim temprows as datarow()
						temprows = ds.tables(0).select("username='" & player_row("username") & "' and week_id=" & week_id_row("week_id"))
						if temprows.length > 0 then
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

							for each drow as datarow in temprows
								if drow("team_id") is dbnull.value then
									temp_row("losses") = temp_row("losses") + 1
								else
									if drow("away_id") = drow("team_id") then
										temp_row("away_picks") = temp_row("away_picks") + 1
										if drow("away_score") > drow("home_score") then
											temp_row("wins") = temp_row("wins") + 1
										else
											temp_row("losses") = temp_row("losses") + 1
										end if
									end if
									if drow("home_id") = drow("team_id") then
										temp_row("home_picks") = temp_row("home_picks") + 1
										if drow("home_score") > drow("away_score") then
											temp_row("wins") = temp_row("wins") + 1
										else
											temp_row("losses") = temp_row("losses") + 1
										end if
									end if
								end if
							next
							temp_table.rows.add(temp_row)
						end if
					next
				next
				for i as integer = 0 to temp_table.rows.count - 1
					with temp_table.rows(i)

					.item("win_pct") = system.convert.todouble( .item("wins")) / system.convert.todouble(.item("wins") + .item("losses"))
					.item("home_picks_pct") = 1.00 * .item("home_picks") / .item("home_picks") + .item("away_picks")
					.item("away_picks_pct") = 1.00 * .item("away_picks") / .item("home_picks") + .item("away_picks")
					end with
				next
				temp_ds.tables.add(temp_table)
			end using
			catch ex as exception
				makesystemlog("error", ex.tostring())
			end try

			return temp_ds 
		end Function
		
		public function GetStandingsForWeek(pool_id as integer, week_id as integer) as dataset

			Dim temp_ds As New system.Data.DataSet()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				Dim sql As String = ""
				dim cmd as SQLCommand
				Dim oda As System.Data.SQLClient.SQLDataAdapter
				
					Dim temp_table As New system.Data.DataTable("Scores")
					
					Dim temp_col As system.Data.DataColumn 
					dim temp_row as system.Data.DataRow
					
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
					cmd = New SQLCommand(sql,con)
					
					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters.add(new SQLParameter("@POOL_ID2", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@POOL_ID3", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int))
					cmd.parameters("@POOL_ID").value = pool_id
					cmd.parameters("@POOL_ID2").value = pool_id
					cmd.parameters("@POOL_ID3").value = pool_id
					cmd.parameters("@week_id").value = week_id
					
					oda = New SQLDataAdapter()
					oda.SelectCommand = cmd
					oda.fill(picks_ds)

					dim options_ht as new system.collections.hashtable()
					options_ht = getPoolOptions(pool_id:=pool_id)
					
					Dim weeks_ds As dataset
					weeks_ds = listweeks(pool_id:=pool_id)

					dim players_ds as new dataset()
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
							If options_ht("AUTOHOMEPICKS") = "on" and drow("away_score") < drow("home_score") Then
								temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1
							else
								temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1			
							end if
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
										
										For i As Integer = 0 To week_table.rows.Count -1
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
									
										For i As Integer = 0 To week_table.rows.Count -1
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
					next 'drow
					
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
									tiebreaker_picks_ds = GetPlayerTiebreakers(pool_id:= pool_id, week_id:=week_id_row("week_id"))
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
									try
										allscoresforweek = scoresforweek_ds.tables(0).Select("game_id=" & gettiebreaker(pool_id:= pool_id, week_id:= week_id_row("week_id")))
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
											dim check_score as integer = 0
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
										
											dim check_score as integer = 100000
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
					
					For i As Integer = 0 To temp_table.Rows.Count -1
						temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("wins")
						If options_ht("LONEWOLFEPICK") = "on" Then								
							temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("totalscore") + temp_table.Rows(i)("lwp")
						End If
						If options_ht("WINWEEKPOINT") = "on" Then								
							temp_table.Rows(i)("totalscore") = temp_table.Rows(i)("totalscore") + temp_table.Rows(i)("weekwins")
						End If
					Next

					dim ranked_rows as datarow()
					
					ranked_rows = temp_table.select("1=1", "totalscore desc")
					dim top_score as integer = 0
					try
						top_score = ranked_rows(0)("totalscore")
					catch ex as exception
						makesystemlog("error getting top_score", ex.tostring())
					end try
					
					for i as integer = 0 to temp_table.rows.count -1
						temp_table.rows(i)("rank") = top_score - temp_table.rows(i)("totalscore")
					next
					temp_ds.tables.add(temp_table)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			Return temp_ds
			

		end function

		public function isInteger (s as string) as boolean
			dim rx as new Regex("^-?\d+$")
			return rx.IsMatch(s)
		end function


		Public Function GetStandings(pool_id As Integer) As dataset

			Dim temp_ds As New system.Data.DataSet()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				Dim sql As String = ""
				dim cmd as SQLCommand
				Dim oda As System.Data.SQLClient.SQLDataAdapter
				
				sql = "select count(*) from fb_pools where pool_id=@pool_id and (updatescore_tsp > standings_tsp or standings_tsp is null)"
				cmd = New SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				dim c as integer = 0
				c = cmd.executescalar() 

				if c > 0 then

					Dim temp_table As New system.Data.DataTable("Scores")
					
					Dim temp_col As system.Data.DataColumn 
					dim temp_row as system.Data.DataRow
					
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
					cmd = New SQLCommand(sql,con)
					cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
					
					oda = New SQLDataAdapter()
					oda.SelectCommand = cmd
					oda.fill(picks_ds)

					dim options_ht as new system.collections.hashtable()
					options_ht = getPoolOptions(pool_id:=pool_id)
					
					Dim weeks_ds As dataset
					weeks_ds = listweeks(pool_id:=pool_id)

					dim players_ds as new dataset()
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
							If options_ht("AUTOHOMEPICKS") = "on" and drow("away_score") < drow("home_score") Then
								temp_table.Rows(player_idx)("wins") = temp_table.Rows(player_idx)("wins") + 1
							else
								temp_table.Rows(player_idx)("losses") = temp_table.Rows(player_idx)("losses") + 1			
							end if
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
										
										For i As Integer = 0 To week_table.rows.Count -1
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
									
										For i As Integer = 0 To week_table.rows.Count -1
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
					next 'drow
					
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
									tiebreaker_picks_ds = GetPlayerTiebreakers(pool_id:= pool_id, week_id:=week_id_row("week_id"))
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
									try
										allscoresforweek = scoresforweek_ds.tables(0).Select("game_id=" & gettiebreaker(pool_id:= pool_id, week_id:= week_id_row("week_id")))
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
											dim check_score as integer = 0
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
										
											dim check_score as integer = 100000
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
					
					For i As Integer = 0 To temp_table.Rows.Count -1
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
					cmd = New SQLCommand(sql,con)
					cmd.parameters.add(new SQLParameter("pool_id", SQLDbType.int))
					cmd.parameters("pool_id").value = pool_id
					cmd.executenonquery()

					dim ranked_rows as datarow()
					
					ranked_rows = temp_table.select("1=1", "totalscore desc")
					dim top_score as integer = 0
					try
						top_score = ranked_rows(0)("totalscore")
					catch ex as exception
						makesystemlog("error getting top_score", ex.tostring())
					end try
					
					for each inrow as datarow in ranked_rows
						dim current_rank as integer = top_score - inrow("totalscore")

						sql = "insert into fb_standings (pool_id, username, wins, losses, home, away, weekwins, lwp, totalscore, rank) values (@pool_id, @username, @wins, @losses, @home, @away, @weekwins, @lwp, @totalscore, @rank)"
						cmd = New SQLCommand(sql,con)

						cmd.parameters.add(new SQLParameter("pool_id", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("username", SQLDbType.varchar, 50))
						cmd.parameters.add(new SQLParameter("wins", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("losses", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("home", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("away", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("weekwins", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("lwp", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("totalscore", SQLDbType.int))
						cmd.parameters.add(new SQLParameter("rank", SQLDbType.int))

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

					next

					sql = "update fb_pools set standings_tsp = CURRENT_TIMESTAMP where pool_id=@pool_id"
					cmd = New SQLCommand(sql,con)
					cmd.parameters.add(new SQLParameter("pool_id", SQLDbType.int))
					cmd.parameters("pool_id").value = pool_id
					cmd.executenonquery()

				end if
				sql = "select a.*, b.nickname from fb_standings a full outer join fb_players b on a.pool_id=b.pool_id and a.username=b.username where a.pool_id=@pool_id"
				cmd = New SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("pool_id", SQLDbType.int)).value = pool_id

				oda = new SQLDataAdapter()
				oda.selectcommand = cmd
				temp_ds = new dataset()
				oda.fill(temp_ds)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			Return temp_ds
			
		End Function
		
		public function GetPlayerScoresForWeek(pool_id as integer, week_id as integer) as dataset


			Dim temp_ds As New system.Data.DataSet()
			try
				Dim temp_table As New system.Data.DataTable("Picks")
				Dim temp_col As system.Data.DataColumn 
				dim temp_row as system.Data.DataRow
				
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
				
				dim games_ds as new dataset()
				games_ds = GetGamesForWeek(pool_id:=pool_id, week_id:=week_id)

				dim players_ds as new dataset()
				players_ds = getplayers(pool_id:=pool_id)

				dim picks_ds as new dataset()
				picks_ds = GetAllPicksForWeek(pool_id:=pool_id, week_id:=week_id)

				dim scores_ds as new dataset()
				scores_ds = GetScoresForWeek(pool_id:=pool_id, week_id:=week_id)

				for each pdrow as datarow in players_ds.tables(0).rows

					temp_row = temp_table.newrow()
					temp_row("score") = 0
					temp_row("username") = pdrow("username")
					temp_row("nickname") = pdrow("nickname")

					for each gdrow as datarow in games_ds.tables(0).rows

						dim pick_name as string = ""

						dim temprows as datarow()
						temprows = picks_ds.tables(0).select("game_id=" & gdrow("game_id") & " and username='" & pdrow("username") & "'")
						if temprows.length > 0 then
							pick_name = temprows(0)("pick_name")
						else
							pick_name = "NP"
						end if 
						temprows = scores_ds.tables(0).select("game_id='" & gdrow("game_id") & "'")
						if temprows.length > 0 then
							if temprows(0)("away_score") > temprows(0)("home_score") then
								if pick_name = gdrow("away_shortname") then
									temp_row("score") = temp_row("score") + 1
									'makesystemlog("debug playerscores", "player=" & pdrow("username") & " - pick_name=" & pick_name & " - awayshortname=" & gdrow("away_shortname"))

								end if
							elseif temprows(0)("away_score") < temprows(0)("home_score") then
								if pick_name = gdrow("home_shortname") then
									temp_row("score") = temp_row("score") + 1
									'makesystemlog("debug playerscores", "player=" & pdrow("username") & " - pick_name=" & pick_name & " - homeshortname=" & gdrow("home_shortname"))
								end if
							end if
						end if

					next 'gdrow
					temp_table.rows.add(temp_row)
				next 'pdrow
				
				temp_ds.tables.add(temp_table)
		        
				'temp_ds.WriteXml (savefiledialog1.FileName)
			catch ex as exception
				makesystemlog("Error in GetPlayerScoresForWeek", ex.tostring())
			end try

			return temp_ds

		end function

		public function GetPicksForWeek(pool_id as integer, week_id as integer, player_name as string) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select * from fb_picks  where pool_id=@pool_id and username=@username and game_id in (select game_id from fb_sched where pool_id=@pool_id and week_id=@week_id)"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50)).value = player_name
				cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int)).value = week_id

				dim oda as new SQLDataAdapter()
				oda.SelectCommand = cmd
				oda.Fill(res)
			end using
			catch ex as exception
				makesystemlog("Error getting pool picksforweek", ex.tostring())
			end try

			return res
		end function

		public function GetPick(pool_id as integer, game_id as integer, player_name as string) as integer

			dim res as integer = 0
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select team_id from fb_picks  where pool_id=@pool_id and username=@username and game_id=@game_id"
				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@game_id", SQLDbType.int)).value = game_id
				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 50)).value = player_name
				res = cmd.executescalar()
			end using
			catch ex as exception
				makesystemlog("Error in GetPick", ex.tostring())
			end try

			return res
		end function


		public function gettiebreakervalue(pool_id as integer, week_id as integer, player_name as string) as string

			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				
				sql = "select score from fb_tiebreaker  where pool_id=@pool_id and week_id=@week_id and username=@username"
				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@week_id", SQLDbType.int)).value = week_id
				cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar, 50)).value = player_name

				dim oda as new SQLDataAdapter()
				dim ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(ds)
				try
					res = ds.tables(0).rows(0)("score") 
				catch
					res = ""
				end try
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res

		end function

		
		public function GetMyPools(player_name as string) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select * from fb_pools where pool_owner=@pool_owner or pool_id in (select pool_id from fb_players where username=@player_name)"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.varchar, 50)).value = player_name
				cmd.parameters.add(new SQLParameter("@player_name", SQLDbType.varchar, 50)).value = player_name

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res) 
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		public function GetImportGames() as dataset
			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select a.*, b.team_name as home_team, c.team_name as away_team from fb_copy_scheds a left join fb_copy_teams b on a.home_id=b.team_id left join fb_copy_teams c on a.away_id=c.team_id order by game_tsp asc"
				cmd = new SQLCommand(sql,con)

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res)
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function
		
		public function GetImportPreviousTeams(pool_owner as string) as dataset
			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				sql = "select distinct team_name, team_shortname from fb_teams where pool_id in (select pool_id from fb_pools where pool_owner=@pool_owner) order by team_name"
				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("@pool_owner", SQLDbType.varchar, 50)).value = pool_owner
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res) 
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function
		

		public function GetImportTeams() as dataset
			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				sql = "select distinct team_name, team_shortname from fb_copy_teams order by team_name"
				cmd = new SQLCommand(sql,con)
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res) 
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function
		
		public function GetSchedule(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from fb_sched sched full outer join fb_teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join fb_teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.pool_id in (select pool_id from fb_pools where pool_id=@pool_id) order by sched.game_tsp"

				cmd = new SQLCommand(sql,con)

				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(res) 
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function

		public function validateEmail (key as string, username as string) as boolean
			dim res as boolean = false
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select * from fb_users where username=@username and validate_key=@validate_key"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("@username", SQLDbType.VARCHAR, 50))
				cmd.parameters.add(new SQLParameter("@validate_key", SQLDbType.VARCHAR, 50))

				cmd.parameters("@username").value = username
				cmd.parameters("@validate_key").value = key 

				dim invites_ds as new dataset()
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(invites_ds)
				if invites_ds.tables(0).rows.count > 0 then
					sql = "update fb_users set validated='Y', validate_key='' where username=@username"
					cmd = new SQLCommand(sql,con)
					cmd.parameters.add(new SQLParameter("@username", SQLDbType.VARCHAR, 50)).value = username
					cmd.executenonQuery()

					res = true
				end if 
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res 
		end function
		
		public function validatekey (invite_key as string, email as string, pool_id as integer) as boolean
			dim res as boolean = false

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				dim parm1 as SQLParameter
				
				sql = "select * from fb_invites where email=@email and pool_id=@pool_id and invite_key=@invite_key"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(new SQLParameter("@EMAIL", SQLDbType.VARCHAR, 255))
				cmd.parameters.add(getsqlparameter("pool_id"))
				cmd.parameters.add(new SQLParameter("@INVITE_KEY", SQLDbType.VARCHAR, 40))

				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@EMAIL").value = EMAIL
				cmd.parameters("@INVITE_KEY").value = INVITE_KEY 

				dim invites_ds as new dataset()
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(invites_ds)
				if invites_ds.tables(0).rows.count > 0 then
					res = true
				end if 
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function
		
		public function AcceptInvitation (invite_key as string, email as string, pool_id as integer, player_name as string) as string
			dim res as string = ""

			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand
				
				sql = "select * from fb_pools a full outer join fb_users b on a.pool_owner=b.username where pool_id=@pool_id"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id

				dim pool_ds as new dataset()
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(pool_ds)

				dim pool_name as string  = ""
				try
					pool_name = pool_ds.tables(0).rows(0)("pool_name")
				catch
				end try
				dim pool_owner_email as string = ""
				try
					pool_owner_email = pool_ds.tables(0).rows(0)("email")
				catch
				end try

				res = addPlayer(pool_id, player_name)

				if res = player_name then
					sql = "delete from fb_invites where email=@email and pool_id=@pool_id and invite_key=@invite_key"

					cmd = new SQLCommand(sql,con)
					cmd.parameters.add(new SQLParameter("@EMAIL", SQLDbType.VARCHAR, 255))
					cmd.parameters.add(getsqlparameter("pool_id"))
					cmd.parameters.add(new SQLParameter("@INVITE_KEY", SQLDbType.VARCHAR, 40))

					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@EMAIL").value = EMAIL
					cmd.parameters("@INVITE_KEY").value = INVITE_KEY
					cmd.executenonquery()
					updatescoretsp(pool_id)

					res = email

					dim sb as new stringbuilder()
					sb.append("Your invitation has been accepted.<br />")
					sb.append("Pool Name: " & pool_name & "<br />")
					sb.append("Player Name: " & player_name & "<br />")
					sendemail(emailaddress:=pool_owner_email, subject:="Invitation accepted", body:=sb.tostring())

				else
					res = "Invalid input info."
				end if
			end using
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try

			return res
		end function
		
		public function addPlayer(pool_id as integer, username as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "insert into fb_players (pool_id, username) values (@pool_id, @username)"

				cmd = new SQLCommand(sql,con)
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar, 50)).value = username
				cmd.executenonquery()
				updatescoretsp(pool_id)
				res = username
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function ResetPassword(username as string) as string
			dim res as string
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim temppassword as string
				temppassword = CreateTempPassword()

				dim sql as string
				dim cmd as SQLCommand

				sql = "select *  from fb_users where upper(username) = @username or upper(email) = @username"
				cmd = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar, 50)).value = username.toupper()
				dim oda as new sqldataadapter()
				oda.selectcommand = cmd
				dim ds as new dataset()
				oda.fill(ds)

				dim realUsername as string = ""
				dim email as string = ""
				try
					realUsername = ds.tables(0).rows(0)("username")
					email = ds.tables(0).rows(0)("email")
				catch
				end try

				if realUsername <> "" then
					sql = "update fb_users set temp_password=@password where username=@username"
					cmd = new SQLCommand(sql,con)

					cmd.parameters.add(new SQLParameter("@password", SQLDbType.varchar, 50)).value = hashpassword(temppassword)
					cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar, 50)).value = realUsername

						
					dim sb as stringbuilder = new stringbuilder()
					sb.append( "A request has been received to reset your password.  The following password is temporary.  If this message is in error, and you have not requested to reset your password, then you do not have to do anything.  <br/><br/>Your password will still work normally.  <br/><br/>If you did request to have your password reset, when you login using this password it will become your permanent password until you choose to change it.<br /><br />")
					sb.append("Username: " & realUsername & "<br/>")
					sb.append("Password: " & temppassword & "<br/>")

					SendEmail(email, "Your password has been reset.",sb.tostring())		
				end if
				res = realUsername
				makesystemlog("Password reset", "Input Username: " & username)
			end using
			catch ex as exception
				res = "An error occurred.  The password may not have been reset."
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		private function CreateTempPassword()
			dim temppassword as string
			
			Dim validcharacters as String
			validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"
			
			dim c as char
			System.Threading.Thread.Sleep( 30 )
			
			Dim fixRand As New Random()
			dim randomstring as stringbuilder = new stringbuilder(20)	
			
			dim i as integer
			for i = 0 to 7    
				randomstring.append(validcharacters.substring(fixRand.Next( 0, validcharacters.length ),1))		
			next
			temppassword = randomstring.ToString()
			return temppassword

		end function

		private function SendEmail(emailaddress as string, Subject as string, Body as String) as string
			dim res as string = ""
			try

				dim myMessage as mailmessage
				
				myMessage = New MailMessage
				
				myMessage.BodyFormat = MailFormat.Html
				myMessage.From = "support@smackpools.com"
				myMessage.To = emailaddress
				myMessage.Subject = subject
				myMessage.Body = body
				
				SmtpMail.SmtpServer = "mrelay.perfora.net"
				SmtpMail.Send(myMessage)
				res = emailaddress

			catch ex as exception
				res = ex.message
				MakeSystemLog("Failed to send email.", "Info:" & system.environment.newline & "Email: " & emailaddress & system.environment.newline & "Subject:" & subject & system.environment.newline & "Body:" & system.environment.newline & body & system.environment.newline & ex.tostring())
			end try
			return res
		end function
		
		public function validusername(u as string) as boolean
			Dim res as boolean = true
			
			if u.ToUpper() = "SYSTEM" then
				res = false
			end if
			if u.ToUpper() = "RASPUTIN" then
				res = false
			end if
				
			dim i as integer
			dim validcharacters as string
			validcharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
			
			dim c as string
			
			for i = 0 to u.length -1
				c = u.substring(i,1)
				if validcharacters.indexof(c) < 0 then
					res = false
				end if
			next
			return res
		end Function
		

		public function RegisterUser(username as string, password as string, email as string) as string
		
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim usercount as integer
				
				dim validate_key as string
				
				dim cmd as SQLCommand
				dim dr as SQLDataReader
				dim parm1 as SQLParameter
							
				dim sql as string
				
				
				sql = "select count(*) from fb_users where UPPER(username) = @username or UPPER(email) = @email"
				
				cmd = new SQLCommand(sql,con)
				
				parm1 = new SQLParameter("@username", SQLDbType.varchar, 30)
				parm1.value = username.toupper()
				cmd.parameters.add(parm1)
				
				parm1 = new SQLParameter("@email", SQLDbType.varchar, 50)
				parm1.value = email.toupper()
				cmd.parameters.add(parm1)
				
				usercount = cmd.ExecuteScalar()
				
				if usercount > 0 then
					res = "Username and/or email is already registered."
				else

					
					
					Dim validcharacters as String
					validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
					
					dim c as char
					Thread.Sleep( 30 )
					
					Dim fixRand As New Random()
					dim randomstring as stringbuilder = new stringbuilder(20)	
					
					dim i as integer
					for i = 0 to 29    
						randomstring.append(validcharacters.substring(fixRand.Next( 0, validcharacters.length ),1))		
					next
					validate_key = randomstring.ToString()
								
					sql = "insert into fb_users (username,email,password,validate_key) values (@username, @email, @password,@validate_key)"
					
					cmd = new SQLCommand(sql,con)
					
					parm1 = new SQLParameter("@username", SQLDbType.varchar, 30)
					parm1.value = username
					cmd.parameters.add(parm1)
					
					parm1 = new SQLParameter("@email", SQLDbType.varchar, 50)
					parm1.value = email
					cmd.parameters.add(parm1)
					
					cmd.parameters.add(new SQLParameter("@password", SQLDbType.VarChar, 50)).value = hashpassword(password)
					
					parm1 = new SQLParameter("@validate_key", SQLDbType.varchar, 40)
					parm1.value = validate_key
					cmd.parameters.add(parm1)
					
					cmd.executenonquery()
					
					
					dim sb as new stringbuilder()
					
					sb.append("You have registered to use the www.smackpools.com website.  <br><br>" & system.environment.newline)
					sb.append ("Username: " & username & " <br><br>" & system.environment.newline)
					sb.append ("Password: " & password & " <br><br>" & system.environment.newline)
					sb.append ("To verify that this is a valid email address you must go to the URL below before you can login using your username and password. <br><br>" & system.environment.newline)
					sb.append("Here is your validation link.<br><br>" & system.environment.newline)
					sb.append("<a href=""http://www.smackpools.com/football/validate_registration.aspx?username=" & username & "&validate_key=" & validate_key & """>http://www.smackpools.com/football/validate_registration.aspx?username=" & username & "&validate_key=" & validate_key & "</a> <br /><br /><br />" & system.environment.newline & system.environment.newline & "Thanks,<br />" & system.environment.newline & "Chris")
					
					
					sendemail(emailaddress:=email, subject:="www.smackpools.com registration verification" , body:=sb.tostring())
					res = email
				end if
			end using
			catch ex as exception
				res = ex.message
				MakeSystemLog("error in registeruser", ex.tostring())
			end try
			return res
		end function

		public function resendinvite(pool_id as integer, email as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()

				dim cmd as SQLCommand
				dim dr as SQLDataReader
				dim sql as string
				
				
				sql = "select a.pool_id, a.email, a.invite_key, b.pool_owner, b.pool_name, b.pool_desc from fb_invites a full outer join fb_pools b on a.pool_id=b.pool_id where a.pool_id=@pool_id and a.email=@email"
				
				cmd = new SQLCommand(sql,con)
				
				cmd.parameters.add(getsqlparameter("pool_id")).value = pool_id
				cmd.parameters.add(new SQLParameter("@email", SQLDbType.varchar, 50)).value = email
				
				dim oda as new SQLDataAdapter()
				dim invite_ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(invite_ds)
				if invite_ds.tables.count < 1 then
					res = "invalid pool_id"
				else
					if invite_ds.tables(0).rows.count < 1 then
						res = "invalid pool_id"
					else
						sendinvite(email:=email, _
						invite_key:=invite_ds.tables(0).rows(0)("invite_key"), _
						pool_id:=pool_id, _
						username:=invite_ds.tables(0).rows(0)("pool_owner"))
						res = email

					end if
				end if
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("error in resendinvite", ex.tostring())
			end try
			return res
		end function

		public function sendmessage(email as string, msg as string, username as string) as string
			dim res as string = ""
			try
					dim sb as new stringbuilder()
					
					sb.append("The following message was sent from the website:  <br><br>" & system.environment.newline)
					
					sb.append ("Username: " & username & " <br><br>" & system.environment.newline)
					
					sb.append ("Email: " & email & " <br><br>" & system.environment.newline)
					
					sb.append ("System Time: " & system.datetime.now & " <br><br>" & system.environment.newline)
					
					sb.append ("Message:  <br><br>" & system.environment.newline)
					
					sb.append (msg & " <br><br>" & system.environment.newline)					
					
					dim myMessage as mailmessage
					
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
			catch ex as exception
				res = ex.message
				makesystemlog("error in sendmessage", ex.tostring())
			end try
			return res
		end function
			
		private function hashpassword(password as string) as string
			'Encrypt the password
			Dim md5Hasher as New MD5CryptoServiceProvider()
			
			Dim hashedBytes as Byte()   
			Dim encoder as New UTF8Encoding()
			
			hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(password))
			dim sb as StringBuilder = new StringBuilder(hashedbytes.length * 2)
			for i as integer = 0 to hashedbytes.length -1
				sb.append(hashedbytes(i).toString("X2"))
			next

			return sb.ToString().tolower()

		end function

		public function Login(username as string, password as string) as string
			dim res as string = ""
			try
			res = authenticate(username, password)
			if res.toupper() = username.toUpper() then
				return res
			else
				' failed to authenticate with username and normal password, try temp password
				using con as new SQLConnection(myconnstring)
					con.open()
					dim usercount as integer = 0		
					
					dim cmd as SQLCommand
					dim dr as SQLDataReader
					dim parm1 as SQLParameter
					
					dim sql as string
						
					sql = "select username from fb_users where (UPPER(username) = @username  or upper(email) = @username) and temp_password=@password and validated='Y'"
						
					cmd = new SQLCommand(sql,con)
						
					cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar, 50)).value = username.toupper()
					cmd.parameters.add(new SQLParameter("@password", SQLDbType.varchar, 50)).value = hashpassword(password)
						
					dim user_ds2 as system.data.dataset = new dataset()
					dim user_ds as new dataset()
					dim oda as new SQLDataAdapter()

					dim oda2 as System.Data.SQLClient.SQLDataAdapter = new System.Data.SQLClient.SQLDataAdapter()
					oda2.selectcommand = cmd
					oda2.fill(user_ds2)
					if user_ds2.tables.count > 0 then	
					if user_ds2.tables(0).rows.count > 0 then
						sql = "update fb_users set password=temp_password where username = @username"
		
						cmd = new SQLCommand(sql,con)
		
						parm1 = new SQLParameter("@username", SQLDbType.varchar, 50)
						parm1.value = user_ds2.tables(0).rows(0)("username")
						cmd.parameters.add(parm1)
						
						dim ra as integer
						ra = cmd.executenonquery()
						'makesystemlog ("Updated fb_users", "Updated fb_users with new password. Rows affected=" & ra)
		
						' refill user_ds dataset so the rest of the code will work normally 
		
						sql = "select username from fb_users where UPPER(username) = @username and password=@password and validated='Y'"
					
						cmd = new SQLCommand(sql,con)
						
						cmd.parameters.add(new SQLParameter("@username", SQLDbType.varchar, 50)).value = username.toupper()
						cmd.parameters.add(new SQLParameter("@password", SQLDbType.varchar, 50)).value = hashpassword(password)
						
						user_ds = new dataset()
						oda = new System.Data.SQLClient.SQLDataAdapter()
						oda.selectcommand = cmd
						oda.fill(user_ds)
					else
					end if
					end if
		
					if user_ds.tables.count > 0 then	
					if user_ds.tables(0).rows.count > 0 then
						res = user_ds.tables(0).rows(0)("username")
						
						sql = "update fb_users set login_count=login_count + 1, last_seen = current_timestamp, temp_password = NULL  where username=@username"
						
						cmd = new SQLCommand(sql,con)
						
						parm1 = new SQLParameter("@username", SQLDbType.varchar, 50)
						parm1.value = res
						cmd.parameters.add(parm1)
						
						cmd.executenonquery()
					end if
					end if
				end using
			end if
			catch ex as exception
				res = ex.message
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function GetAvatar(username as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "select email from fb_users where username=@username"
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(new SQLParameter("@USERNAME", SQLDbType.VARCHAR, 30)).value = username
				
				dim ds as new system.data.dataset()
				dim oda as new SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(ds)
				try
					if not ds.tables(0).rows(0)("email") is dbnull.value then
						Dim md5Hasher as New MD5CryptoServiceProvider()
				
						Dim hashedBytes as Byte()   
						Dim encoder as New UTF8Encoding()
						hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(ds.tables(0).rows(0)("email")))
						dim sb as StringBuilder = new StringBuilder(hashedbytes.length * 2)
						for i as integer = 0 to hashedbytes.length -1
							sb.Append(hashedbytes(i).toString("X2"))
						next
						res = sb.ToString().ToLower()
					end if
				catch ex as exception
					makesystemlog("error in GetAvatar", ex.toString())
				end try
			end using
			catch ex as exception
				dim st as new System.Diagnostics.StackTrace() 
				makesystemlog("error in " & st.GetFrame(0).GetMethod().Name.toString(), ex.tostring())
			end try
			return res
		end function

		public function GetAvatar(pool_id as integer, username as string) as string
			return getavatar(username)
		end function

		public function ChangeAvatar(pool_id as integer, username as string, avatar as string) as string
			dim res as string = ""
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string = "update fb_players set avatar=@avatar WHERE pool_id=@pool_id AND username=@username"
				dim cmd as SQLCommand = new SQLCommand(sql, con)

				cmd.parameters.add(getSQLParameter("pool_id")).value = pool_id

				cmd.parameters.add(new SQLParameter("@avatar", SQLDbType.VARCHAR, 255))
				cmd.parameters.add(getSQLParameter("username"))

				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@avatar").value = avatar
				
				dim rowsaffected as integer = 0

				rowsaffected = cmd.executenonquery()


				If rowsaffected > 0 Then
					res = "SUCCESS"
				Else
					res = "Failed to change avatar."
				End if
			end using
			catch ex as exception
				res = ex.message
				makesystemlog("error in ChangeAvatar", ex.toString())
			end try
			return res
		end function

		private function getSqlParameter(t as string) as SQLParameter
			select case t.tolower()
				case "pool_id"
					return getsqlparameter("pool_id")
				case "username"
					return New SQLParameter("@username", SQLDbType.VarChar, 50)
			end select
		end function
	end Class


	public class FBMessage
		private myconnstring as string = System.Configuration.ConfigurationSettings.AppSettings("connString")
		private _from_user as string
		private _to_user as string
		private _subject as string
		private _body as string
		private _read_at as datetime
		private _created_at as datetime
		private _id as integer

		public Property fromUser() as string
			get
				return _from_user
			end get
			set(byval value as string)
				_from_user = value
			end set
		end property
		public Property toUser() as string
			get
				return _to_user
			end get
			set(byval value as string)
				_to_user = value
			end set
		end property
		public Property subject() as string
			get
				return _subject
			end get
			set(byval value as string)
				_subject = value
			end set
		end property
		public Property body() as string
			get
				return _body
			end get
			set(byval value as string)
				_body = value
			end set
		end property
		public Property id() as integer
			get
				return _id
			end get
			set(byval value as integer)
				_id = value
			end set
		end property
		public Property created_at() as datetime
			get
				return _created_at
			end get
			set(byval value as datetime)
				_created_at = value
			end set
		end property
		public Property read_at() as datetime
			get
				return _read_at
			end get
			set(byval value as datetime)
				_read_at = value
			end set
		end property
		

	end class


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
	Public BarWidthModifier as double = 1.0

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
