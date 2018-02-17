using System;
using System.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Data.SqlClient;


/// <summary>
/// Summary description for db
/// </summary>
public class MSdb
{
    public MSdb()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    static public DataTable GetData(SqlCommand cmd)
    {
        
        SqlConnection conn = new SqlConnection(DefaultConnectionString);
        cmd = NullParameters(cmd);

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

    static public object ExecuteScalar(SqlCommand cmd)
    {
        cmd = NullParameters(cmd);

        SqlConnection conn = new SqlConnection(DefaultConnectionString);
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

    static public void ExecuteNonQuery(SqlCommand cmd)
    {
        cmd = NullParameters(cmd);
        SqlConnection conn = new SqlConnection(DefaultConnectionString);
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
        return GetData(new SqlCommand(SQL));
    }

    public static SqlCommand NullParameters(SqlCommand cmd)
    {
        foreach (SqlParameter parameter in cmd.Parameters)
        {

            if (parameter.Value == null)
            {
                parameter.Value = DBNull.Value;
            }
            else if (parameter.SqlDbType == System.Data.SqlDbType.DateTime)
            {
                if (((DateTime)parameter.Value) == DateTime.MinValue)
                    parameter.Value = DBNull.Value;
            }

        }

        return cmd;
    }

    public static string DefaultConnectionString
    {
        get { return System.Configuration.ConfigurationManager.ConnectionStrings["SQLServer"].ConnectionString; }
    }
}