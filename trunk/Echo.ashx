<%@ WebHandler Language="C#" Class="Echo" %>

using System;
using System.Web;
using System.IO;

public class Echo : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = context.Request.ContentType;
        context.Response.ContentEncoding = context.Request.ContentEncoding;

        context.Response.Write("Method:" + context.Request.HttpMethod + Environment.NewLine);
        context.Response.Write("Content Type:" + context.Request.ContentType + Environment.NewLine);
        context.Response.Write("Content Length:" + context.Request.ContentLength + Environment.NewLine);
        context.Response.Write("Content Encoding:" + context.Request.ContentEncoding.WebName + Environment.NewLine);
        if (context.Request.AcceptTypes != null)
            context.Response.Write("Accept:" + string.Join(",", context.Request.AcceptTypes)+ Environment.NewLine);

        context.Response.Write("Cookies: " + context.Request.Cookies.Count + Environment.NewLine);
        foreach (string cookieName in context.Request.Cookies)
        {
            HttpCookie cookie = context.Request.Cookies[cookieName];
            context.Response.Write("Cookie: " + cookie.Name + ", " + cookie.Expires.ToString() + ", path=" + cookie.Path + ", domain=" + (cookie.Domain??string.Empty) + Environment.NewLine);    
        }
        
        if (context.Request.HttpMethod == "POST" || context.Request.HttpMethod == "PUT")
        {
            context.Response.Write("Body:" + Environment.NewLine);
        
            const int InputBufferSize = 8 * 1024;
            int bytesRead = 0;
            byte[] buffer = new byte[InputBufferSize];
            Stream inputStream = context.Request.InputStream;
            using (Stream outStream = context.Response.OutputStream)
            {
                while ((bytesRead = inputStream.Read(buffer, 0, InputBufferSize)) > 0)
                {
                    outStream.Write(buffer, 0, bytesRead);
                }
                outStream.Flush();
                outStream.Close();
            }            
        }   
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}