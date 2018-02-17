<%@ WebHandler Language="C#" Class="login" %>

using System;
using System.Web;
using System.Data.SQLite;
using System.Data;
using System.Net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

public class login : IHttpHandler {

    public enum ErrorType { NoSSL, InvalidUserPass, InvalidEmail, InvalidCode, MissingParameters, MissingLang, InvalidKey };
    public enum ActionType { Activate, CheckCode, Login, LoginPass, Logout }


    private string email, code, key, password;
    private bool GCconnexAccess, GCcollabAccess;
    private GCTUser.Lang lang;
    private ActionType Action;

    public void ProcessRequest(HttpContext context)
    {

        context.Response.ContentType = "application/javascript";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.AppendHeader("Access-Control-Allow-Origin", "*");
        SetVars(); //### This will check for invalid/missing parameters and send an error if any are found;

        if (Action == ActionType.Activate)
        {

            SetAccess(context);

            if (!GCcollabAccess)
                SendError(ErrorType.InvalidEmail);

            GCTUser.SendUserCode(email, lang);
            SendSuccess("Code Sent");

        }
        else if (Action == ActionType.CheckCode)
        {
            string UserKey = GCTUser.ValidateUserCode(email, code);

            if (string.IsNullOrEmpty(UserKey))
            {
                SendError(ErrorType.InvalidCode);
            }
            else
            {

                SetAccess(context);
                SendSuccess(UserKey);
            }
        }
        else if (Action == ActionType.Login)
        {
            bool valid = GCTUser.IsUserValid(email, key);
            if (valid)
            {
                SetAccess(context);
                SendSuccess("Logged In");
            }
            else
            {
                SendError(ErrorType.InvalidKey);
            }
        }
        else if (Action == ActionType.LoginPass)
        {
            string prms = string.Format("user={0}&password={1}&lang{2}", email, password, lang);
            string response = "";
            using (MyWebClient wc = new MyWebClient())
            {

                wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
                response = wc.UploadString("https://gccollab.ca/services/api/rest/json/?method=login.user", prms);
                JObject jo = JObject.Parse(response);
                if (jo["result"].ToString() == "True")
                {
                    string code = GCTUser.ValidateUserCode(email, lang);
                    SetAccess(context);
                    SendSuccess(code);
                }
                else
                {
                    SendError(ErrorType.InvalidUserPass);
                }
            }
            
        }
        else if (Action == ActionType.Logout)
        {
            GCTUser.Logout(email, key);
            SendSuccess("Logged Out");
        }
    }



    private void SetVars()
    {
        if (!string.IsNullOrEmpty(HttpContext.Current.Request["email"]))
            email = HttpContext.Current.Request["email"];
        else
            SendError(ErrorType.MissingParameters);

        if (!Enum.TryParse<ActionType>(HttpContext.Current.Request["action"], true, out Action))
            SendError(ErrorType.MissingParameters); //### We could indicate action is invalid but with externally available systems it's best not to for security reasons



        if (!string.IsNullOrEmpty(HttpContext.Current.Request["code"]))
        {
            code = HttpContext.Current.Request["code"];
        }else if(Action == ActionType.CheckCode)
        {
            //### Code is required with checking the code
            SendError(ErrorType.MissingParameters);
        }

        if ((!Enum.TryParse<GCTUser.Lang>(HttpContext.Current.Request["lang"], false, out lang)) && Action == ActionType.Activate)
            SendError(ErrorType.MissingLang);

        if (Action == ActionType.LoginPass && string.IsNullOrEmpty(HttpContext.Current.Request["password"]))
            SendError(ErrorType.MissingParameters);
        else
            password = HttpContext.Current.Request["password"];

        if(Action == ActionType.Login || Action == ActionType.Logout)
        {
            if (HttpContext.Current.Request["key"] != null)
            {
                key = HttpContext.Current.Request["key"];
            }
            else
            {
                SendError(ErrorType.MissingParameters);
            }
        }

    }


    public bool IsReusable {
        get {
            return false;
        }
    }

    private void SendError(ErrorType ET)
    {
        HttpContext.Current.Response.Write("{\"status\":-1,\"message\":\"" + ET.ToString() + "\"}");
        HttpContext.Current.Response.End();
    }

    private void SendSuccess(string Message)
    {
        HttpContext.Current.Response.Write("{\"status\":1,\"message\":\"" + Message + "\",\"GCconnexAccess\":" + GCconnexAccess.ToString().ToLower() + ",\"GCcollabAccess\":" + GCcollabAccess.ToString().ToLower() + "}");
        HttpContext.Current.Response.End();
    }

    public void SetAccess(HttpContext context)
    {
        //### Don't much like these try's because what good is the api is the app servers are down.
        //### Doing this now for testing to continue dev while we correct api issues on the apps.
        //### Check for system access
        string urlGCCollab = "";
        string urlGCconnex = "";
        string apiGCcollab = "";
        string apiGCconnex = "";

        if (!string.IsNullOrEmpty(context.Request["environment"]) && context.Request["environment"].ToLower() == "dev")
        {
            urlGCCollab = Gen_Functions.URLGCCollabDev;
            urlGCconnex = Gen_Functions.URLGCConnexDev;
            apiGCcollab = Gen_Functions.APIKeyGCCollabDev;
            apiGCconnex = Gen_Functions.APIKeyGCConnexDev;
        }
        else
        {
            urlGCCollab = Gen_Functions.URLGCCollabProd;
            urlGCconnex = Gen_Functions.URLGCConnexProd;
            apiGCcollab = Gen_Functions.APIKeyGCCollabProd;
            apiGCconnex = Gen_Functions.APIKeyGCConnexProd;
        }



        string prms = string.Format("method=get.userexists&api_key={0}&user={1}", apiGCcollab, email);
        string result = "";
        try
        {
            using (MyWebClient wc = new MyWebClient())
            {
                wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
                result = wc.UploadString(urlGCCollab, prms);
                if (result.Contains("true")) //### This should be worked on more, but this works for now.
                    GCcollabAccess = true;
            }
        }
        catch (Exception e)
        {
            string t = "test";
        }

        //try
        //{

        //    prms = string.Format("method=get.userexists&api_key={0}&user={1}", apiGCconnex, email);

        //    using (MyWebClient wc = new MyWebClient())
        //    {
        //        wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
        //        result = wc.UploadString(urlGCconnex, prms);
        //        if (result.Contains("true")) //### This should be worked on more, but this works for now.
        //            GCconnexAccess = true;
        //    }
        //}
        //catch (Exception e)
        //{
        //    string t = "test";
        //}
    }
}