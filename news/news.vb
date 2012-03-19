Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.ComponentModel
Imports System.Data
Imports System.Data.SQLClient

Namespace Rasputin
	public Class FootballNews

		private myconnstring as string = System.Configuration.ConfigurationSettings.AppSettings("connString")

		Public sub MakeSystemLog (log_title as string, log_text as string)
			try
			using con as new SQLConnection(myconnstring)
				con.open()
				dim sql as string
				dim cmd as SQLCommand

				sql = "insert into fb_journal_entries (username,journal_type,entry_title,entry_text) values ('', 'FOOTBALL_NEWS', @entry_title, @entry_text)"
				
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
        End Function

        Public Function GetNewsItemsForTeam(ByVal team_name As String, ByVal start As Integer, ByVal count As Integer) As ArrayList
            Dim res As New ArrayList()
            Try
                Using con As New SqlConnection(myconnstring)
                    con.Open()
                    Dim sql As String
                    Dim cmd As SqlCommand

                    sql = "select * from (select a.*, row_number() over(order by item_tsp desc) [rowNUmber] from fb_news_items a where team_name=@team_name)q where rowNumber between @start and @end"

                    cmd = New SqlCommand(sql, con)
                    cmd.Parameters.Add(GetParm("team_name")).Value = team_name
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

        Public Function GetNewsItems(ByVal start As Integer, ByVal count As Integer) As ArrayList
            Dim res As New ArrayList()
            Try
                Using con As New SqlConnection(myconnstring)
                    con.Open()
                    Dim sql As String
                    Dim cmd As SqlCommand

                    sql = "select * from (select a.*, row_number() over(order by item_tsp desc) [rowNumber] from fb_news_items a)q where rowNumber between @start and @end"

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

        Private Function GetParm(ByVal t As String) As SqlParameter
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
End Namespace
