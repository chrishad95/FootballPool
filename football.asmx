<%@ WebService Language="VB" Class="Football" %>
Imports System
Imports System.Web.Services
Imports System.Data
Imports System.Data.odbc
Imports System.Configuration
Imports System.Web.Mail
Imports System.Collections
Imports System.Text.RegularExpressions
Imports System.Text
Imports System.Security.Cryptography

Public Class Football


	private myconnstring  = System.Configuration.ConfigurationSettings.AppSettings("connString")
	private con as odbcconnection
	
	Private function MakeSystemLog (log_title , log_text ) 
		dim res as string = "FAILURE"
		try 
		
			dim sql as string
			dim cmd as odbccommand
			dim con as odbcconnection
			dim parm1 as odbcparameter
			
			sql = "insert into journal.entries (username,journal_type,entry_tsp,entry_date,entry_title,entry_text) values (?,?,current timestamp,date(current timestamp),?,?)"
						
			con = new odbcconnection(myconnstring)
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
			res = "SUCCESS"
		catch ex as exception
			res = ex.tostring()
		end try
		return res
	end function 
	private function authorized(uid as string, pwd as string) as boolean
		dim res as boolean = false
		try
			dim sql as string
			
			'Encrypt the password
			Dim md5Hasher as New MD5CryptoServiceProvider()
			
			Dim hashedBytes as Byte()   
			Dim encoder as New UTF8Encoding()
			
			hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(pwd))
			
			sql = "select count(*) from admin.users where ucase(username) = ? and password=? and validated='Y'"
			
			con = new odbcconnection(myconnstring)
			con.open()
			dim cmd as new odbccommand(sql,con)
			
			cmd.parameters.add(new odbcparameter("username", odbctype.varchar, 30))
			cmd.parameters("username").value = uid.toupper()
			
			cmd.parameters.add(new odbcparameter("password", odbctype.Binary, 16))
			cmd.parameters("password").value = hashedbytes
			
			dim c as integer = 0
			c = cmd.executescalar()
			if c > 0 then
				res = true
			end if
			
		catch ex as exception
			makesystemlog("Error in authorized", ex.tostring())
		end try
		return res
	end function
	
	<WebMethod()> Public Function Log(title as string, message as string, uid as string, pwd as string) 
	if authorized(uid, pwd) then
		return MakeSystemLog(title, message)
	else
		return "Invalid userid/password."
	end if
	
	End Function
	
	<WebMethod()> Public Function Login(uid as string, pwd as string) 
	if authorized(uid, pwd) then
		return "SUCCESS"
	else
		return "Invalid userid/password."
	end if
	
	End Function
	
	<WebMethod()> Public Function ListMyPools( uid AS STRING, pwd as string) as DataSet	

		dim res as new system.data.dataset()
		if authorized(uid, pwd) then
			try
				dim sql as string
				dim cmd as odbccommand
				dim con as odbcconnection
				dim parm1 as odbcparameter
							
				con = new odbcconnection(myconnstring)
				con.open()

				sql = "select * from pool.pools where pool_owner=?"

				cmd = new odbccommand(sql,con)

				parm1 = new odbcparameter("@pool_owner", odbctype.varchar, 50)
				parm1.value = uid
				cmd.parameters.add(parm1)

				dim oda as new odbcdataadapter()
				oda.selectcommand = cmd
				oda.fill(res)
			
				con.close()
				con.dispose()
			catch ex as exception
				makesystemlog("Error getting pool list", ex.tostring())
			end try
		End if
		return res
	End Function
	

	<WebMethod()> Public Function CreatePool(POOL_OWNER as string, POOL_NAME as string, POOL_DESC as string, ELIGIBILITY as string, POOL_LOGO as string, POOL_BANNER as string, uid as string, pwd as string) as string
		dim res  = "FAILURE"
		if authorized(uid, pwd) then
			try
				con.connectionstring = myconnstring
				con.open()
				dim sql  as string = "insert into POOL.POOLS(POOL_OWNER, POOL_NAME, POOL_DESC, POOL_TSP, ELIGIBILITY, POOL_LOGO, POOL_BANNER) values (?, ?, ?, ?, ?, ?, ?)"
				dim cmd as odbccommand = new odbccommand(sql, con)
		
				cmd.parameters.add(new odbcparameter("@POOL_OWNER", odbctype.VARCHAR, 50))
				cmd.parameters.add(new odbcparameter("@POOL_NAME", odbctype.VARCHAR, 100))
				cmd.parameters.add(new odbcparameter("@POOL_DESC", odbctype.VARCHAR, 500))
				cmd.parameters.add(new odbcparameter("@POOL_TSP", odbctype.datetime))
				cmd.parameters.add(new odbcparameter("@ELIGIBILITY", odbctype.VARCHAR, 10))
				cmd.parameters.add(new odbcparameter("@POOL_LOGO", odbctype.VARCHAR, 255))
				cmd.parameters.add(new odbcparameter("@POOL_BANNER", odbctype.VARCHAR, 255))
				cmd.parameters("@POOL_OWNER").value = POOL_OWNER
				cmd.parameters("@POOL_NAME").value = POOL_NAME
				cmd.parameters("@POOL_DESC").value = POOL_DESC
				cmd.parameters("@POOL_TSP").value = system.datetime.now
				cmd.parameters("@ELIGIBILITY").value = ELIGIBILITY
				cmd.parameters("@POOL_LOGO").value = POOL_LOGO
				cmd.parameters("@POOL_BANNER").value = POOL_BANNER
				cmd.executenonquery()
				con.close()
				res = "SUCCESS"
			catch ex as exception
				makesystemlog("newpool broke", ex.tostring())	
				res = ex.toString()
			end try
		End if
		return res
	
	End Function	

	<WebMethod()> Public Function GetPoolDetails(pool_id as integer, uid as string, pwd as string) as dataset

	
		dim res as new system.data.dataset()
		if authorized(uid, pwd) then
			if isowner(pool_id, uid) then
				try
					dim sql as string
					dim cmd as odbccommand
					dim con as odbcconnection
					dim parm1 as odbcparameter
								
					con = new odbcconnection(myconnstring)
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
			end if
		end if

		return res	
	End Function	
		

	<WebMethod()> Public Function GetTeams(pool_id as integer, uid as string, pwd as string) as dataset

	
		dim res as new system.data.dataset()
		if authorized(uid, pwd) then
			if isowner(pool_id, uid) then
				try
					dim sql as string
					dim cmd as odbccommand
					dim con as odbcconnection
					dim parm1 as odbcparameter
								
					con = new odbcconnection(myconnstring)
					con.open()

					sql = "select * from football.teams where pool_id=?"

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
					makesystemlog("Error in GetTeams", ex.tostring())
				end try
			end if
		end if

		return res	
	End Function	

	<WebMethod()> Public Function GetGames(pool_id as integer, uid as string, pwd as string) as dataset

	
		dim res as new system.data.dataset()
		if authorized(uid, pwd) then
			if isowner(pool_id, uid) Then			
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
					parm1.value = uid
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
			end if
		end if

		return res	
	End Function	
		

	<WebMethod()> Public Function ChangeNickname(pool_id as integer, player_id as integer, nickname as string, uid as String, pwd as string) as String
	
		dim res as string = "FAILURE"

		if authorized(uid, pwd) then
			if isowner(pool_id, uid) Then			
				try
					dim cn as new odbcconnection()
					cn.connectionstring = myconnstring
					cn.open()
					dim sql as string = "update POOL.PLAYERS set NICKNAME=? WHERE POOL_ID=? AND PLAYER_ID=?"
					dim cmd as odbccommand = new odbccommand(sql, cn)

					cmd.parameters.add(new odbcparameter("@NICKNAME", odbctype.VARCHAR, 100))
					cmd.parameters.add(new odbcparameter("@POOL_ID", odbctype.int))
					cmd.parameters.add(new odbcparameter("@PLAYER_ID", odbctype.INT))

					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.parameters("@PLAYER_ID").value = PLAYER_ID
					cmd.parameters("@NICKNAME").value = NICKNAME
					
					dim rowsaffected as integer = 0

					rowsaffected = cmd.executenonquery()


					If rowsaffected > 0 Then
						res = "SUCCESS"
					Else
						res = "Failed to update nickname."
					End if

					cn.close()
				catch ex as exception
					res = ex.message
					makesystemlog("error in ChangeNickname", ex.toString())
				end try
			End If
		End IF
		return res
	end function

	<WebMethod()> Public Function GetPlayers(pool_id as integer, uid as string, pwd as string) as dataset

	
		dim res as new system.data.dataset()
		if authorized(uid, pwd) then
			if isowner(pool_id, uid) then
				try
					dim sql as string
					dim cmd as odbccommand
					dim con as odbcconnection
					dim parm1 as odbcparameter
								
					con = new odbcconnection(myconnstring)
					con.open()

					sql = "select * from pool.players where pool_id=?"

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
					makesystemlog("Error in GetPlayers", ex.tostring())
				end try
			end if
		end if

		return res	
	End Function	

	<WebMethod()> Public function UpdateTeam(TEAM_ID as INTEGER, TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER, uid as string, pwd as string) as string
		dim res as string = "FAILURE"
		if authorized(uid, pwd) then
			if isowner(pool_id, uid) then
				try
					dim cn as new odbcconnection()
					cn.connectionstring = myconnstring
					cn.open()
					dim sql as string = ""

					sql = "update FOOTBALL.TEAMS set TEAM_NAME=?, TEAM_SHORTNAME=?, URL=? where POOL_ID=? and TEAM_ID=?"
					dim cmd as odbccommand = new odbccommand(sql, cn)
					dim rowsupdated as integer

					cmd.parameters.add(new odbcparameter("@TEAM_NAME", odbctype.VARCHAR, 40))
					cmd.parameters.add(new odbcparameter("@TEAM_SHORTNAME", odbctype.varchar, 5))
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
						res = "SUCCESS"
					else
						res = "Team was not updated."
					end if
				catch ex as exception
					if ex.message.tostring().indexof("duplicate rows") >= 0 then
						res = "Team already exists for this pool."
					else
						res = ex.message
						makesystemlog("Error in Update Team", ex.tostring())
					end if

				end try
			End If
		End if
		return res
	end function

	<WebMethod()> Public Function GetFeeds(uid as string, pwd as string) as dataset
		if authorized(uid, pwd) then
			return getDataset("select * from pool.rss_feeds order by FEED_TITLE")
		else
			return new dataset()
		end if
	
	End Function
	
	private function getDataset(sql as string) as dataset
		dim res as new system.data.dataset()
		try
			dim cmd as odbccommand
			dim con as odbcconnection
			dim parm1 as odbcparameter
						
			con = new odbcconnection(myconnstring)
			con.open()


			cmd = new odbccommand(sql,con)
			dim oda as new odbcdataadapter()
			oda.selectcommand = cmd
			oda.fill(res)
		
			con.close()
			con.dispose()
		catch ex as exception
			makesystemlog("Error in getDataset", ex.tostring())
		end try
		return res	
	end function
	

	private function isowner(pool_id as integer, pool_owner as string) as boolean
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
end class
