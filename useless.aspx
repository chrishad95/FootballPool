<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ import namespace="system.drawing" %>
<%@ import namespace="system.drawing.imaging" %>
<%@ import namespace="system.drawing.drawing2d" %>
<script runat="server" language="VB">
	private myname as string = ""
    Private Sub mnuFileSave_Click(greatgraph as Rasputin.GreatGraph) 
    End Sub
	
</script>
<%

server.execute("/cookiecheck.aspx")
dim fb as new Rasputin.FootballUtility()
dim ggr as new Rasputin.GreatGraph()

dim myname as string = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
	
dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

dim pool_id as integer
try
	if request("pool_id") <> "" then
		pool_id = request("pool_id")
	end if
catch 
end try

dim isowner as boolean = false
if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
	isowner = true
end if
if myname = "" then
	response.redirect("login.aspx?returnurl=showpicks.aspx?pool_id=" & pool_id, true)
end if
if fb.isplayer(pool_id:=pool_id, player_name:=myname) or isowner then
else	
	session("page_message") = "Invalid pool/player."
	response.redirect("/football/error.aspx", true)
end if

dim pool_details_ds as new dataset()
pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

dim banner_image as string = ""
if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
	banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" &  pool_details_ds.tables(0).rows(0)("pool_banner")
end if

dim pool_name as string = ""
pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

dim options_ht as new system.collections.hashtable()
options_ht = fb.getPoolOptions(pool_id:=pool_id)

dim weekly_stats as new dataset()
weekly_stats = fb.GetWeeklyStats(pool_id:=pool_id)

dim graph_request as string = ""
try
	if request("graph") <> "" then
		graph_request = request("graph")
	end if
catch
end try
dim player as string = myname
try
	if request("player") <> "" then
		player = request("player")
	end if
catch
end try

dim error_message as string = ""
if graph_request = "win_pct" then
	try
	
			dim win_pct_points as PointF()
			dim high_point as double = 0.0
			dim low_point as double = 1000.0

			dim nick as string = myname
			dim temprows as datarow()
			temprows = weekly_stats.tables(0).select("username='" & player & "'")
			if temprows.length > 0 then
				if not temprows(0)("nickname") is dbnull.value then
					nick = temprows(0)("nickname")
				end if

				for i as integer = 0  to temprows.length -1
					if (temprows(i)("win_pct") * 100) > high_point then
						high_point = (temprows(i)("win_pct") * 100)
					end if

					if (temprows(i)("win_pct") * 100) < low_point then
						low_point = (temprows(i)("win_pct") * 100)
					end if
				next
			end if
			high_point = math.ceiling(high_point + 5) - (math.ceiling(high_point + 5) mod 5)  
			low_point = math.floor(low_point) - (math.floor(low_point) mod 5)

			if temprows.length > 0 then
				redim win_pct_points(temprows.length -1)
				for i as integer = 0  to temprows.length -1
					win_pct_points(i) = new PointF(i + 1, (temprows(i)("win_pct") * 100) - low_point )
				next
			end if
	        '' Set the world coordinate bounds.
	        ' Set the world coordinate bounds.
	        ggr.Wxmin = -2
	        ggr.Wxmax = temprows.length + 2
	        ggr.Wymin = -2
	        ggr.Wymax = high_point - low_point + 1 
	
			' Make the X axis.
	        Dim x_axis As Rasputin.DataSeries = Rasputin.DataSeries.MakeAxis(1, 0, temprows.length, 0, 0)
	        With x_axis
	            .LinePen = New Pen(Color.DarkGray, 0)
	            .LabelBrush = Brushes.DarkGray
	            .LabelFont = New Font("Arial", 1, FontStyle.Regular, GraphicsUnit.World)
	            .TickPen = .LinePen
	            '.Labels = New String() {"J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"}
	        End With
	        ggr.AddDataSeries(x_axis)
			dim ylabels as string()
			redim ylabels((high_point - low_point) / 5 )
			for i as integer = 0 to (high_point - low_point) / 5
				ylabels(i) = "" & ((i * 5) + low_point)
			next
	        ' Make the Y axis.
	        Dim y_axis As Rasputin.DataSeries = Rasputin.DataSeries.MakeAxis(5, 0, 0, low_point - low_point ,high_point - low_point)
	        With y_axis
	            .LinePen = New Pen(Color.DarkGray, 0)
	            .LabelBrush = Brushes.DarkGray
	            .LabelFont = New Font("Arial", 1, FontStyle.Regular, GraphicsUnit.World)
	            '.Labels = New String() {"0", "100", "200", "300", "400", "500", "600", "700", "800", "900", "1000"}
				.Labels = ylabels
	            .TickPen = .LinePen
	        End With
	        ggr.AddDataSeries(y_axis)
	
	
	        ' Make a bar data series.
	        Dim bar_data1 As New Rasputin.DataSeries
	        With bar_data1
	
	            .Name = "Weekly Win Percentages"
	            .ShowDataTips = True
	            .HitDx = 0.5
	            .HitDy = 0.25
	            .Points = win_pct_points
	            .BarPen = New Pen(Color.Green, 0)
	            .BarBrush = New SolidBrush(Color.FromArgb(128, 0, 0, 255)) ' Translucent blue.
	            '.BarBrush = New SolidBrush(Color.Black) ' black
				''.BarWidthModifier = .33
	
	        End With
	
	        ggr.AddDataSeries(bar_data1)
	
	
	        ' Make the Bitmap.
	        Const BM_WID As Integer = 200
	        Const BM_HGT As Integer = 500
	        Using bm As New Bitmap(BM_WID, BM_HGT)
	            ' Make the control draw on the Bitmap.
	            Using gr As Graphics = Graphics.FromImage(bm)
	                gr.Clear(Color.White)
	
	                ggr.DrawToGraphics( _
	                    gr, 0, BM_WID - 1, 0, BM_HGT - 1)
	            End Using
	
	            '' Save the Bitmap.
	            ''bm.Save(file_name, Imaging.ImageFormat.Jpeg)
	
	
			dim mimetype as string
			mimeType = "image/gif"
			dim j as integer
			dim encoders
			dim codecinfo as imagecodecinfo
			
			encoders = ImageCodecInfo.GetImageEncoders()
			for j = 0 to encoders.Length -1 
				if encoders(j).mimetype = mimetype then
					codecinfo = encoders(j)
				end if
				
			next j
	
			' Set the quality to 100 (must be a long)
			dim qualityEncoder as System.Drawing.Imaging.encoder
			qualityEncoder = System.Drawing.Imaging.Encoder.Quality
			
			dim ratio as encoderparameter 
			ratio = new EncoderParameter(qualityEncoder, 100L)
			
			' Add the quality parameter to the list
			dim codecparams
			
			codecParams = new EncoderParameters(1)
			codecParams.Param(0) = ratio
			' set the content type
	
			response.contenttype="image/gif"
			Response.AppendHeader("Content-Disposition", "filename=graphtest.gif")
			bm.Save(response.outputstream, codecinfo, codecParams )
	
	        End Using
	
	
	catch ex as exception
		error_message = ex.tostring()
		error_message = error_message & ex.stacktrace
	end try
end if
if graph_request = "win_vs_avg_vs_high" then
	try
	
	        Dim rnd As New Random()
			dim weekly_points as PointF()
			
			dim nick as string = myname
			dim temprows as datarow()
			temprows = weekly_stats.tables(0).select("username='" & player & "'")
			if temprows.length > 0 then
				redim weekly_points(temprows.length -1)
				if not temprows(0)("nickname") is dbnull.value then
					nick = temprows(0)("nickname")
				end if
				dim debugmessage as string = ""
				for i as integer = 0  to temprows.length -1
					weekly_points(i) = new PointF(i + 1, temprows(i)("wins"))
					debugmessage &= "Week: " & i & "=" & temprows(i)("wins") & "<br />"
				next
				fb.makesystemlog("debug", debugmessage)
			end if
	
			dim players_ds as new dataset()
			players_ds = fb.getplayers(pool_id)
			dim weeks_ds as new dataset()
			weeks_ds = fb.listweeks(pool_id)
			dim week_high_points as PointF()
			dim week_avg_points as PointF()
			redim week_high_points(temprows.length -1)
			redim week_avg_points(temprows.length -1)
			dim week_ctr as integer = 0
			dim last_week as integer = 0
			dim lowest_score as integer = 5000
			dim highest_score as integer = 0
	
			for each week_id_row as datarow in weeks_ds.tables(0).rows
				dim high_score as integer = 0
				temprows = weekly_stats.tables(0).select("week_id=" & week_id_row("week_id"))
				if temprows.length > 0 then
					if week_id_row("week_id") > last_week then
						last_week = week_id_row("week_id")
					end if
					dim score_counter as integer = 0
					dim score_total as integer = 0
	
					for each drow as datarow in temprows
						score_counter = score_counter + 1
						score_total = score_total + drow("wins")
	
						if drow("wins") > high_score then
							high_score = drow("wins")
						end if
						if drow("wins") > highest_score then
							highest_score = drow("wins")
						end if
						if drow("wins") < lowest_score then
							lowest_score = drow("wins")
						end if
					next
					week_avg_points(week_ctr) = new PointF(week_ctr + .8, score_total / score_counter)
					week_high_points(week_ctr) = new PointF(week_ctr + 1.2, high_score)
					week_ctr = week_ctr + 1
				end if
			next
	
	'		' Make a line data series.
	'        Dim line_avgscore_data As Rasputin.DataSeries = ggr.AddDataSeries()
	'        With line_avgscore_data
	'			.Points = week_avg_points
	'            .Name = "High Scores"
	'            .ShowDataTips = True
	'            .LinePen = New Pen(Color.Blue, 0.05)
	'            '.LinePen.DashStyle = Drawing2D.DashStyle.Dash
	'
	'            ' Debugging.
	'            '.AllowUserChangeX = True
	'            '.TickPen = New Pen(Color.Green, 0.1)
	'            '.PointPen = New Pen(Color.Red, 0)
	'            '.PointBrush = Brushes.Lime
	'            '.PointWidth = 0.2
	'            'ReDim .Labels(.Points.Length - 1)
	'            'For i As Integer = 0 To .Points.Length - 1
	'            '    .Labels(i) = i
	'            'Next i
	'            '.LabelBrush = Brushes.Red
	'            '.LabelFont = New Font("Arial", 0.75, FontStyle.Regular, GraphicsUnit.World)
	'        End With
	'
	'		' Make a line data series.
	'        Dim line_highscore_data As Rasputin.DataSeries = ggr.AddDataSeries()
	'        With line_highscore_data
	'			.Points = week_high_points
	'            .Name = "High Scores"
	'            .ShowDataTips = True
	'            .LinePen = New Pen(Color.Red, 0.05)
	'            '.LinePen.DashStyle = Drawing2D.DashStyle.Dash
	'
	'            ' Debugging.
	'            '.AllowUserChangeX = True
	'            '.TickPen = New Pen(Color.Red, 0.05)
	'            '.PointPen = New Pen(Color.Red, 0)
	'            '.PointBrush = Brushes.Lime
	'            '.PointWidth = 0.2
	'            'ReDim .Labels(.Points.Length - 1)
	'            'For i As Integer = 0 To .Points.Length - 1
	'            '    .Labels(i) = i
	'            'Next i
	'            '.LabelBrush = Brushes.Red
	'            '.LabelFont = New Font("Arial", 0.75, FontStyle.Regular, GraphicsUnit.World)
	'        End With
	'
	'		' Make a line data series.
	'        Dim line_data As Rasputin.DataSeries = ggr.AddDataSeries()
	'        With line_data
	'			.Points = weekly_points
	'            .Name = "Line Data"
	'            .ShowDataTips = True
	'            .LinePen = New Pen(Color.Black, 0.1)
	'            '.LinePen.DashStyle = Drawing2D.DashStyle.Dash
	'
	'            ' Debugging.
	'            '.AllowUserChangeX = True
	'            '.TickPen = New Pen(Color.Green, 0.1)
	'            '.PointPen = New Pen(Color.Red, 0)
	'            '.PointBrush = Brushes.Lime
	'            '.PointWidth = 0.2
	'            'ReDim .Labels(.Points.Length - 1)
	'            'For i As Integer = 0 To .Points.Length - 1
	'            '    .Labels(i) = i
	'            'Next i
	'            '.LabelBrush = Brushes.Red
	'            '.LabelFont = New Font("Arial", 0.75, FontStyle.Regular, GraphicsUnit.World)
	'        End With
	
	        '' Set the world coordinate bounds.
	        ' Set the world coordinate bounds.
	        ggr.Wxmin = -2
	        ggr.Wxmax = last_week + 2
	        ggr.Wymin = -2
	        ggr.Wymax = highest_score + 1 
	
			' Make the X axis.
	        Dim x_axis As Rasputin.DataSeries = Rasputin.DataSeries.MakeAxis(1, 0, last_week, 0, 0)
	        With x_axis
	            .LinePen = New Pen(Color.DarkGray, 0)
	            .LabelBrush = Brushes.DarkGray
	            .LabelFont = New Font("Arial", .5, FontStyle.Regular, GraphicsUnit.World)
	            .TickPen = .LinePen
	            '.Labels = New String() {"J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"}
	        End With
	        ggr.AddDataSeries(x_axis)
	
	        ' Make the Y axis.
	        Dim y_axis As Rasputin.DataSeries = Rasputin.DataSeries.MakeAxis(1, 0, 0, lowest_score, highest_score)
	        With y_axis
	            .LinePen = New Pen(Color.DarkGray, 0)
	            .LabelBrush = Brushes.DarkGray
	            .LabelFont = New Font("Arial", 0.5, FontStyle.Regular, GraphicsUnit.World)
	            '.Labels = New String() {"0", "100", "200", "300", "400", "500", "600", "700", "800", "900", "1000"}
	            .TickPen = .LinePen
	        End With
	        ggr.AddDataSeries(y_axis)
	
	'        ggr.AddDataSeries(line_data)
	'        ggr.AddDataSeries(line_highscore_data)
	'        ggr.AddDataSeries(line_avgscore_data)
	
	
	        ' Make a bar data series.
	        Dim bar_data1 As New Rasputin.DataSeries
	        With bar_data1
	
	            .Name = "Weekly Score"
	            .ShowDataTips = True
	            .HitDx = 0.5
	            .HitDy = 0.25
	            .Points = weekly_points
	            .BarPen = New Pen(Color.Green, 0)
	            .BarBrush = New SolidBrush(Color.FromArgb(128, 0, 255, 0)) ' Translucent green.
	            .BarBrush = New SolidBrush(Color.Black) ' black
				.BarWidthModifier = .33
	
	        End With
	
	        ' Make a bar data series.
	        Dim bar_data2 As New Rasputin.DataSeries
	        With bar_data2
	            .Name = "2006 Sales"
	            .ShowDataTips = True
	            .HitDx = 0.5
	            .HitDy = 0.25
	            .Points = week_high_points
	            .BarPen = New Pen(Color.Green, 0)
	            .BarBrush = New SolidBrush(Color.FromArgb(128, 255, 0, 0)) ' Translucent red.
	            '.BarBrush = New SolidBrush(Color.Red) 
				.BarWidthModifier = .33
	        End With
	
	        ' Make a bar data series.
	        Dim bar_data3 As New Rasputin.DataSeries
	        With bar_data3
	            .Name = "2007 Sales"
	            .ShowDataTips = True
	            .HitDx = 0.5
	            .HitDy = 0.25
	            .Points = week_avg_points
	            .BarPen = New Pen(Color.Green, 0)
	            .BarBrush = New SolidBrush(Color.FromArgb(128, 0, 0, 255)) ' Translucent blue.
	            '.BarBrush = New SolidBrush(Color.Blue) 
				.BarWidthModifier = .33
	        End With
	
	        ggr.AddDataSeries(bar_data3)
	        ggr.AddDataSeries(bar_data2)
	        ggr.AddDataSeries(bar_data1)
	
	
	        ' Make the Bitmap.
	        Const BM_WID As Integer = 500
	        Const BM_HGT As Integer = 500
	        Using bm As New Bitmap(BM_WID, BM_HGT)
	            ' Make the control draw on the Bitmap.
	            Using gr As Graphics = Graphics.FromImage(bm)
	                gr.Clear(Color.White)
	
	                ggr.DrawToGraphics( _
	                    gr, 0, BM_WID - 1, 0, BM_HGT - 1)
	            End Using
	
	            '' Save the Bitmap.
	            ''bm.Save(file_name, Imaging.ImageFormat.Jpeg)
	
	
			dim mimetype as string
			mimeType = "image/gif"
			dim j as integer
			dim encoders
			dim codecinfo as imagecodecinfo
			
			encoders = ImageCodecInfo.GetImageEncoders()
			for j = 0 to encoders.Length -1 
				if encoders(j).mimetype = mimetype then
					codecinfo = encoders(j)
				end if
				
			next j
	
			' Set the quality to 100 (must be a long)
			dim qualityEncoder as System.Drawing.Imaging.encoder
			qualityEncoder = System.Drawing.Imaging.Encoder.Quality
			
			dim ratio as encoderparameter 
			ratio = new EncoderParameter(qualityEncoder, 100L)
			
			' Add the quality parameter to the list
			dim codecparams
			
			codecParams = new EncoderParameters(1)
			codecParams.Param(0) = ratio
			' set the content type
	
			response.contenttype="image/gif"
			Response.AppendHeader("Content-Disposition", "filename=graphtest.gif")
			bm.Save(response.outputstream, codecinfo, codecParams )
	
	        End Using
	
	
	catch ex as exception
		error_message = ex.tostring()
	end try
end if
if error_message <> "" then
%>
<html>
<head>
	<title>Statistics - <% = pool_name %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/style4.css";</style>
	<style type="text/css">
		.content {
			border: none;
			padding: 1px;
			margin:0px 0px 20px 170px;
		}
		.week_column {
			width: 100px;
		}
	</style>
</head>

<body>

	<div class="content">
	<%
	if error_message <> "" then
		response.write(fb.bbencode(error_message))
	end if
	%>
	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>

<!-- BlueRobot was here. -->
</body>
</html>
<%
end if
%>
