<%@ Page language="VB" debug="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script language="VB" runat="server">
	public function gettables() as String()
		dim cmd as sqlcommand
		dim sql as string
		dim ds as dataset
		dim da as sqldataadapter

		dim connstring as string = "server=mssql01.1and1.com; initial catalog=db108114264;uid=dbo108114264;pwd=j7aQMZbs"

		using con as new sqlconnection(connstring)
			con.open()
			sql = "select distinct name from sysobjects where name like 'fb_%' order by name"

			cmd = new sqlcommand()
			cmd.connection = con
			cmd.commandtext = sql
			ds = new dataset()
			da = new sqldataadapter()
			da.selectcommand = cmd
			da.fill(ds)
			
			if ds.tables.count > 0 then
				if ds.tables(0).rows.count > 0 then
					for each drow as datarow in ds.tables(0).rows
						processtable(drow("name"))
					next
				end if
			end if
		end using

	end function
	public function processtable(tabname as string)
		dim cmd as sqlcommand
		dim sql as string
		dim ds as dataset
		dim da as sqldataadapter

		dim connstring as string = "server=mssql01.1and1.com; initial catalog=db108114264;uid=dbo108114264;pwd=j7aQMZbs"

		using con as new sqlconnection(connstring)
			con.open()
			sql = "select a.name as tabname, b.name as colname, c.name as typename, b.length, b.isnullable, d.definition from syscolumns b left join sysobjects a on a.id=b.id left join systypes c on b.xtype=c.xtype left join sys.default_constraints d on b.cdefault=d.object_id where a.name=@tabname order by colid"
			sql ="select a.name as tabname, b.name as colname, c.name as typename, b.max_length, b.is_nullable, b.is_identity, d.definition from sys.tables a left join sys.columns b on a.object_id=b.object_id left join systypes c on b.system_type_id=c.xtype left join sys.default_constraints d on b.default_object_id=d.object_id where a.name=@tabname order by b.column_id"


			cmd = new sqlcommand()
			cmd.connection = con
			cmd.commandtext = sql
			cmd.parameters.add(new sqlparameter("@tabname",System.Data.SqlDbType.VarChar)).Value =tabname
			ds = new dataset()
			da = new sqldataadapter()
			da.selectcommand = cmd
			da.fill(ds)
			
			if ds.tables.count > 0 then
				if ds.tables(0).rows.count > 0 then
					response.write ("create table " & tabname & "(<br>")
					dim comma as string = ""
					for each drow as datarow in ds.tables(0).rows
						response.write (comma & " ")
						if drow("typename") = "varchar" or drow("typename") = "char"  then
							response.write (drow("colname") & " " & drow("typename") & " (" & drow("max_length") & ")" )
						else
							response.write (drow("colname") & " " & drow("typename"))
						end if
						if drow("is_nullable") = 0 then
							response.write (" NOT NULL ")
						end if
						if not drow("definition") is dbnull.value then
							response.write(" DEFAULT " & drow("definition"))
						end if
						if drow("is_identity") <> 0 then
							response.write (" IDENTITY ")
						end if
						comma = ","

						response.write ("<br>")
					next
					response.write(");<br><br>")

				end if

			end if




		end using

	end function
</script>

<%
	'processtable("fb_pools")
	gettables()

%>

