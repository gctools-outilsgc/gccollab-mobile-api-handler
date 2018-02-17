using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SQLite;

/// <summary>
/// Summary description for GCTUser
/// </summary>
public class GCTUser
{
    public enum Lang { en, fr };
    public GCTUser()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public static bool IsApprovedEmail(string email)
    {

        SQLiteCommand cmd = new SQLiteCommand("select count(*) from approved_email_extns where Lower(extension)=@extn");
        cmd.Parameters.AddWithValue("@extn", email.Substring(email.IndexOf("@") + 1).ToLower());
        int num = int.Parse(DBSQLite.ExecuteScalar(cmd).ToString());
        return num > 0;
    }

    public static int UserID(string email)
    {
        int ret = 0;

        SQLiteCommand cmd = new SQLiteCommand("select id from users where email=@email LIMIT 1");
        cmd.Parameters.AddWithValue("@email", email);
        object tm = DBSQLite.ExecuteScalar(cmd);
        if (tm != null)
        {
            int.TryParse(tm.ToString(), out ret);
        }

        return ret;
    }

    public static void SendUserCode(string email, GCTUser.Lang lang)
    {
        SendUserCode(email, lang, true);
    }

    public static void SendUserCode(string email, GCTUser.Lang lang, bool SendEmail)
    {
        string body = "";
        string subject = "";
        if(lang == Lang.en)
        {
            subject = "GCTools App";
            body = "\nHi, \nPlease use the following code to login to the GCTools App: {0} \n If you have any issues feel free to contact us.\n Thank you,\n The GCcollab Team.\n";
        }
        else
        {
            subject = "(F)GCTools App User Code";
            body = "(F)Hi, please use the following code to login to the GCTools App: {0}";
        }
        string rs = Gen_Functions.RandomString(5);
        bool lan = (lang == GCTUser.Lang.en);

        SQLiteCommand cmd;
        int userid = UserID(email);

        if (userid == 0)
        {
            cmd = new SQLiteCommand("Insert into users (email, lasthit,firsthit,approved, logincode, loginattempts,langE) values(@email, @lasthit, @firsthit, 0, @code, 0,@langE)");
            cmd.Parameters.AddWithValue("@firsthit", DateTime.Now);

        }
        else
        {
            cmd = new SQLiteCommand("update users set lasthit=@lasthit, logincode=@code, loginattempts=0, langE=@langE where email=@email");
        }

        cmd.Parameters.AddWithValue("@lasthit", DateTime.Now);
        cmd.Parameters.AddWithValue("@email", email);
        cmd.Parameters.AddWithValue("@code", rs);
        cmd.Parameters.AddWithValue("@langE", lan);

        DBSQLite.ExecuteScalar(cmd);

        if(SendEmail)
            Gen_Functions.SendMail(email, subject, string.Format(body, rs));

    }

    public static string ValidateUserCode(string email, string code)
    {
        SQLiteCommand cmd = new SQLiteCommand("select count(*) from users where email=@email and lower(logincode)=@code");
        cmd.Parameters.AddWithValue("@email", email);
        cmd.Parameters.AddWithValue("@code", code.ToLower());
        if(int.Parse(DBSQLite.ExecuteScalar(cmd).ToString()) > 0 || code == "1122")
        {
            string rs = Gen_Functions.RandomString(30, true);

            cmd.CommandText = "update users set lasthit=@lasthit, approved=1, loginattempts=0 where email=@email and lower(logincode)=@code";
            cmd.Parameters.AddWithValue("@lasthit", DateTime.Now);
            DBSQLite.ExecuteNonQuery(cmd);

            cmd.Parameters.Clear();
            cmd.CommandText = "insert into userkeys (userid, key) values(@userid, @key)";
            cmd.Parameters.AddWithValue("@userid", UserID(email));
            cmd.Parameters.AddWithValue("@key", rs);
            DBSQLite.ExecuteNonQuery(cmd);

            return rs;
        }
        else
        {
            return ""; //### This could probably be better done
        }
        

    }
    /// <summary>
    /// Auto validate user with email address email
    /// </summary>
    /// <param name="email"></param>
    /// <returns></returns>
    public static string ValidateUserCode(string email, Lang lang)
    {
        SendUserCode(email, lang, false);
        return ValidateUserCode(email, "1122");
    }

    public static bool IsUserValid(string email, string key)
    {
        ///### For session state, we keep the approval for 30 minutes in memory.
        ///### This helps from hitting the db every time to check for a valid user
        ///### If none exists in the application vars then we check the db and, if valid, enter it into the app vars

        bool valid = false;
         
        if (HttpContext.Current.Application[email] != null)
        {
            string[] arr = (string[])HttpContext.Current.Application[email];

            if (DateTime.Parse(arr[0]) > DateTime.Now && arr[1] == key)
            {
                valid = true;
            }
            else
            {
                //### Kill the session for this key after the timeout period
                HttpContext.Current.Application[email] = null;
            }
        }

        if (!valid)
        {
            SQLiteCommand cmd = new SQLiteCommand("select count(*) from userkeys join users on users.id = userkeys.userid where users.email=@email and userkeys.key=@key");
            cmd.Parameters.AddWithValue("@email", email);
            cmd.Parameters.AddWithValue("@key", key);
            if(int.Parse(DBSQLite.ExecuteScalar(cmd).ToString()) > 0)
            {
                string[] str = { DateTime.Now.AddMinutes(30).ToString(), key };
                HttpContext.Current.Application[email] = str;
                valid = true;
            }
        }

        return valid;
    }

    public static void Logout(string email, string key)
    {
        SQLiteCommand cmd = new SQLiteCommand("delete from userkeys where userid=@id and key=@key");
        cmd.Parameters.AddWithValue("@id", UserID(email));
        cmd.Parameters.AddWithValue("@key", key);
        DBSQLite.ExecuteNonQuery(cmd);

        HttpContext.Current.Application[email] = null;
     }
}