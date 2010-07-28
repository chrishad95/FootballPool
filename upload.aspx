<%@ Page language="VB" src="football.vb" Debug="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<script runat="server">
  function gettimestamp() as string

	Dim filetimestamp As String
	filetimestamp = ""
	filetimestamp = filetimestamp & datetime.now.year.tostring().padleft(4,"0")
	filetimestamp = filetimestamp & datetime.now.month.tostring().padleft(2,"0")
	filetimestamp = filetimestamp & datetime.now.day.tostring().padleft(2,"0")
	filetimestamp = filetimestamp & datetime.now.hour.tostring().padleft(2,"0")
	filetimestamp = filetimestamp & datetime.now.minute.tostring().padleft(2,"0")
	filetimestamp = filetimestamp & datetime.now.second.tostring().padleft(2,"0")
	return filetimestamp

  end function

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

			Span1.InnerHtml = Span1.InnerHtml & "File uploaded successfully to <b>" & _
							   savepath & "</b> on the Web server."

		  Catch exc As Exception
			
			fb.makesystemlog("Error writing upload file", exc.tostring())
			Span1.InnerHtml = Span1.InnerHtml & "Error saving file <b>" & _
							   savepath & "</b><br />" & exc.ToString() & "."
			
		  End Try
		  
		End If
	end if

    
  End Sub
 
</script>
<%
server.execute("/cookiecheck.aspx")
server.scripttimeout = 360

dim myname as string
myname = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try

If myname = "" Then
	session("page_message") = "You must login before uploading files."

	response.redirect ("/football/login.aspx?returnurl=/football/upload.aspx", true)
End If

dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

%>
<html>
<head>
	<title>Upload File - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	
</head>

<body>

	
	<div class="content">
		<h1><% = http_host %></h1>
		<h2>File Upload</h2>
		Use this page to upload files to be used elsewhere on the site.  You can upload images and documents that you can later link to in articles/comments.  You can also use files that you have uploaded here as a banner for a football pool that you've created.  You can also upload images here that you can later select to use as your avatar in the football pool trash talk area.<br /><br />
		Please use discretion when uploading files.  You should not upload sensitive/private information, or files that would break any laws, copyright or otherwise.  You should also refrain from uploading files that would be considered inappropriate.  <br />
		<br />
		<b>Use your head!</b><br />
		<br />
		If I find people abusing this, I will shut it down until I can implement an approval system!<br />
<br />
		Thanks,<br /> 
		The Management<br />
		<br />
    <form id="form1" enctype="multipart/form-data" 
          runat="server">
 
       Select Image File to Upload: 
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

	</div>

<div id="navAlpha">
<% server.execute ("/football/nav.aspx") %>
</div>

<div id="navBeta"><%
	server.execute ("/quotes/getrandomquote.aspx")
%></div>

<!-- BlueRobot was here. -->

</body>
</html>
<%

%>
