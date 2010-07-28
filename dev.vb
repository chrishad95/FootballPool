Imports System
Imports System.Collections
Imports System.ComponentModel
Imports System.Data
Imports System.Data.odbc
Imports System.Drawing
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Web.UI.HtmlControls
Imports System.Web.Mail
Imports System.Text
Imports System.Threading
Imports System.Security.Cryptography

Namespace Rasputin
	public Class Football

		private myconnstring as string = System.Configuration.ConfigurationSettings.AppSettings("connString")

		private con as odbcconnection

		Public sub MakeSystemLog (log_title as string, log_text as string)
		
			dim sql as string
			dim cmd as odbccommand
			dim con as odbcconnection
			dim parm1 as odbcparameter
			
			sql = "insert into journal.entries (username,journal_type,entry_tsp,entry_date,entry_title,entry_text) values (?,?,current timestamp,date(current timestamp),?,?)"
			
			dim connstring as string
			connstring = myconnstring
			
			con = new odbcconnection(connstring)
			con.open()
			cmd = new odbccommand(sql,con)
		
			parm1 = new odbcparameter("username", odbctype.varchar, 50)
			parm1.value = "chadley"
			cmd.parameters.add(parm1)
			parm1 = new odbcparameter("journal_type", odbctype.varchar, 20)
			parm1.value = "SYSTEM"
			cmd.parameters.add(parm1)
			parm1 = new odbcparameter("entry_title", odbctype.varchar, 200)
			parm1.value = log_title & " - " & system.datetime.now
			cmd.parameters.add(parm1)
			parm1 = new odbcparameter("entry_text", odbctype.text, 32700)
			parm1.value = log_text
			cmd.parameters.add(parm1)
			
			cmd.executenonquery()
			con.close()
			con.dispose()

		end sub 

		Public function ListPools(pool_owner as string) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from pool.pools where pool_owner=?"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
				con.dispose()
			catch ex as exception
				makesystemlog("Error getting pool list", ex.tostring())
			end try

			return res
		end function

		Public function GetPoolDetails(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from pool.pools where pool_id=?"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
				con.dispose()
			catch ex as exception
				makesystemlog("Error getting pool details", ex.tostring())
			end try

			return res
		end function


		Public function GetPoolGames(pool_owner as string, pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from football.sched sched full outer join football.teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join football.teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by sched.game_tsp"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
				con.dispose()
			catch ex as exception
				makesystemlog("Error getting pool games", ex.tostring())
			end try

			return res
		end function


		Public function GetPoolTeams(pool_owner as string, pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from football.teams where pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by team_name"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
				con.dispose()
			catch ex as exception
				makesystemlog("Error getting pool details", ex.tostring())
			end try

			return res
		end function

		Public function GetPoolInvitations(pool_owner as string, pool_id as string) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from pool.invites where pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by email"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
			catch ex as exception
				makesystemlog("Error getting pool invites", ex.tostring())
			end try

			return res

		end function

		Public function GetPoolPlayers(pool_owner as string, pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from pool.players where pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by username"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
			catch ex as exception
				makesystemlog("Error getting pool players", ex.tostring())
			end try

			return res
		end function


		Public function UpdatePool(POOL_ID as INTEGER, POOL_OWNER as String, POOL_NAME as String, POOL_DESC as String, ELIGIBILITY as String, POOL_LOGO as String, POOL_BANNER as String) as string
			dim res as string = ""
			try
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()
				dim sql as string = "update POOL.POOLS set POOL_NAME=?, POOL_DESC=?, POOL_TSP=?, ELIGIBILITY=?, POOL_LOGO=?, POOL_BANNER=? where POOL_ID=? and pool_owner=?"
				dim cmd as odbccommand = new odbccommand(sql, cn)

				cmd.parameters.add(new odbcparameter("@POOL_NAME", odbctype.VARCHAR, 100))
				cmd.parameters.add(new odbcparameter("@POOL_DESC", odbctype.VARCHAR, 500))
				cmd.parameters.add(new odbcparameter("@POOL_TSP", odbctype.datetime))
				cmd.parameters.add(new odbcparameter("@ELIGIBILITY", odbctype.VARCHAR, 10))
				cmd.parameters.add(new odbcparameter("@POOL_LOGO", odbctype.VARCHAR, 255))
				cmd.parameters.add(new odbcparameter("@POOL_BANNER", odbctype.VARCHAR, 255))
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@POOL_OWNER", odbctype.VARCHAR, 50))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@POOL_OWNER").value = POOL_OWNER
				cmd.parameters("@POOL_NAME").value = POOL_NAME
				cmd.parameters("@POOL_DESC").value = POOL_DESC
				cmd.parameters("@POOL_TSP").value = system.datetime.now
				cmd.parameters("@ELIGIBILITY").value = ELIGIBILITY
				cmd.parameters("@POOL_LOGO").value = POOL_LOGO
				cmd.parameters("@POOL_BANNER").value = POOL_BANNER
				cmd.executenonquery()
				cn.close()
				res = pool_name
			catch ex as exception
				res = ex.toString()
			end try
			return res
		end function

		Public function CreateTeam(TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""

			try
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()

				dim sql as string = ""

				dim pools_ds as dataset = listpools(pool_owner)

				if pools_ds.tables.count > 0 then
					dim temp_rows as datarow()
					temp_rows = pools_ds.tables(0).select("pool_id=" & pool_id)
					if temp_rows.length > 0 then

						sql = "insert into FOOTBALL.TEAMS(TEAM_NAME, TEAM_SHORTNAME, URL, POOL_ID) values ( ?, ?, ?, ?)"
						dim cmd as odbccommand = new odbccommand(sql, cn)

						cmd.parameters.add(new odbcparameter("@TEAM_NAME", odbctype.VARCHAR, 40))
						cmd.parameters.add(new odbcparameter("@TEAM_SHORTNAME", odbctype.CHAR, 3))
						cmd.parameters.add(new odbcparameter("@URL", odbctype.VARCHAR, 200))
						cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
						cmd.parameters("@TEAM_NAME").value = TEAM_NAME
						cmd.parameters("@TEAM_SHORTNAME").value = TEAM_SHORTNAME
						cmd.parameters("@URL").value = URL
						cmd.parameters("@POOL_ID").value = POOL_ID
						cmd.executenonquery()
						cn.close()
						res = team_name
					else
						res = "invalid pool_id for " & pool_owner
					end if
				else
					res = "No Pools found for " & pool_owner
				end if

				cn.close()
			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = "Team already exists for this pool."
				else
					res = ex.message
					makesystemlog("Error in Create Team", ex.tostring())
				end if

			end try
			return res
		end function
		
		Public function InvitePlayer(POOL_ID as INTEGER, pool_owner as string, email as string)

			dim res as string = ""
			try
				dim pools_ds as dataset = listpools(pool_owner)

				if pools_ds.tables.count > 0 then
					dim temp_rows as datarow()
					temp_rows = pools_ds.tables(0).select("pool_id=" & pool_id)
					if temp_rows.length > 0 then
						dim invite_key as string = createinvitekey()
						'CreateInvite(POOL_ID as INTEGER, EMAIL as String, INVITE_KEY as String, INVITE_TSP as datetime)
						res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
						if res = email then
							sendinvite(email:=email, invite_key:=invite_key, pool_desc:=temp_rows(0)("pool_desc"), pool_id:=pool_id, pool_owner:=temp_rows(0)("pool_owner"), pool_name:=temp_rows(0)("pool_name"))
						end if
					else
						res = "invalid pool_id for " & pool_owner
					end if
				else
					res = "No Pools found for " & pool_owner
				end if


			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = "Team already exists for this pool."
				else
					res = ex.message
					makesystemlog("Error in InvitePlayer", ex.tostring())
				end if

			end try
			return res
		end function
		
		Public sub SendInvite(email as string, invite_key as string, pool_desc as string, pool_id as string, pool_owner as string, pool_name as string)

			dim sb as new stringbuilder()
			
			sb.append("You have been invited to participate in the pool<br /><br />" & pool_name & "<br /><br />created by " & pool_owner & ".  <br><br>" & system.environment.newline)
			
			sb.append("Description: " & pool_desc & "<br><br>"  & system.environment.newline)
			
			sb.append("To accept the invitation please visit the following link.<br><br>" & system.environment.newline)
			sb.append("Go to:<br /> <a href=""http://superpools.gotdns.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & """>http://superpools.gotdns.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & "</a> <br /><br /><br />" & system.environment.newline & system.environment.newline  )
			
			sb.append("You will need an account with this site (and be logged in) to accept the invitation.  If you don't have an account you should get one <a href=""http://superpools.gotdns.com/football/register.aspx"">here</a> first.<br /><br />" & system.environment.newline)

			sb.append("Note: If you already have an account on rasputin.dnsalias.com, you can user your username and password from that site.<br /><br />" & system.environment.newline)
			
			sb.append ("Thanks,<br />" & system.environment.newline & "Chris<br><br>" & system.environment.newline)
			
			'response.write(sb.tostring())
			sendemail(email, "Invitation to " & pool_name, sb.tostring())
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
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()
				dim sql as string = "insert into POOL.INVITES(POOL_ID, EMAIL, INVITE_KEY, INVITE_TSP) values (?, ?, ?, ?)"
				dim cmd as odbccommand = new odbccommand(sql, cn)

				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@EMAIL", odbctype.VARCHAR, 255))
				cmd.parameters.add(new odbcparameter("@INVITE_KEY", odbctype.VARCHAR, 40))
				cmd.parameters.add(new odbcparameter("@INVITE_TSP", odbctype.datetime))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@EMAIL").value = EMAIL
				cmd.parameters("@INVITE_KEY").value = INVITE_KEY
				cmd.parameters("@INVITE_TSP").value = INVITE_TSP
				cmd.executenonquery()
				cn.close()
				res = email
			catch ex as exception
				res =  ex.toString()
			end try
			return res
		end function

		Public function UpdateTeam(TEAM_ID as INTEGER, TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim cn as new odbcconnection()
					cn.connectionstring = myconnstring
					cn.open()
					dim sql as string = ""

					sql = "update FOOTBALL.TEAMS set TEAM_NAME=?, TEAM_SHORTNAME=?, URL=? where POOL_ID=? and TEAM_ID=?"
					dim cmd as odbccommand = new odbccommand(sql, cn)
					dim rowsupdated as integer

					cmd.parameters.add(new odbcparameter("@TEAM_NAME", odbctype.VARCHAR, 40))
					cmd.parameters.add(new odbcparameter("@TEAM_SHORTNAME", odbctype.char, 3))
					cmd.parameters.add(new odbcparameter("@URL", odbctype.VARCHAR, 200))
					cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@TEAM_ID", odbctype.int))
					cmd.parameters("@TEAM_ID").value = TEAM_ID
					cmd.parameters("@TEAM_NAME").value = TEAM_NAME
					cmd.parameters("@TEAM_SHORTNAME").value = TEAM_SHORTNAME
					cmd.parameters("@URL").value = URL
					cmd.parameters("@POOL_ID").value = POOL_ID
					rowsupdated = cmd.executenonquery()
					cn.close()

					if rowsupdated > 0 then
						res = team_name
					else
						res = "Team was not updated."
					end if

				else
					res = "No Pools found for " & pool_owner
				end if
			catch ex as exception
				if ex.message.tostring().indexof("duplicate rows") >= 0 then
					res = "Team already exists for this pool."
				else
					res = ex.message
					makesystemlog("Error in Update Team", ex.tostring())
				end if

			end try
			return res
		end function
		Public function GetTiebreakers(pool_id as integer, pool_owner as string) as dataset
			dim res as new system.data.dataset()
			try
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim sql as string
					dim cmd as odbccommand
					dim con as odbcconnection
					dim parm1 as odbcparameter
					
					dim connstring as string
					connstring = myconnstring
					
					con = new odbcconnection(connstring)
					con.open()

					sql = "select * from pool.tiebreakers where pool_id=?"

					cmd = new odbccommand(sql,con)

					parm1 = new odbcparameter("@pool_id", odbctype.int)
					parm1.value = pool_id
					cmd.parameters.add(parm1)

					dim oda as new odbcdataadapter()
					oda.selectcommand = cmd
					oda.fill(res)
				
					con.close()
				end if
			catch ex as exception
				makesystemlog("Error getting tie breakers", ex.tostring())
			end try

			return res
		end function

		Public function ListWeeks(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select distinct week_id from football.sched where pool_id=?"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
			catch ex as exception
				makesystemlog("Error getting pool weeks", ex.tostring())
			end try

			return res
		end function

		Public function GetPlayers(pool_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select distinct username from pool.players where pool_id=?"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
			catch ex as exception
				makesystemlog("Error in GetPlayers", ex.tostring())
			end try

			return res
		end function

		Public function AddGames(POOL_ID as INTEGER, pool_owner as string, games_text as string) as string
			dim res as string = ""
			try
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()

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
				cn.close()
			
			catch ex as exception
				res = ex.message
				makesystemlog("Error adding game", ex.tostring())
			end try
			return res
		end function

		Public function lookupteam(pool_id as integer, team_name as string) as string
			dim res as string = "NO TEAM FOUND"

			try
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()

				dim sql as string = "select team_id from football.teams where team_name=? and pool_id=?"


				dim cmd as odbccommand = new odbccommand(sql, cn)


				cmd.parameters.add(new odbcparameter("@TEAM_NAME", odbctype.VARCHAR, 40))
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))

				cmd.parameters("@TEAM_NAME").value = TEAM_NAME
				cmd.parameters("@POOL_ID").value = POOL_ID
				
				dim oda as new odbcdataadapter()
				dim ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(ds)

				if ds.tables.count > 0 then
					if ds.tables(0).rows.count > 0 then
						res = ds.tables(0).rows(0)("team_id")
					end if
				end if

				cn.close()
			
			catch ex as exception
				res = ex.message
				makesystemlog("Error looking up team", ex.tostring())
			end try
			return res
		end function

		Public function CreateGame(WEEK_ID as INTEGER, HOME_ID as INTEGER, AWAY_ID as INTEGER, GAME_TSP as datetime, GAME_URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()



				dim pools_ds as dataset = listpools(pool_owner)

				if pools_ds.tables.count > 0 then
					dim temp_rows as datarow()
					temp_rows = pools_ds.tables(0).select("pool_id=" & pool_id)
					if temp_rows.length > 0 then

						dim sql as string = "insert into FOOTBALL.SCHED(WEEK_ID, HOME_ID, AWAY_ID, GAME_TSP, GAME_URL, POOL_ID) values (?, ?, ?, ?, ?, ?)"


						dim cmd as odbccommand = new odbccommand(sql, cn)

						cmd.parameters.add(new odbcparameter("@WEEK_ID", odbctype.int))
						cmd.parameters.add(new odbcparameter("@HOME_ID", odbctype.int))
						cmd.parameters.add(new odbcparameter("@AWAY_ID", odbctype.int))
						cmd.parameters.add(new odbcparameter("@GAME_TSP", odbctype.datetime))
						cmd.parameters.add(new odbcparameter("@GAME_URL", odbctype.VARCHAR, 300))
						cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
						cmd.parameters("@WEEK_ID").value = WEEK_ID
						cmd.parameters("@HOME_ID").value = HOME_ID
						cmd.parameters("@AWAY_ID").value = AWAY_ID
						cmd.parameters("@GAME_TSP").value = GAME_TSP
						cmd.parameters("@GAME_URL").value = GAME_URL
						cmd.parameters("@POOL_ID").value = POOL_ID
						cmd.executenonquery()
						cn.close()
						res = pool_owner
					else
						res = "invalid pool_id for " & pool_owner
					end if
				else
					res = "No Pools found for " & pool_owner
				end if
			
			catch ex as exception
				res = ex.message
				makesystemlog("Error adding game", ex.tostring())
			end try
			return res
		end function

		Public function UpdateGame(GAME_ID as INTEGER, WEEK_ID as INTEGER, HOME_ID as INTEGER, AWAY_ID as INTEGER, GAME_TSP as datetime, GAME_URL as String, POOL_ID as INTEGER, pool_owner as string) as string
			dim res as string
			try
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim cn as new odbcconnection()
					cn.connectionstring = myconnstring
					cn.open()
					dim sql as string = "update FOOTBALL.SCHED set WEEK_ID=?, HOME_ID=?, AWAY_ID=?, GAME_TSP=?, GAME_URL=?, POOL_ID=? where GAME_ID=?"
					dim cmd as odbccommand = new odbccommand(sql, cn)

					cmd.parameters.add(new odbcparameter("@WEEK_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@HOME_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@AWAY_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@GAME_TSP", odbctype.datetime))
					cmd.parameters.add(new odbcparameter("@GAME_URL", odbctype.VARCHAR, 300))
					cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@GAME_ID", odbctype.int))
					cmd.parameters("@GAME_ID").value = GAME_ID
					cmd.parameters("@WEEK_ID").value = WEEK_ID
					cmd.parameters("@HOME_ID").value = HOME_ID
					cmd.parameters("@AWAY_ID").value = AWAY_ID
					cmd.parameters("@GAME_TSP").value = GAME_TSP
					cmd.parameters("@GAME_URL").value = GAME_URL
					cmd.parameters("@POOL_ID").value = POOL_ID

					cmd.executenonquery()
					cn.close()
					res = pool_owner
				else
					res = "Invalid pool_id."
				end if
			catch ex as exception
				res = ex.message
				makesystemlog("error updating game", ex.toString())
			end try
			return res
		end function

		Public function isowner(pool_id as integer, pool_owner as string) as boolean
			dim res as boolean = false
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select count(*)  from pool.pools where pool_owner=? and pool_id=?"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = pool_owner
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				dim pool_count as integer = 0
				pool_count = cmd.executescalar()
				if pool_count > 0 then
					res = true
				end if
			
				con.close()
			catch ex as exception
				makesystemlog("Error in isowner", ex.tostring())
			end try

			return res

		end function

		Public function UpdateTIEBREAKER(POOL_ID as INTEGER, WEEK_ID as INTEGER, GAME_ID as INTEGER, pool_owner as string) as string
			dim res as string = ""
			try
				if isowner(pool_id:=pool_id, pool_owner:=pool_owner) then
					dim cn as new odbcconnection()
					cn.connectionstring = myconnstring
					cn.open()
					dim sql as string = "update POOL.TIEBREAKERS set GAME_ID=?, tb_tsp=? where pool_id=? and week_id=?"

					dim cmd as odbccommand = new odbccommand(sql, cn)

					cmd.parameters.add(new odbcparameter("@GAME_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@TB_TSP", odbctype.datetime))
					cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@WEEK_ID", odbctype.int))
					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@WEEK_ID").value = WEEK_ID
					cmd.parameters("@GAME_ID").value = GAME_ID
					cmd.parameters("@TB_TSP").value = system.datetime.now
					
					dim rowsaffected as integer = 0
					rowsaffected = cmd.executenonquery()

					if rowsaffected = 0 then

						sql = "insert into POOL.TIEBREAKERS(POOL_ID, WEEK_ID, GAME_ID, TB_TSP) values (?, ?, ?, ?)"
						cmd = new odbccommand(sql, cn)

						cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
						cmd.parameters.add(new odbcparameter("@WEEK_ID", odbctype.int))
						cmd.parameters.add(new odbcparameter("@GAME_ID", odbctype.int))
						cmd.parameters.add(new odbcparameter("@TB_TSP", odbctype.datetime))
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

					cn.close()
				else
					res = "invalid pool_id"
				end if
			catch ex as exception
				res = ex.message
				makesystemlog("error updating tiebreaker", ex.toString())
			end try
			return res
		end function

		public function isvalidfastkey(fastkey as string, pool_id as integer, week_id as integer, player_name as string) as boolean
			dim res as boolean = false

			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select count(*) from football.fastkeys where username=? and week_id=? and fastkey=? and pool_id=?"

				cmd = new odbccommand(sql,con)

				cmd.parameters.add(new odbcparameter("@USERNAME", odbctype.VARCHAR, 30))
				cmd.parameters.add(new odbcparameter("@WEEK_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@FASTKEY", odbctype.CHAR, 30))
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters("@USERNAME").value = player_name
				cmd.parameters("@WEEK_ID").value = WEEK_ID
				cmd.parameters("@FASTKEY").value = FASTKEY
				cmd.parameters("@POOL_ID").value = POOL_ID

				cmd.executenonquery()
				dim fk_count as integer = 0
				fk_count = cmd.executescalar()
				if fk_count > 0 then
					res = true
				end if
			
				con.close()
			catch ex as exception
				makesystemlog("Error in isvalidfastkey", ex.tostring())
			end try


			return res
		end function

		public function UpdatePick(POOL_ID as INTEGER, GAME_ID as INTEGER, USERNAME as String, TEAM_ID as INTEGER) as String
			Dim res as String = ""

			try
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()
				dim sql as string = "update POOL.PICKS set TEAM_ID=? where POOL_ID=? and GAME_ID=? and USERNAME=? "
				dim cmd as odbccommand = new odbccommand(sql, cn)

				cmd.parameters.add(new odbcparameter("@TEAM_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@GAME_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@USERNAME", odbctype.VARCHAR, 50))
				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@GAME_ID").value = GAME_ID
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@TEAM_ID").value = TEAM_ID
				Dim rowsaffected as integer = 0
				rowsaffected = cmd.executenonquery()

				If rowsaffected = 0 Then

					sql = "insert into POOL.PICKS(POOL_ID, GAME_ID, USERNAME, TEAM_ID) values (?, ?, ?, ?)"
					cmd = new odbccommand(sql, cn)

					cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@GAME_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@USERNAME", odbctype.VARCHAR, 50))
					cmd.parameters.add(new odbcparameter("@TEAM_ID", odbctype.int))
					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@GAME_ID").value = GAME_ID
					cmd.parameters("@USERNAME").value = USERNAME
					cmd.parameters("@TEAM_ID").value = TEAM_ID
					rowsaffected = cmd.executenonquery()

				End If
				If rowsaffected > 0 Then
					res = username
				Else
					res = "Failed to update pick."
				End if

				cn.close()
			catch ex as exception
				res = ex.message
				makesystemlog("error updating pick", ex.toString())
			end try
			return res
		end function

		public function isplayer(pool_id as integer, player_name as string) as boolean
			dim res as boolean = false
			try

				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				sql = "select count(*) from pool.players where pool_id=? and username=?"

				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()
				cmd = new odbccommand(sql,con)
			


				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				parm1 = new odbcparameter("@username", odbctype.varchar, 50)
				parm1.value = player_name
				cmd.parameters.add(parm1)

				dim playercount as integer = 0
				playercount = cmd.executescalar()
				if playercount > 0 then
					res = true
				end if
				con.close()

			catch ex as exception
				makesystemlog("error in isplayer", ex.tostring())
			end try

			return res
		end function


		public function GetGamesForWeek(pool_id as integer, week_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select a.game_id,a.week_id,a.away_id,a.home_id,a.game_tsp,b.team_name as away_team, b.team_shortname as away_shortname, b.url as away_url, c.team_name as home_team, c.team_shortname as home_shortname, c.url as home_url from football.sched a full outer join football.teams b on a.away_id=b.team_id full outer join football.teams c on a.home_id=c.team_id  where a.pool_id=? and a.week_id=? order by  a.game_tsp"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("week_id", odbctype.int)
				parm1.value = week_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.SelectCommand = cmd
				oda.Fill(res)

				con.close()
			catch ex as exception
				makesystemlog("Error getting pool details", ex.tostring())
			end try

			return res
		end function

		
		public function GetDefaultWeek(pool_id as integer) as integer

			dim res as integer = 0
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select min(week_id) as week_id from (select week_id from football.sched where pool_id=? and  game_tsp > current timestamp + 30 minutes) as t"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim ds as new dataset()
				dim oda as new odbcdataadapter()
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

				con.close()
			catch ex as exception
				makesystemlog("Error getting pool weeks", ex.tostring())
			end try

			return res

		end function

		public function GetTiebreakertext(pool_id as integer, week_id as integer) as string

			dim res as string = ""
			try

				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				sql = "select tb.*, sched.*, away.team_name as away_team, home.team_name as home_team from pool.tiebreakers tb full outer join football.sched sched on tb.pool_id=sched.pool_id and tb.game_id=sched.game_id full outer join football.teams away on away.team_id=sched.away_id full outer join football.teams home on home.team_id=sched.home_id where tb.pool_id=? and tb.week_id=?"

				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()
				cmd = new odbccommand(sql,con)
			


				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				parm1 = new odbcparameter("@week_id", odbctype.int)
				parm1.value = week_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				dim ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(ds)
				try
					res = ds.tables(0).rows(0)("away_team") & " at " & ds.tables(0).rows(0)("home_team") 
				catch
					res = "Tie Breaker Game Not Set"
				end try
				con.close()

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
						res = updatepick(pool_id:=pool_id, username:=player_name, game_id:=game_id, team_id:=team_id)
					end if
				next
			catch ex as exception
				makesystemlog("error in submitpicks", ex.tostring())
			end try
			try
				if r("tiebreaker") <> "" then
					dim tbvalue as integer
					tbvalue = r("tiebreaker")
					updatetiebreaker(pool_id:=pool_id, week_id:=r("week_id"), username:=player_name, score:=tbvalue)
				end if
			catch ex as exception
				makesystemlog("error in submitpicks", ex.tostring())
			end try
		end function
	
		private function UpdateTiebreaker(POOL_ID as INTEGER, USERNAME as String, score as integer, week_ID as INTEGER) as String
			Dim res as String = ""

			try
				dim cn as new odbcconnection()
				cn.connectionstring = myconnstring
				cn.open()
				dim sql as string = "update FOOTBALL.TIEBREAKER set SCORE=? where USERNAME=? and WEEK_ID=? and  POOL_ID=? "
				dim cmd as odbccommand = new odbccommand(sql, cn)

				cmd.parameters.add(new odbcparameter("@SCORE", odbctype.int))
				cmd.parameters.add(new odbcparameter("@USERNAME", odbctype.VARCHAR, 50))
				cmd.parameters.add(new odbcparameter("@WEEK_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters("@USERNAME").value = USERNAME
				cmd.parameters("@WEEK_ID").value = WEEK_ID
				cmd.parameters("@SCORE").value = SCORE
				cmd.parameters("@POOL_ID").value = POOL_ID

				Dim rowsaffected as integer = 0
				rowsaffected = cmd.executenonquery()

				If rowsaffected = 0 Then

					sql = "insert into FOOTBALL.TIEBREAKER(USERNAME, WEEK_ID, SCORE, POOL_ID) values (?, ?, ?, ?)"
					cmd = new odbccommand(sql, cn)

					cmd.parameters.add(new odbcparameter("@USERNAME", odbctype.VARCHAR, 50))
					cmd.parameters.add(new odbcparameter("@WEEK_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@SCORE", odbctype.int))
					cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
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

				cn.close()
			catch ex as exception
				res = ex.message
				makesystemlog("error updating pick", ex.toString())
			end try
			return res
		end function

		public function GetAllPicksForWeek(pool_id as integer, week_id as integer) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select a.pool_id, a.game_id, a.username, a.team_id, b.team_shortname as pick_name, c.game_tsp from pool.picks a full outer join football.teams b on a.team_id=b.team_id and a.pool_id=b.pool_id full outer join football.sched c on a.game_id=c.game_id and a.pool_id=c.pool_id where a.pool_id=? and a.game_id in (select game_id from football.sched where pool_id=? and week_id=?)"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("pool_id2", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("week_id", odbctype.int)
				parm1.value = week_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.SelectCommand = cmd
				oda.Fill(res)

				con.close()
			catch ex as exception
				makesystemlog("Error getting pool GetAllPicksForWeek", ex.tostring())
			end try

			return res

		end function
		public function GetPicksForWeek(pool_id as integer, week_id as integer, player_name as string) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from pool.picks  where pool_id=? and username=? and game_id in (select game_id from football.sched where pool_id=? and week_id=?)"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)


				cmd.parameters.add(new odbcparameter("@USERNAME", odbctype.VARCHAR, 50))
				cmd.parameters("@USERNAME").value = player_name


				parm1 = new odbcparameter("pool_id2", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("week_id", odbctype.int)
				parm1.value = week_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.SelectCommand = cmd
				oda.Fill(res)

				con.close()
			catch ex as exception
				makesystemlog("Error getting pool picksforweek", ex.tostring())
			end try

			return res
		end function


		public function gettiebreakervalue(pool_id as integer, week_id as integer, player_name as string) as string

			dim res as string = ""
			try

				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				sql = "select score from football.tiebreaker  where pool_id=? and week_id=? and username=?"

				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()
				cmd = new odbccommand(sql,con)
			


				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				parm1 = new odbcparameter("@week_id", odbctype.int)
				parm1.value = week_id
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("@username", odbctype.varchar, 50)
				parm1.value = player_name
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				dim ds as new dataset()
				oda.selectcommand = cmd
				oda.fill(ds)
				try
					res = ds.tables(0).rows(0)("score") 
				catch
					res = ""
				end try
				con.close()

			catch ex as exception
				makesystemlog("error in gettiebreakervalue", ex.tostring())
			end try

			return res

		end function

		
		public function GetMyPools(player_name as string) as dataset

			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from pool.pools where pool_owner=? or pool_id in (select pool_id from pool.players where username=?)"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = player_name
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("@player_name", odbctype.varchar, 50)
				parm1.value = player_name
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
			catch ex as exception
				makesystemlog("Error getting pool list", ex.tostring())
			end try

			return res
		end function
		
		public function GetSchedule(pool_id as integer) as dataset


			dim res as new system.data.dataset()
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from football.sched sched full outer join football.teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join football.teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.pool_id in (select pool_id from pool.pools where pool_id=?) order by sched.game_tsp"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
			catch ex as exception
				makesystemlog("Error getting schedule", ex.tostring())
			end try

			return res
		end function

		
		public function validatekey (invite_key as string, email as string, pool_id as integer) as boolean
			dim res as boolean = false

			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()

				sql = "select * from pool.invites where email=? and pool_id=? and invite_key=?"

				cmd = new odbccommand(sql,con)
				cmd.parameters.add(new odbcparameter("@EMAIL", odbctype.VARCHAR, 255))
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@INVITE_KEY", odbctype.VARCHAR, 40))

				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@EMAIL").value = EMAIL
				cmd.parameters("@INVITE_KEY").value = INVITE_KEY
				
				'makesystemlog("debug", "pool_id=" &  cmd.parameters("@POOL_ID").value & ".")
				'makesystemlog("debug", "email=" &  cmd.parameters("@EMAIL").value & ".")
				'makesystemlog("debug", "invite_key=" &  cmd.parameters("@INVITE_KEY").value & ".")

				dim invites_ds as new dataset()
				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(invites_ds)
				if invites_ds.tables(0).rows.count > 0 then
					res = true
				end if

				con.close()
			catch ex as exception
				makesystemlog("Error in validatekey", ex.tostring())
			end try

			return res
		end function
		
		public function AcceptInvitation (invite_key as string, email as string, pool_id as integer, player_name as string) as string
			dim res as string = ""

			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				dim connstring as string
				connstring = myconnstring
				
				con = new odbcconnection(connstring)
				con.open()
				sql = "select * from pool.pools a full outer join admin.users b on a.pool_owner=b.username where pool_id=?"

				cmd = new odbccommand(sql,con)
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters("@POOL_ID").value = POOL_ID

				dim pool_ds as new dataset()
				dim oda as new odbcdataadapter()
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


				sql = "insert into pool.players (pool_id, username, player_tsp) values (?,?,?)"

				cmd = new odbccommand(sql,con)
				cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
				cmd.parameters.add(new odbcparameter("@USERNAME", odbctype.VARCHAR, 50))
				cmd.parameters.add(new odbcparameter("@PLAYER_TSP", odbctype.datetime))

				cmd.parameters("@POOL_ID").value = POOL_ID
				cmd.parameters("@USERNAME").value = player_name
				cmd.parameters("@PLAYER_TSP").value = system.datetime.now
				dim rowsaffected as integer
				rowsaffected = cmd.executenonquery()
				if rowsaffected > 0 then

					sql = "delete from pool.invites where email=? and pool_id=? and invite_key=?"

					cmd = new odbccommand(sql,con)
					cmd.parameters.add(new odbcparameter("@EMAIL", odbctype.VARCHAR, 255))
					cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@INVITE_KEY", odbctype.VARCHAR, 40))

					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@EMAIL").value = EMAIL
					cmd.parameters("@INVITE_KEY").value = INVITE_KEY
					cmd.executenonquery()
					res = email

					dim sb as new stringbuilder()
					sb.append("Your invitation has been accepted.<br />")
					sb.append("Pool Name: " & pool_name & "<br />")
					sb.append("Player Name: " & player_name & "<br />")
					'SendEmail(emailaddress as string, Subject as string, Body as String)
					sendemail(emailaddress:=pool_owner_email, subject:="Invitation accepted", body:=sb.tostring())

				else
					res = "Invalid input info."
				end if

				con.close()
			catch ex as exception
				res = ex.message
				makesystemlog("Error in AcceptInvitation", ex.tostring())
			end try

			return res
		end function

		public function ResetPassword(username as string) as string
			dim res as string
			try
								
				dim temppassword as string
				temppassword = CreateTempPassword()


				'Encrypt the password
				Dim md5Hasher as New MD5CryptoServiceProvider()
				
				Dim hashedBytes as Byte()   
				Dim encoder as New UTF8Encoding()
				
				hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(temppassword))

				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
				
				sql = "select * from final table (update admin.users set temp_password=? where ucase(username)=? or ucase(email)=?)"
								
				con = new odbcconnection(myconnstring)
				con.open()
				cmd = new odbccommand(sql,con)
			
				parm1 = new odbcparameter("password", odbctype.Binary, 16)
				parm1.value = hashedbytes
				cmd.parameters.add(parm1)

				parm1 = new odbcparameter("username", odbctype.varchar, 50)
				parm1.value = username.toUpper()
				cmd.parameters.add(parm1)
				
				parm1 = new odbcparameter("email", odbctype.varchar, 50)
				parm1.value = username.toUpper()
				cmd.parameters.add(parm1)
				
				dim user_ds as system.data.dataset = new dataset()
				dim oda as system.data.odbc.odbcdataadapter = new system.data.odbc.odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(user_ds)
				con.close()

				if user_ds.tables(0).rows.count > 0 then
					
					dim sb as stringbuilder = new stringbuilder()
					sb.append( "A request has been received to reset your password.  The following password is temporary.  If this message is in error, and you have not requested to reset your password, then you do not have to do anything.  <br/><br/>Your password will still work normally.  <br/><br/>If you did request to have your password reset, when you login using this password it will become your permanent password until you choose to change it.<br /><br />")
					sb.append("Username: " & username & "<br/>")
					sb.append("Password: " & temppassword & "<br/>")

					SendEmail(user_ds.tables(0).rows(0)("email"), "Your password has been reset.",sb.tostring())		
				end if

				res = username
				makesystemlog("Password reset", "Input Username: " & username)
			catch ex as exception
				res = ex.message
				makesystemlog("error in resetpassword", ex.tostring())
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
				myMessage.From = "chrishad95@yahoo.com"
				myMessage.To = emailaddress
				myMessage.Subject = subject
				myMessage.Body = body
				
				myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtsperver", "smtp.mail.yahoo.com")
				myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserverport", 25)
				myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusing", 2)
				myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1)
				myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusername", "chrishad95")
				myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendpassword", "househorse89")
				
				' Doesn't have to be local... just enter your
				' SMTP server's name or ip address!
				
				
				SmtpMail.SmtpServer = "smtp.mail.yahoo.com"
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

				dim usercount as integer
				
				dim validate_key as string
				
				dim con as odbcconnection
				dim cmd as odbccommand
				dim dr as odbcdatareader
				dim parm1 as odbcparameter
							
				dim sql as string
				con = new odbcconnection(myconnstring)
				con.open()
				
				sql = "select count(*) from admin.users where ucase(username) = ? or ucase(email) = ?"
				
				cmd = new odbccommand(sql,con)
				
				parm1 = new odbcparameter("username", odbctype.varchar, 30)
				parm1.value = username.toupper()
				cmd.parameters.add(parm1)
				
				parm1 = new odbcparameter("email", odbctype.varchar, 50)
				parm1.value = email.toupper()
				cmd.parameters.add(parm1)
				
				usercount = cmd.ExecuteScalar()
				
				if usercount > 0 then
					res = "Username and/or email is already registered."
				else

					'Encrypt the password
					Dim md5Hasher as New MD5CryptoServiceProvider()
					
					Dim hashedBytes as Byte()   
					Dim encoder as New UTF8Encoding()
					
					hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(password))
					
					
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
								
					sql = "insert into admin.users (username,email,password,login_count,validated,validate_key, last_seen) values (?,?,?,0,'N',?, ?)"
					
					cmd = new odbccommand(sql,con)
					
					parm1 = new odbcparameter("username", odbctype.varchar, 30)
					parm1.value = username
					cmd.parameters.add(parm1)
					
					parm1 = new odbcparameter("email", odbctype.varchar, 50)
					parm1.value = email
					cmd.parameters.add(parm1)
					
					parm1 = new odbcparameter("password", odbctype.Binary, 16)
					parm1.value = hashedbytes
					cmd.parameters.add(parm1)
					
					parm1 = new odbcparameter("validate_key", odbctype.varchar, 40)
					parm1.value = validate_key
					cmd.parameters.add(parm1)

					parm1 = new odbcparameter("last_seen", odbctype.datetime)
					parm1.value = system.datetime.now
					cmd.parameters.add(parm1)
					
					cmd.executenonquery()
					
					
					dim sb as new stringbuilder()
					
					sb.append("You have registered to use the superpools.gotdns.com website.  <br><br>" & system.environment.newline)
					
					sb.append ("Username: " & username & " <br><br>" & system.environment.newline)
					
					sb.append ("Password: " & password & " <br><br>" & system.environment.newline)
					
					sb.append ("To verify that this is a valid email address you must go to the URL below before you can login using your username and password. <br><br>" & system.environment.newline)
					
					
					sb.append("Here is your validation link.<br><br>" & system.environment.newline)
					sb.append("<a href=""http://superpools.gotdns.com/validate_registration.aspx?username=" & username & "&validate_key=" & validate_key & """>http://superpools.gotdns.com/validate_registration.aspx?username=" & username & "&validate_key=" & validate_key & "</a> <br /><br /><br />" & system.environment.newline & system.environment.newline & "Thanks,<br />" & system.environment.newline & "Chris")
					
					
					sendemail(emailaddress:=email, subject:="superpools.gotdns.com registration verification" , body:=sb.tostring())
					res = email
				end if
			catch ex as exception
				res = ex.message
				MakeSystemLog("error in registeruser", ex.tostring())
			end try
			return res
		end function
		public function resendinvite(pool_id as integer, email as string) as string
			dim res as string = ""
			try

				dim cmd as odbccommand
				dim dr as odbcdatareader
				dim parm1 as odbcparameter
							
				dim sql as string
				con = new odbcconnection(myconnstring)
				con.open()
				
				sql = "select a.pool_id, a.email, a.invite_key, b.pool_owner, b.pool_name, b.pool_desc from pool.invites a full outer join pool.pools b on a.pool_id=b.pool_id where a.pool_id=? and a.email=?"
				
				cmd = new odbccommand(sql,con)
				
				parm1 = new odbcparameter("pool_id", odbctype.int)
				parm1.value = pool_id
				cmd.parameters.add(parm1)
				
				parm1 = new odbcparameter("email", odbctype.varchar, 50)
				parm1.value = email
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
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
						pool_desc:=invite_ds.tables(0).rows(0)("pool_desc"), _
						pool_id:=pool_id, _
						pool_owner:=invite_ds.tables(0).rows(0)("pool_owner"), _
						pool_name:=invite_ds.tables(0).rows(0)("pool_name"))
						res = email

					end if
				end if

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
					
					myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtsperver", "smtp.mail.yahoo.com")
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
				
		public function Login(username as string, password as string) as string
			dim res as string = ""
			try

				dim usercount as integer = 0		
				
				dim cmd as odbccommand
				dim dr as odbcdatareader
				dim parm1 as odbcparameter
				
				dim sql as string
						
				con = new odbcconnection(myconnstring)
				con.open()
				
				'Encrypt the password
				Dim md5Hasher as New MD5CryptoServiceProvider()
				
				Dim hashedBytes as Byte()   
				Dim encoder as New UTF8Encoding()
				
				hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(password))
				
				sql = "select username from admin.users where ucase(username) = ? and password=? and validated='Y'"
				
				cmd = new odbccommand(sql,con)
				
				parm1 = new odbcparameter("username", odbctype.varchar, 30)
				parm1.value = username.toupper()
				cmd.parameters.add(parm1)
				
				parm1 = new odbcparameter("password", odbctype.Binary, 16)
				parm1.value = hashedbytes
				cmd.parameters.add(parm1)
				
				dim user_ds as system.data.dataset = new dataset()
				dim oda as system.data.odbc.odbcdataadapter = new system.data.odbc.odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(user_ds)
		
				if user_ds.tables(0).rows.count <= 0 then
					'makesystemlog("Failed Login First Try", "Username:" & username & " - Password:" & password)
					
					sql = "select username from admin.users where ucase(username) = ? and temp_password=? and validated='Y'"
					
					cmd = new odbccommand(sql,con)
					
					parm1 = new odbcparameter("username", odbctype.varchar, 30)
					parm1.value = username.toupper()
					cmd.parameters.add(parm1)
					
					parm1 = new odbcparameter("password", odbctype.Binary, 16)
					parm1.value = hashedbytes
					cmd.parameters.add(parm1)
					
					dim user_ds2 as system.data.dataset = new dataset()
					dim oda2 as system.data.odbc.odbcdataadapter = new system.data.odbc.odbcdataadapter()
					oda2.selectcommand = cmd
					oda2.fill(user_ds2)
				
					if user_ds2.tables(0).rows.count > 0 then
						sql = "update admin.users set password=temp_password where username = ?"
		
						cmd = new odbccommand(sql,con)
		
						parm1 = new odbcparameter("username", odbctype.varchar, 30)
						parm1.value = user_ds2.tables(0).rows(0)("username")
						cmd.parameters.add(parm1)
						
						dim ra as integer
						ra = cmd.executenonquery()
						'makesystemlog ("Updated admin.users", "Updated admin.users with new password. Rows affected=" & ra)
		
						' refill user_ds dataset so the rest of the code will work normally 
		
						sql = "select username from admin.users where ucase(username) = ? and password=? and validated='Y'"
				
						cmd = new odbccommand(sql,con)
						
						parm1 = new odbcparameter("username", odbctype.varchar, 30)
						parm1.value = username.toupper()
						cmd.parameters.add(parm1)
						
						parm1 = new odbcparameter("password", odbctype.Binary, 16)
						parm1.value = hashedbytes
						cmd.parameters.add(parm1)
						
						user_ds = new dataset()
						oda = new system.data.odbc.odbcdataadapter()
						oda.selectcommand = cmd
						oda.fill(user_ds)
					else
					end if
				
				end if
		
				if user_ds.tables(0).rows.count > 0 then
					res = user_ds.tables(0).rows(0)("username")
					
					sql = "update admin.users set login_count=login_count + 1, last_seen = current timestamp, temp_password = NULL  where username=?"
					
					cmd = new odbccommand(sql,con)
					
					parm1 = new odbcparameter("username", odbctype.varchar, 30)
					parm1.value = res
					cmd.parameters.add(parm1)
					
					cmd.executenonquery()
				end if
			catch ex as exception
				res = ex.message
				makesystemlog("error in login", ex.tostring())
			end try
			return res
		end function
	end Class
End Namespace