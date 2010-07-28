<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<script runat="server" language="VB">

  Sub Button1_Click(ByVal Source As Object, ByVal e As EventArgs)

	dim fb as new Rasputin.FootballUtility()

	dim username as string = ""
	try
		if session("username") <> "" then
			username = session("username")
		end if
	catch
	end try
	if username <> "" then

		dim webpath as string = "/users/" & username

		dim savepath as string = server.mappath(webpath)

		if not system.io.directory.exists(savepath) then
			system.io.directory.createdirectory(savepath)
		end if

		If upload_file.PostedFile.ContentLength > 0 Then
		  Try

			dim filename as string = System.IO.Path.GetFileName(upload_file.PostedFile.FileName)
			savepath = savepath & "\" & filename

			upload_file.PostedFile.SaveAs(savepath)
			fb.changeavatar(pool_id:=request("pool_id"), username:=username, avatar:=filename)

		  Catch exc As Exception
			
			fb.makesystemlog("Error writing upload file", exc.tostring())
			
		  End Try
		  
		End If
	end if

    
  End Sub

</script>
<%
	server.execute("/football/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
	dim submit as string
	try
		submit = request("submit")
	catch
	end try
	
	dim myname as string = ""
	try
		myname = session("username")
	catch
	end try
	if myname = "" then
		session("page_message") = "You must be logged in to pick your avatar."
		response.redirect("error.aspx", true)
	end if
	dim pool_id as integer 
	try
		pool_id = request("pool_id")
	catch
	end try
	dim avatar as string = ""
	try
		if request("avatar") <> "" then
			avatar = request("avatar")
		end if
	catch
	end try

	if fb.isplayer(pool_id:=pool_id, player_name:=myname) then
	else
		session("page_message") = "Invalid pool_id/player_name."
		response.redirect("error.aspx", true)
	end if

	dim message_text as string = ""

	if submit = "Change Avatar" then
		dim res as string
		res = fb.changeavatar(pool_id:=pool_id, username:=myname, avatar:=avatar)
		if res="SUCCESS" then
			message_text = "Your avatar was changed."
		else
			message_text = res
		end if
	end if

	dim current_avatar as string = ""	
	try
		current_avatar = fb.GetAvatar(pool_id:=pool_id, username:=myname)	
	catch
	end try

	dim pool_details_ds as new dataset()
	pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

	dim banner_image as string = ""
	if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
		banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" &  pool_details_ds.tables(0).rows(0)("pool_banner")
	end if

	dim pool_name as string = ""
	pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

%>
<html>
<head>
	<title>Change Avatar - <% = http_host %></title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	<style>
		.content {
			border: none;
			padding: 1px;
			margin:0px 0px 20px 170px;
		}
	</style>
	<link rel="stylesheet" href='hoverbox.css' type="text/css" media="screen, projection" />
	<!--[if IE]>
	<link rel="stylesheet" href='ie_fixes.css' type="text/css" media="screen, projection" />
	<![endif]-->
	
</head>

<body>

	<div class="content">
		<%
			if banner_image = "" then
				%><h1><% = pool_name %></h1><%
			else
				%><img src="<% = banner_image %>" border="0"><BR><BR><%
			end if
		%>
		<h2>Change Avatar</h2>
		<fieldset>
			<form>
			<input type="hidden" name="pool_id" value="<% = pool_id %>">
			<TABLE>
			<TR>
				<TD>Avatar:</TD>
	
				<TD><select id="avatar" name="avatar" >
				<%
					try
	
						dim userfiles as new system.collections.arraylist()
						userfiles = fb.getfiles(server.mappath("/users/" & myname ))
						dim myenum as system.collections.ienumerator = userfiles.getEnumerator()
						while myenum.movenext()
								if myenum.current.tostring() = current_avatar
									%><option value="<% = myenum.current.tostring() %>" SELECTED><% = myenum.current.tostring() %></option><%
								else
									%><option value="<% = myenum.current.tostring() %>"><% = myenum.current.tostring() %></option><%
								end if
						end while
					catch ex as exception
					end try
				%>				
				</select></TD>
			</TR>
			<TR>
				<TD colspan=2 ><input type="submit" name="submit" value="Change Avatar" /></TD>
			</TR>
			</TABLE>
			</form>
		</fieldset>
		<fieldset>
		    <form id="form1" enctype="multipart/form-data" 
		          runat="server">
		 
		       Select Avatar Image File to Upload: 
		       <input id="upload_file" 
		              type="file"
		              runat="server"/>
		 
		       <p>
		       <span id="Span1" 
		             style="font: 8pt verdana;" 
		             runat="server" />
		 
		       </p>
		       <p>
		       <input type="button" 
		              id="Button1" 
		              value="Upload" 
		              onserverclick="Button1_Click" 
		              runat="server" />
		
		       </p>
		
		    </form>
		</fieldset>
		<br />
		<br />
		Current Avatar: 
		<ul class="hoverbox">
		<li>
		<a href="javascript:void(0)"><img src="/users/<% = myname & "/" & current_avatar %>" alt="description" ><img src="/users/<% = myname & "/" & current_avatar %>" alt="description" class="preview" ></a>
		</li>
		</ul>
		<%
			if message_text <> "" then
				%><script>window.alert("<% = message_text %>")</script><%
			end if
		%>


	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
