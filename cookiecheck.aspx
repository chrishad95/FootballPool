<%@ Page language="VB" debug="true" src="/football/football.vb" %>
<%@ import namespace="system.io" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server" language="VB">
	private function getrandomstring() as string

		Dim validcharacters as String
		validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
		
		dim c as char
		Thread.Sleep( 30 )
		
		Dim fixRand As New Random()
		dim randomstring as stringbuilder = new stringbuilder(40)	
		
		dim i as integer
		for i = 0 to 39    
			randomstring.append(validcharacters.substring(fixRand.Next( 0, len(validcharacters) ),1))		
		next
		return randomstring.ToString()

	end function
</script>
<%

dim fb as new Rasputin.FootballUtility()

application("football_year") = "2005"
	
	
	dim myname as string
	myname = ""
	try
		if session("username") <> "" then
			myname = session("username")
		end if
	catch
	end try
	if myname = "" then
		session("username") = ""
	end if

	if myname = "" then
		try
			dim mycookies as HttpCookieCollection
			mycookies = request.cookies
			dim username as string
			dim password as string
			username = ""
			password = ""

			try
				username = mycookies("username").value
				password = mycookies("password").value
			catch 
			end try
			if username <> "" and password <> "" then
				dim res as string
				res = fb.authenticate(username, password)
				if res <> "" then
					session("username") = res
					myname = res
				end if
			end if
		catch ex as exception
			fb.makesystemlog("Error Detected - " & datetime.now, ex.tostring())
		end try
		
	end if

' not sure what this stuff is for

'	dim mysessionid as string = ""
'	try
'		mysessionid = request.cookies("mysessionid").value
'	catch
'	end try
'
'	try
'
'		if mysessionid = "" then
'			mysessionid = getrandomstring()
'			Dim MyCookie As New HttpCookie("mysessionid")
'			MyCookie.Value = mysessionid
'			Response.Cookies.Add(MyCookie)
'		end if
'
'
'		sql = "update admin.sessions set value=? where session_key=? and name=?"
'
'		dim cmd1 as new SQLCommand(sql,cn)
'
'		cmd1.parameters.add(new SQLParameter("value", SQLDbType.text))
'		cmd1.parameters.add(new SQLParameter("session_key", SQLDbType.varchar, 40))
'		cmd1.parameters.add(new SQLParameter("name", SQLDbType.varchar, 255))
'		cmd1.parameters("session_key").value = mysessionid
'
'		for each x as object in session.contents
'			dim ra as integer = 0
'			cmd1.parameters("name").value = x
'			cmd1.parameters("value").value = session(x)
'			ra = cmd1.executenonquery()
'			if ra < 1 then
'
'				sql = "insert into admin.sessions (session_key, name, value) values (?,?,?)"
'				cmd = new SQLCommand(sql,cn)
'
'				cmd.parameters.add(new SQLParameter("session_key", SQLDbType.varchar, 40))
'				cmd.parameters.add(new SQLParameter("name", SQLDbType.varchar, 255))
'				cmd.parameters.add(new SQLParameter("value", SQLDbType.text))
'				cmd.parameters("session_key").value = mysessionid
'				cmd.parameters("name").value = x
'				cmd.parameters("value").value = session(x)
'				cmd.executenonquery()
'			end if
'		next
'
'
'		sql = "select * from admin.sessions where session_key=?"
'
'
'		cmd = new SQLCommand(sql,cn)
'
'		cmd.parameters.add(new SQLParameter("session_key", SQLDbType.varchar, 40))
'		cmd.parameters("session_key").value = mysessionid
'		dim session_ds as new dataset()
'		oda = new SQLDataAdapter()
'		oda.selectcommand = cmd
'		oda.fill(session_ds)
'
'		try
'			for each sdrow as datarow in session_ds.tables(0).rows
'				dim n as string = sdrow("name")
'				dim v as string = sdrow("value")
'				session(n) = v
'			next
'		catch
'		end try
'
'
'	catch ex as exception
'	end try
%>
