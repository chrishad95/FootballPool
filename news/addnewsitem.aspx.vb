Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.ComponentModel
Imports System.Data
Imports System.Data.SqlClient

Partial Class addnewsitem
    Inherits System.Web.UI.Page

    Private myconnstring As String = System.Configuration.ConfigurationSettings.AppSettings("connString")
    Private myname As String = ""

    Protected Sub Button1_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles Button1.Click
        Try
            Using con As New SqlConnection(myconnstring)
                con.Open()
                Dim sql As String
                Dim cmd As SqlCommand

                sql = "insert into fb_news_items (item_title, item_body, item_excerpt, item_author, item_source_url, team_name) values " _
                & "(@item_title, @item_body, @item_excerpt, @item_author, @item_source_url, @team_name)"


                cmd = New SqlCommand(sql, con)

                cmd.Parameters.Add(GetParm("item_title")).Value = txtTeamName.Text
                cmd.Parameters.Add(GetParm("item_body")).Value = txtBody.Text
                cmd.Parameters.Add(GetParm("item_excerpt")).Value = txtExcerpt.Text
                cmd.Parameters.Add(GetParm("item_author")).Value = myname
                cmd.Parameters.Add(GetParm("item_source_url")).Value = txtSourceURL.Text
                cmd.Parameters.Add(GetParm("team_name")).Value = txtTeamName.Text
                cmd.ExecuteNonQuery()

            End Using
        Catch ex As Exception
            Throw (ex)
        End Try
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

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Session("username") <> "" Then
            myname = Session("username")
        End If

    End Sub
End Class
