using System;
using System.Data.SQLite;
using System.Data;
using System.Web;   

/// <summary>
/// Summary description for DBSQLite
/// </summary>
public class DBSQLite
{
    public DBSQLite()
    {
        //
        // TODO: Add constructor logic here
        //
    }


    static public DataTable GetData(SQLiteCommand cmd)
    {

        SQLiteConnection conn = new SQLiteConnection(DefaultConnectionString);
        try
        {
            DataTable dt = new DataTable();
            cmd.Connection = conn;
            conn.Open();
            dt.Load(cmd.ExecuteReader());
            return dt;
        }
        finally
        {
            if (conn.State == ConnectionState.Open)
                conn.Close();
        }
    }

    static public object ExecuteScalar(SQLiteCommand cmd)
    {
        cmd = NullParameters(cmd);

        SQLiteConnection conn = new SQLiteConnection(DefaultConnectionString);
        try
        {
            cmd.Connection = conn;
            conn.Open();
            return cmd.ExecuteScalar();
        }
        finally
        {
            if (conn.State == ConnectionState.Open)
                conn.Close();
        }
    }

    static public void ExecuteNonQuery(SQLiteCommand cmd)
    {
        cmd = NullParameters(cmd);
        SQLiteConnection conn = new SQLiteConnection(DefaultConnectionString);
        try
        {
            cmd.Connection = conn;
            conn.Open();
            cmd.ExecuteNonQuery();
        }
        finally
        {
            if (conn.State == ConnectionState.Open)
                conn.Close();
        }

    }

    static public DataTable GetData(string SQL)
    {
        return GetData(new SQLiteCommand(SQL));
    }

    public static SQLiteCommand NullParameters(SQLiteCommand cmd)
    {
        foreach (SQLiteParameter parameter in cmd.Parameters)
        {

            if (parameter.Value == null)
            {
                parameter.Value = DBNull.Value;
            }
            else if (parameter.DbType == System.Data.DbType.DateTime)
            {
                if (((DateTime)parameter.Value) == DateTime.MinValue)
                    parameter.Value = DBNull.Value;
            }
            
        }

        return cmd;
    }

    public static string DefaultConnectionString
    {
        get { return "Data Source=" + HttpContext.Current.Server.MapPath("~/app_data/accounts.db") + ";Version=3;"; }
    }
}