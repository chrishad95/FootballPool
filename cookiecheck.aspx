<%@ Page Language="vb" Debug="true" %>
<%@ import namespace="system.io" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server" language="VB">
	private sub MakeSystemLog (log_title as string, log_text as string)
		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		sql = "insert into journal.entries (username,journal_type,entry_tsp,entry_date,entry_title,entry_text) values (?,?,current timestamp,date(current timestamp),?,?)"
		
		
		dim connstring as string = System.Configuration.ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()
		cmd = new SQLCommand(sql,con)
	
		parm1 = new SQLParameter("username", SQLDbType.varchar, 50)
		parm1.value = "chadley"
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("journal_type", SQLDbType.varchar, 20)
		parm1.value = "SYSTEM"
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("entry_title", SQLDbType.varchar, 200)
		parm1.value = log_title
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("entry_text", SQLDbType.text, 32700)
		parm1.value = log_text
		cmd.parameters.add(parm1)
		
		cmd.executenonquery()
	end sub
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

application("football_year") = "2005"
	
	dim username as string
	dim password as string
	username = ""
	password = ""
	
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

	Dim cn As SQLConnection
		
	dim sConnString as string = ConfigurationSettings.AppSettings("connString")
	
	dim dr as SQLDataReader
	dim cmd as SQLCommand
	dim oda as SQLDataAdapter
	dim ds as dataset
	dim parm1 as SQLParameter
	
	dim sql as string
	dim count 
	
	cn = New System.Data.SQLClient.SQLConnection(sConnString)
	cn.Open()
	
	if myname = "" then
		try
			dim mycookies as HttpCookieCollection
			mycookies = request.cookies
			username = ""
			password = ""

			try
				username = mycookies("username").value
				password = mycookies("password").value
			catch 
			end try
			if username <> "" and password <> "" then
				
				'Encrypt the password
				Dim md5Hasher as New MD5CryptoServiceProvider()
				
				Dim hashedBytes as Byte()   
				Dim encoder as New UTF8Encoding()
				
				hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(password))
				
				sql = "select username from admin.users where ucase(username) = ? and password=? and validated='Y'"
				
				cmd = new SQLCommand(sql,cn)
				
				parm1 = new SQLParameter("username", SQLDbType.varchar, 30)
				parm1.value = username.toupper()
				cmd.parameters.add(parm1)
				
				parm1 = new SQLParameter("password", SQLDbType.Binary, 16)
				parm1.value = hashedbytes
				cmd.parameters.add(parm1)
				
				dim user_ds as system.data.dataset = new dataset()
				oda = new System.Data.SQLClient.SQLDataAdapter()
				oda.selectcommand = cmd
				oda.fill(user_ds)
				
				
				if user_ds.tables(0).rows.count > 0 then
					username = user_ds.tables(0).rows(0)("username")
					session("username") = username
					myname = username
					
					sql = "update admin.users set login_count=login_count + 1, last_seen = current timestamp where username=?"
					
					cmd = new SQLCommand(sql,cn)
					
					parm1 = new SQLParameter("username", SQLDbType.varchar, 30)
					parm1.value = username
					cmd.parameters.add(parm1)
					
					cmd.executenonquery()
				end if
			end if
				
	
		catch ex as exception
			makesystemlog("Error Detected - " & datetime.now, ex.tostring())
		end try
		
	end if
			
	if myname <> "chadley" then
		try
			
			dim page_url
			dim http_referer as string
			dim http_user_agent as string
			http_user_agent = ""
			
			page_url = request.servervariables("URL")
			
			if request.servervariables("QUERY_STRING") <> "" then
				page_url = page_url & "?" & request.servervariables("QUERY_STRING")
			end if
			page_url = page_url.toLower()
			
			http_referer = request.servervariables("HTTP_REFERER")
			if http_referer is nothing then
				http_referer = ""
			end if
			http_user_agent = request.servervariables("HTTP_USER_AGENT")
			if http_user_agent is nothing then
				http_user_agent = ""
			end if
			
	
			sql = "insert into admin.pagecount (page_url, page_count, page_tsp, username, http_referer,remote_addr,http_user_agent) values (?,1,current timestamp,?,?,?,?)"
	
			cmd = new SQLCommand(sql,cn)
		
			parm1 = new SQLParameter("page_url", SQLDbType.varchar, 500)
			parm1.value = cstr(page_url)
			cmd.parameters.add(parm1)
		
			
			if session("username") = "" then
				parm1 = new SQLParameter("username", SQLDbType.varchar, 50)
				parm1.value = request.servervariables("REMOTE_ADDR")
				cmd.parameters.add(parm1)
			else
				parm1 = new SQLParameter("username", SQLDbType.varchar, 50)
				parm1.value = myname
				cmd.parameters.add(parm1)
			end if
			
		
			parm1 = new SQLParameter("http_referer", SQLDbType.varchar, 1000)
			parm1.value = http_referer
			cmd.parameters.add(parm1)
			
			parm1 = new SQLParameter("remote_addr", SQLDbType.varchar, 20)
			parm1.value = request.servervariables("REMOTE_ADDR").toString()
			cmd.parameters.add(parm1)
		
			parm1 = new SQLParameter("http_user_agent", SQLDbType.varchar, 255)
			parm1.value = http_user_agent
			cmd.parameters.add(parm1)
				
			cmd.executenonquery()
		catch ex as exception
			makesystemlog("Error Detected - " & datetime.now, ex.tostring())
		end try
	end if


	dim mysessionid as string = ""
	try
		mysessionid = request.cookies("mysessionid").value
	catch
	end try

	try

		if mysessionid = "" then
			mysessionid = getrandomstring()
			Dim MyCookie As New HttpCookie("mysessionid")
			MyCookie.Value = mysessionid
			Response.Cookies.Add(MyCookie)
		end if


		sql = "update admin.sessions set value=? where session_key=? and name=?"

		dim cmd1 as new SQLCommand(sql,cn)

		cmd1.parameters.add(new SQLParameter("value", SQLDbType.text))
		cmd1.parameters.add(new SQLParameter("session_key", SQLDbType.varchar, 40))
		cmd1.parameters.add(new SQLParameter("name", SQLDbType.varchar, 255))
		cmd1.parameters("session_key").value = mysessionid

		for each x as object in session.contents
			dim ra as integer = 0
			cmd1.parameters("name").value = x
			cmd1.parameters("value").value = session(x)
			ra = cmd1.executenonquery()
			if ra < 1 then

				sql = "insert into admin.sessions (session_key, name, value) values (?,?,?)"
				cmd = new SQLCommand(sql,cn)

				cmd.parameters.add(new SQLParameter("session_key", SQLDbType.varchar, 40))
				cmd.parameters.add(new SQLParameter("name", SQLDbType.varchar, 255))
				cmd.parameters.add(new SQLParameter("value", SQLDbType.text))
				cmd.parameters("session_key").value = mysessionid
				cmd.parameters("name").value = x
				cmd.parameters("value").value = session(x)
				cmd.executenonquery()
			end if
		next


		sql = "select * from admin.sessions where session_key=?"


		cmd = new SQLCommand(sql,cn)

		cmd.parameters.add(new SQLParameter("session_key", SQLDbType.varchar, 40))
		cmd.parameters("session_key").value = mysessionid
		dim session_ds as new dataset()
		oda = new SQLDataAdapter()
		oda.selectcommand = cmd
		oda.fill(session_ds)

		try
			for each sdrow as datarow in session_ds.tables(0).rows
				dim n as string = sdrow("name")
				dim v as string = sdrow("value")
				session(n) = v
			next
		catch
		end try


	catch ex as exception
	end try
%>
