<%@ WebHandler Language="C#" Class="SteamingProxy" %>

using System;
using System.Diagnostics;
using System.Threading;
using System.Web;
using System.Net;
using System.IO;
using System.IO.Compression;
using System.Web.Caching;
using ProxyHelpers;

public class SteamingProxy : IHttpAsyncHandler {

    const int BUFFER_SIZE = 8 * 1024;
    private const string STR_ContentEncoding = "Content-Encoding";
    private const string STR_ContentLength = "Content-Length";
    private const string STR_METHOD = "m";
    private const string STR_GET = "GET";
    private const string STR_URL = "u";
    private const string STR_CACHE_DURATION = "c";
    private const string STR_CONTENTTYPE = "t";
    private const string STR_DEFAULT_CACHE_DURATION = "0";        

    private Utility.PipeStream _PipeStream;
    private Stream _ResponseStream;

    #region Http Sync Handler ProcessRequest
    
    public void ProcessRequest(HttpContext context)
    {
        string method = context.Request[STR_METHOD] ?? STR_GET;
        string url = context.Request[STR_URL];

        if (string.IsNullOrEmpty(url))
        {
            context.Response.End();
            return;
        }

        int cacheDuration = Convert.ToInt32(context.Request[STR_CACHE_DURATION] ?? STR_DEFAULT_CACHE_DURATION);
        string contentType = context.Request[STR_CONTENTTYPE] ?? string.Empty;

        Log.WriteLine(method + " " + cacheDuration.ToString() + " " + contentType + " " + url);
        /// If cache duration specified, emit response header so that browser caches the response
        /// for specified duration.
        if (cacheDuration > 0)
        {
            if (context.Cache[url] != null)
            {
                CachedContent content = context.Cache[url] as CachedContent;

                if (!string.IsNullOrEmpty(content.ContentEncoding))
                    context.Response.AppendHeader(STR_ContentEncoding, content.ContentEncoding);
                if (!string.IsNullOrEmpty(content.ContentLength))
                    context.Response.AppendHeader(STR_ContentLength, content.ContentLength);

                context.Response.ContentType = content.ContentType;

                content.Content.Position = 0;
                content.Content.WriteTo(context.Response.OutputStream);
            }
        }

        using (new TimedLog("StreamingProxy\t" + url))
        {
            HttpWebRequest outRequest = HttpHelper.CreateScalableHttpWebRequest(url);
            // As we will stream the response, don't want to automatically decompress the content
            // when source sends compressed content
            outRequest.AutomaticDecompression = DecompressionMethods.None;

            CopyCookies(context.Request, outRequest);            
                
            if (!string.IsNullOrEmpty(contentType))
                outRequest.ContentType = contentType;

            outRequest.Method = method;

            // If there's a body provided then upload that            
            if (DoesRequestHaveBody(method))
            {
                if (context.Request.ContentLength > 0)
                    outRequest.ContentLength = context.Request.ContentLength;

                using (Stream outStream = outRequest.GetRequestStream())
                {
                    CopyRequestStream(context.Request.InputStream, outStream);
                }
            }

            using (new TimedLog("StreamingProxy\tTotal GetResponse and transmit data"))
            using (HttpWebResponse response = outRequest.GetResponse() as HttpWebResponse)
            {
                this.DownloadData(outRequest, response, context, cacheDuration);
            }
        }
    } 
    
    #endregion

    #region Http Async Handler Begin/End ProcessRequest

    public IAsyncResult BeginProcessRequest(HttpContext context, AsyncCallback cb, object extraData)
    {
        string method = context.Request[STR_METHOD] ?? STR_GET;
        string url = context.Request[STR_URL];
        int cacheDuration = Convert.ToInt32(context.Request[STR_CACHE_DURATION] ?? STR_DEFAULT_CACHE_DURATION);
        string contentType = context.Request[STR_CONTENTTYPE];

        if (string.IsNullOrEmpty(url))
        {
            context.Response.End();
            return null;
        }       

        if (cacheDuration > 0)
        {
            if (context.Cache[url] != null)
            {
                // We have response to this URL already cached
                SyncResult result = new SyncResult();
                result.Context = context;
                result.Content = context.Cache[url] as CachedContent;
                return result;
            }
        }

        HttpWebRequest outRequest = HttpHelper.CreateScalableHttpWebRequest(url);
        // As we will stream the response, don't want to automatically decompress the content
        // when source sends compressed content
        outRequest.AutomaticDecompression = DecompressionMethods.None;
        outRequest.Method = method;

        CopyCookies(context.Request, outRequest);

        if (!string.IsNullOrEmpty(contentType))
            outRequest.ContentType = contentType;

        AsyncState state = new AsyncState();
        state.Method = method;
        state.Context = context;
        state.Url = url;
        state.CacheDuration = cacheDuration;
        state.OutboundRequest = outRequest;

        // If there's a body provided then upload that            
        if (DoesRequestHaveBody(method))
        {
            if (context.Request.ContentLength > 0)
                outRequest.ContentLength = context.Request.ContentLength;

            return outRequest.BeginGetRequestStream(cb, state);
        }
        else
        {
            return outRequest.BeginGetResponse(cb, state);
        }
    }

    public void EndProcessRequest(IAsyncResult result)
    {
        if (result.CompletedSynchronously)
        {
            // Content is already available in the cache and can be delivered from cache
            SyncResult syncResult = result as SyncResult;
            syncResult.Context.Response.ContentType = syncResult.Content.ContentType;
            syncResult.Context.Response.AppendHeader(STR_ContentEncoding, syncResult.Content.ContentEncoding);
            syncResult.Context.Response.AppendHeader(STR_ContentLength, syncResult.Content.ContentLength);

            syncResult.Content.Content.Seek(0, SeekOrigin.Begin);
            syncResult.Content.Content.WriteTo(syncResult.Context.Response.OutputStream);
        }
        else
        {
            // Content is not available in cache and needs to be downloaded from external source
            AsyncState state = result.AsyncState as AsyncState;
            state.Context.Response.Buffer = false;
            HttpWebRequest outRequest = state.OutboundRequest;

            if (DoesRequestHaveBody(state.Method))
            {
                using (Stream outStream = outRequest.EndGetRequestStream(result))
                {
                    this.CopyRequestStream(state.Context.Request.InputStream, outStream);

                    using (HttpWebResponse outResponse = outRequest.GetResponse() as HttpWebResponse)
                    {
                        this.DownloadData(outRequest, outResponse, state.Context, state.CacheDuration);
                    }
                }
            }
            else
            {
                using (HttpWebResponse outResponse = outRequest.EndGetResponse(result) as HttpWebResponse)
                {
                    this.DownloadData(outRequest, outResponse, state.Context, state.CacheDuration);
                }
            }
        }
    }

    #endregion

    #region Private stuff

    public bool IsReusable {
        get {
            return false;
        }
    }

    private void CopyCookies(HttpRequest request, HttpWebRequest outRequest)
    {
        CookieContainer cookieContainer = new CookieContainer();
        outRequest.CookieContainer = cookieContainer;
        foreach (string cookieName in request.Cookies)
        {
            HttpCookie cookie = request.Cookies[cookieName];
            if (cookie.Domain == null)
                cookieContainer.Add(new Cookie(cookie.Name, cookie.Value, cookie.Path, outRequest.RequestUri.Host));
            else
                cookieContainer.Add(new Cookie(cookie.Name, cookie.Value, cookie.Path, cookie.Domain));
        }
    }
    private void DownloadData(HttpWebRequest request, HttpWebResponse response, HttpContext context, int cacheDuration)
    {
        MemoryStream responseBuffer = new MemoryStream();
        context.Response.Buffer = false;

        try
        {
            if (response.StatusCode != HttpStatusCode.OK)
            {
                context.Response.StatusCode = (int)response.StatusCode;                
                return;
            }
            using (Stream readStream = response.GetResponseStream())
            {
                if (context.Response.IsClientConnected)
                {
                    string contentLength = string.Empty;
                    string contentEncoding = string.Empty;
                    ProduceResponseHeader(response, context, cacheDuration, out contentLength, out contentEncoding);

                    //int totalBytesWritten = TransmitDataInChunks(context, readStream, responseBuffer);
                    //int totalBytesWritten = TransmitDataAsync(context, readStream, responseBuffer);
                    int totalBytesWritten = TransmitDataAsyncOptimized(context, readStream, responseBuffer);

                    Log.WriteLine("Response generated: " + DateTime.Now.ToString());
                    Log.WriteLine(string.Format("Content Length vs Bytes Written: {0} vs {1} ", contentLength, totalBytesWritten));

                    if (cacheDuration > 0)
                    {
                        #region Cache Response in memory
                        // Cache the content on server for specified duration
                        CachedContent cache = new CachedContent();
                        cache.Content = responseBuffer;
                        cache.ContentEncoding = contentEncoding;
                        cache.ContentLength = contentLength;
                        cache.ContentType = response.ContentType;

                        context.Cache.Insert(request.RequestUri.ToString(), cache, null,
                        Cache.NoAbsoluteExpiration,
                        TimeSpan.FromMinutes(cacheDuration),
                        CacheItemPriority.Normal, null);
                        #endregion
                    }                    
                }

                using (new TimedLog("StreamingProxy\tResponse Flush"))
                {
                    context.Response.Flush();                    
                }
            }
        }
        catch (Exception x)
        {
            Log.WriteLine(x.ToString());
            request.Abort();
        }
        
    }

    private int TransmitDataInChunks(HttpContext context, Stream readStream, MemoryStream responseBuffer)
    {
        byte[] buffer = new byte[BUFFER_SIZE];
        int bytesRead;
        int totalBytesWritten = 0;
        
        using( new TimedLog("StreamingProxy\tTotal read from socket and write to response") )
        while ((bytesRead = readStream.Read(buffer, 0, BUFFER_SIZE)) > 0)
        {
            using (new TimedLog("StreamingProxy\tWrite " + bytesRead + " to response"))
                context.Response.OutputStream.Write(buffer, 0, bytesRead);
            
            responseBuffer.Write(buffer, 0, bytesRead);

            totalBytesWritten += bytesRead;
        }

        return totalBytesWritten;
    }

    private int TransmitDataAsync(HttpContext context, Stream readStream, MemoryStream responseBuffer)
    {
        this._ResponseStream = readStream;

        _PipeStream = new Utility.PipeStreamBlock(5000);
        
        byte[] buffer = new byte[BUFFER_SIZE];

        Thread readerThread = new Thread(new ThreadStart(this.ReadData));
        readerThread.Start();
        //ThreadPool.QueueUserWorkItem(new WaitCallback(this.ReadData));

        int totalBytesWritten = 0;
        int dataReceived;

        using (new TimedLog("StreamingProxy\tTotal read and write"))
        {
            while ((dataReceived = this._PipeStream.Read(buffer, 0, BUFFER_SIZE)) > 0)
            {
                using (new TimedLog("StreamingProxy\tWrite " + dataReceived + " to response"))
                {
                    context.Response.OutputStream.Write(buffer, 0, dataReceived);
                    responseBuffer.Write(buffer, 0, dataReceived);
                    totalBytesWritten += dataReceived;
                }
            }
        }

        _PipeStream.Dispose();
        
        return totalBytesWritten;
        
    }

    private int TransmitDataAsyncOptimized(HttpContext context, Stream readStream, MemoryStream responseBuffer)
    {
        this._ResponseStream = readStream;

        _PipeStream = new Utility.PipeStreamBlock(10000);
        //_PipeStream = new Utility.PipeStream(10000);
        
        byte[] buffer = new byte[BUFFER_SIZE];

        // Asynchronously read content form response stream
        Thread readerThread = new Thread(new ThreadStart(this.ReadData));
        readerThread.Start();
        //ThreadPool.QueueUserWorkItem(new WaitCallback(this.ReadData));

        // Write to response 
        int totalBytesWritten = 0;
        int dataReceived;

        byte[] outputBuffer = new byte[BUFFER_SIZE];
        int responseBufferPos = 0;
        
        using (new TimedLog("StreamingProxy\tTotal read and write"))
        {
            while ((dataReceived = this._PipeStream.Read(buffer, 0, BUFFER_SIZE)) > 0)
            {
                // if about to overflow, transmit the response buffer and restart
                int bufferSpaceLeft = BUFFER_SIZE - responseBufferPos;

                if (bufferSpaceLeft < dataReceived)
                {
                    Buffer.BlockCopy(buffer, 0, outputBuffer, responseBufferPos, bufferSpaceLeft);

                    using (new TimedLog("StreamingProxy\tWrite " + BUFFER_SIZE + " to response"))
                    {
                        context.Response.OutputStream.Write(outputBuffer, 0, BUFFER_SIZE);
                        responseBuffer.Write(outputBuffer, 0, BUFFER_SIZE);
                        totalBytesWritten += BUFFER_SIZE;
                    }

                    // Initialize response buffer and copy the bytes that were not sent
                    responseBufferPos = 0;
                    int bytesLeftOver = dataReceived - bufferSpaceLeft;
                    Buffer.BlockCopy(buffer, bufferSpaceLeft, outputBuffer, 0, bytesLeftOver);
                    responseBufferPos = bytesLeftOver;
                }
                else
                {
                    Buffer.BlockCopy(buffer, 0, outputBuffer, responseBufferPos, dataReceived);
                    responseBufferPos += dataReceived;
                }                    
            }

            // If some data left in the response buffer, send it
            if (responseBufferPos > 0)
            {
                using (new TimedLog("StreamingProxy\tWrite " + responseBufferPos + " to response"))
                {
                    context.Response.OutputStream.Write(outputBuffer, 0, responseBufferPos);
                    responseBuffer.Write(outputBuffer, 0, responseBufferPos);
                    totalBytesWritten += responseBufferPos;
                }
            }
        }

        Log.WriteLine("StreamingProxy\tSocket read " + this._PipeStream.TotalWrite + " bytes and response written " + totalBytesWritten + " bytes");
        
        _PipeStream.Dispose();
        
        return totalBytesWritten;
        
    }

    private void ProduceResponseHeader(HttpWebResponse response, HttpContext context, int cacheDuration, out string contentLength, out string contentEncoding)
    {
        // produce cache headers for response caching
        if (cacheDuration > 0)
            HttpHelper.CacheResponse(context, cacheDuration);
        else
            HttpHelper.DoNotCacheResponse(context);

        // If content length is not specified, this the response will be sent as Transfer-Encoding: chunked
        contentLength = response.GetResponseHeader(STR_ContentLength);        
        if (!string.IsNullOrEmpty(contentLength)) 
                context.Response.AppendHeader(STR_ContentLength, contentLength);

        // If downloaded data is compressed, Content-Encoding will have either gzip or deflate
        contentEncoding = response.GetResponseHeader(STR_ContentEncoding);
        if (!string.IsNullOrEmpty(contentEncoding))
            context.Response.AppendHeader(STR_ContentEncoding, contentEncoding);

        context.Response.ContentType = response.ContentType;
    }

    private void ReadData()
    {
        byte[] buffer = new byte[BUFFER_SIZE];
        int dataReceived;
        int totalBytesFromSocket = 0;
    
        using (new TimedLog("StreamingProxy\tTotal Read from socket"))
        {
            try
            {
                while ((dataReceived = this._ResponseStream.Read(buffer, 0, BUFFER_SIZE)) > 0)
                {
                    this._PipeStream.Write(buffer, 0, dataReceived);
                    totalBytesFromSocket += dataReceived;
                }
            }
            catch (Exception x)
            {
                Log.WriteLine(x.ToString());
            }
            finally
            {
                Log.WriteLine("Total bytes read from socket " + totalBytesFromSocket + " bytes");
                this._ResponseStream.Dispose();
                this._PipeStream.Flush();                
            }
        }
    }

    private bool DoesRequestHaveBody(string method)
    {
        return (method == "POST" || method == "PUT");
    }

    private void CopyRequestStream(Stream inputStream, Stream outStream)
    {
        const int InputBufferSize = 8 * 1024;
        int bytesRead = 0;
        byte[] buffer = new byte[InputBufferSize];
        while ((bytesRead = inputStream.Read(buffer, 0, InputBufferSize)) > 0)
        {
            outStream.Write(buffer, 0, bytesRead);
        }
        outStream.Flush();
        outStream.Close();
    }

    #endregion

}