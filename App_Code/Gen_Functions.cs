using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mail;
using System.IO;
using System.Net;

/// <summary>
/// Summary description for Gen_Functions
/// </summary>
public class Gen_Functions
{
    public Gen_Functions()
    {
        //
        // TODO: Add constructor logic here
        //
    }

    public static string RandomString(int len, bool UpperAndLowerCase)
    {
        var chars = "";
        if (UpperAndLowerCase)
        {
            chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        }
        else
        {
            chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        }
        var stringChars = new char[len];
        var random = new Random();

        for (int i = 0; i < stringChars.Length; i++)
        {
            stringChars[i] = chars[random.Next(chars.Length)];
        }

        return new String(stringChars);
    }

    public static string RandomString(int len)
    {
        return RandomString(len, false);
    }

    public static void SendMail(string to, string subject, string body)
    {

        //### Using deprecated function because system.net.mail did not work

        MailMessage mm = new MailMessage();
        mm.From = System.Configuration.ConfigurationManager.AppSettings["emailfrom"];
        mm.To = to;
        mm.Subject = subject;
        mm.Body = body;

        mm.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserverport", 465);
        mm.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusing", 2);
        mm.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1);
        mm.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusername", System.Configuration.ConfigurationManager.AppSettings["emailusername"]);
        mm.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendpassword", System.Configuration.ConfigurationManager.AppSettings["emailpassword"]);
        mm.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpusessl", true);


        SmtpMail.SmtpServer = System.Configuration.ConfigurationManager.AppSettings["emailsmtp"];
        SmtpMail.Send(mm);

    }

    public static string APIKeyGCCollabProd
    {
        get {
            return System.Configuration.ConfigurationManager.AppSettings["gccollabProdAPIKey"];
        }
    }

    public static string APIKeyGCCollabDev
    {
        get
        {
            return System.Configuration.ConfigurationManager.AppSettings["gccollabDevAPIKey"];
        }
    }

    public static string APIKeyGCConnexProd
    {
        get
        {
            return System.Configuration.ConfigurationManager.AppSettings["gcconnexProdAPIKey"];
        }
    }

    public static string APIKeyGCConnexDev
    {
        get
        {
            return System.Configuration.ConfigurationManager.AppSettings["gcconnexDevAPIKey"];
        }
    }

    public static string URLGCCollabProd
    {
        get
        {
            return System.Configuration.ConfigurationManager.AppSettings["gccollabProdUrl"];
        }
    }

    public static string URLGCCollabDev
    {
        get
        {
            return System.Configuration.ConfigurationManager.AppSettings["gccollabDevUrl"];
        }
    }

    public static string URLGCConnexProd
    {
        get
        {
            return System.Configuration.ConfigurationManager.AppSettings["gcconnexProdUrl"];
        }
    }

    public static string URLGCConnexDev
    {
        get
        {
            return System.Configuration.ConfigurationManager.AppSettings["gcconnexDevUrl"];
        }
    }


    /// <summary>
    /// Gets the appropriate api key based on the request.
    /// Valid paramaters are in form or qstring are:
    /// context: gcconnex|gccollab
    /// environment: dev|prod
    /// </summary>
    /// <param name="context">current http context</param>
    /// <returns>Appropriate API key. Defaults to gccollab prod</returns>
    public static string GetAppropriateAPIKey(HttpContext context)
    {
        if (!string.IsNullOrEmpty(context.Request["context"]) && context.Request["context"].ToLower() == "gcconnex")
        {
            if(!string.IsNullOrEmpty(context.Request["environment"]) && context.Request["environment"].ToLower() == "dev")
            {
                return APIKeyGCConnexDev;
            }else
            {
                return APIKeyGCConnexProd;
            }
        }
        else
        {
            if (!string.IsNullOrEmpty(context.Request["environment"]) && context.Request["environment"].ToLower() == "dev")
            {
                return  APIKeyGCCollabDev;
            }
            else
            {
                return APIKeyGCCollabProd;
            }
        }
        
    }

    /// <summary>
    /// Gets the appropriate api url based on the request.
    /// Valid paramaters are in form or qstring are:
    /// context: gcconnex|gccollab
    /// environment: dev|prod
    /// </summary>
    /// <param name="context">current http context</param>
    /// <returns>Appropriate API url with trailing slash e.g. https://gccollab.ca/services/api/rest/json/ Defaults to gccollab prod</returns>
    public static string GetAppropriateAPIURL(HttpContext context)
    {
        if (!string.IsNullOrEmpty(context.Request["context"]) && context.Request["context"].ToLower() == "gcconnex")
        {
            if (!string.IsNullOrEmpty(context.Request["environment"]) && context.Request["environment"].ToLower() == "dev")
            {
                return URLGCConnexDev;
            }
            else
            {
                return URLGCConnexProd;
            }
        }
        else
        {
            if (!string.IsNullOrEmpty(context.Request["environment"]) && context.Request["environment"].ToLower() == "dev")
            {
                return URLGCCollabDev;
            }
            else
            {
                return URLGCCollabProd;
            }
        }

    }


    public static string GetImageURL(string ImageURL)
    {
        // This will need a major overhaul. Just doing this for now.

        if (ImageURL.ToLower().Contains("gcconnex"))
        {
            if (ImageURL.ToLower().Contains("defaultmedium.gif") || ImageURL.ToLower().Contains("medium.png"))
                return "https://api.gctools.ca/images/gcconnex/defaultmedium.gif";

            string LastCache = ImageURL.Substring(ImageURL.IndexOf("cache=") + 7);
            string GUID = LastCache.Substring(LastCache.IndexOf("guid=") + 5);
            GUID = GUID.Substring(0, GUID.IndexOf("&"));
            LastCache = LastCache.Substring(0, LastCache.IndexOf("&")); //### LOL

            string FileName = GUID + LastCache + ".jpg";
            string FileURL = "https://api.gctools.ca/images/gcconnex/" + FileName;
            string Path = HttpContext.Current.Server.MapPath("~/images/gcconnex/");
            string FileLocation = Path + FileName;

            if (!File.Exists(FileLocation))
            {
                using (WebClient webClient = new WebClient())
                {
                    webClient.DownloadFile(ImageURL, FileLocation);
                }
            }



            return FileURL;


               
            //### Check for local version of the file


        }
        else
        {
            return ImageURL;
        }
    }

}
