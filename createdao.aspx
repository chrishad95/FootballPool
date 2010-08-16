<%@ Page language="VB" debug="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<script language="VB" runat="server">

	private connstring as string = System.Configuration.ConfigurationSettings.AppSettings("connString")

	public function getVBType(s as string) as string

	select case s
		case "bigint"                        
			return "Long" 
		case "binary"                        
			return "Object" 
		case "bit"                        
			return "Boolean" 
		case "char"                        
			return "String" 
		case "datetime"                        
			return "DateTime" 
		case "decimal"                        
			return "Decimal" 
		case "float"                        
			return "Double" 
		case "image"                        
			return "Byte()" 
		case "int"                        
			return "Integer" 
		case "money"                        
			return "Decimal" 
		case "nchar"                        
			return "String" 
		case "ntext"                        
			return "String" 
		case "numeric"                        
			return "Decimal" 
		case "nvarchar"                        
			return "String" 
		case "real"                        
			return "Single" 
		case "smalldatetime"                        
			return "DateTime" 
		case "smallint"                        
			return "Short" 
		case "smallmoney"                        
			return "Decimal" 
		case "text"                        
			return "String" 
		case "timestamp"                        
			return "Byte()" 
		case "tinyint"                        
			return "Byte" 
		case "uniqueidentifier"                        
			return "Guid" 
		case "varbinary"                        
			return "Byte()" 
		case "varchar"                        
			return "String" 
		case "xml"                        
			return "String" 
		case "sql_variant"                        
			return "Object" 
		case else
			return "Object"
	end select
	end function

	public function gettables() as String()
		dim cmd as sqlcommand
		dim sql as string
		dim da as sqldataadapter


		using con as new sqlconnection(connstring)
			con.open()
			sql = "select distinct name from sysobjects where name like 'fb_%' order by name"

			cmd = new sqlcommand()
			cmd.connection = con
			cmd.commandtext = sql
			dim dt as new DataTable()
			da = new sqldataadapter()
			da.selectcommand = cmd
			da.fill(dt)
			for each drow as datarow in dt.rows
				processtable(drow("name"))
			next
		end using
	end function

	public function processtable(tabname as string) as DataTable
		dim cmd as sqlcommand
		dim sql as string
		dim ds as dataset
		dim da as sqldataadapter
		dim dt as new DataTable()


		using con as new sqlconnection(connstring)
			con.open()
			sql = "select a.name as tabname, b.name as colname, c.name as typename, b.length, b.isnullable, d.definition from syscolumns b left join sysobjects a on a.id=b.id left join systypes c on b.xtype=c.xtype left join sys.default_constraints d on b.cdefault=d.object_id where a.name=@tabname order by colid"
			sql ="select a.name as tabname, b.name as colname, c.name as typename, b.max_length, b.is_nullable, b.is_identity, d.definition from sys.tables a left join sys.columns b on a.object_id=b.object_id left join systypes c on b.system_type_id=c.xtype left join sys.default_constraints d on b.default_object_id=d.object_id where a.name=@tabname order by b.column_id"


			cmd = new sqlcommand()
			cmd.connection = con
			cmd.commandtext = sql
			cmd.parameters.add(new sqlparameter("@tabname",System.Data.SqlDbType.VarChar)).Value =tabname
			dt = new DataTable()
			da = new sqldataadapter()
			da.selectcommand = cmd
			da.fill(dt)
		end using
		return dt	
	end function
</script>

<%
	'processtable("fb_pools")
	'gettables()
	dim dt as new DataTable()
	dt = processtable("fb_messages")
	%>
	<pre>
	Public Class Message
	<%
	for each drow as datarow in dt.rows
	%>
		private _<% = drow("colname") %> as <% = getVBType(drow("typename")) %> <%
	next
	for each drow as datarow in dt.rows
	%>
		public Property <% = drow("colname") %>() as <% = getVBType(drow("typename")) %>
			get
				return _<% = drow("colname") %>
			end get
			set(byval value as <% = getVBType(drow("typename")) %>)
				_<% = drow("colname") %> = value
			end set
		end property<% next %>
	<%	
	for each drow as datarow in dt.rows
	%>
		Public Function FindBy<% = drow("colname") %>(value as <% = getVBType(drow("typename")) %>) as Message
		End Function
	<% next %>

	End Class
	</pre>
	<%
'''			response.write ("create table " & tabname & "(<br>")
'''			dim comma as string = ""
'''				response.write (comma & " ")
'''				if drow("typename") = "varchar" or drow("typename") = "char"  then
'''					response.write (drow("colname") & " " & drow("typename") & " (" & drow("max_length") & ")" )
'''				else
'''					response.write (drow("colname") & " " & drow("typename"))
'''				end if
'''				if drow("is_nullable") = 0 then
'''					response.write (" NOT NULL ")
'''				end if
'''				if not drow("definition") is dbnull.value then
'''					response.write(" DEFAULT " & drow("definition"))
'''				end if
'''				if drow("is_identity") <> 0 then
'''					response.write (" IDENTITY ")
'''				end if
'''				comma = ","
'''
'''				response.write ("<br>")
'''			next
'''			response.write(");<br><br>")
%>

