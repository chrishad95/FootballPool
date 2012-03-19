Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.ComponentModel
Imports System.Data
Imports System.Data.SqlClient

Partial Class news_add_news_feed
    Inherits System.Web.UI.Page


    Private myconnstring As String = System.Configuration.ConfigurationSettings.AppSettings("connString")

    Protected Sub Button1_Click(sender As Object, e As System.EventArgs) Handles Button1.Click
        Try
            Using con As New SqlConnection(myconnstring)
                con.Open()
                Dim sql As String
                Dim cmd As SqlCommand

                sql = "insert into fb_rss_feeds (feed_title, feed_url) values " _
                & "(@feed_title, @feed_url)"


                cmd = New SqlCommand(sql, con)

                cmd.Parameters.Add(GetParm("feed_title")).Value = txtTitle.Text
                cmd.Parameters.Add(GetParm("feed_url")).Value = txtURL.Text
                cmd.ExecuteNonQuery()

            End Using
        Catch ex As Exception
            Throw (ex)
        End Try
        Response.Redirect("/football/news/")
    End Sub
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
