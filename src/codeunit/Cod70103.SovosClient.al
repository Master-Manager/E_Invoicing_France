codeunit 70103 "Sovos Client"
{
    Access = Internal;

    var
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        OAuthManager: Codeunit "OAuth Manager";
        HttpHelper: Codeunit "EDoc HTTP Helper";
        Base64Convert: Codeunit "Base64 Convert";
        Logger: Codeunit "EDoc Logger";

    /// <summary>
    /// Sends a complete SBD (Standard Business Document) XML to POST /v1/documents.
    /// Per Sovos's documented contract, the request body is JSON with the whole SBD XML
    /// Base64-encoded inside "data" - NOT raw XML with Content-Type: application/xml.
    /// </summary>
    /// <param name="SbdXml">The full, unencoded StandardBusinessDocument XML (SBDH + SovosDocument).</param>
    /// <param name="DocumentId">Out: the Sovos-assigned documentId from the 202 response.</param>
    /// <returns>The raw response body, for logging/troubleshooting.</returns>
    procedure SendInvoice(SbdXml: Text; var DocumentId: Text): Text
    var
        Service: Record "EDoc Service";
        ResponseText: Text;
    begin
        SetupMgt.GetDefaultService(Service);

        ResponseText := Post(Service."Invoice Endpoint", SbdXml, Service);

        DocumentId := ExtractDocumentId(ResponseText);
        exit(ResponseText);
    end;

    procedure SendEReporting(SbdXml: Text; var DocumentId: Text): Text
    var
        Service: Record "EDoc Service";
        ResponseText: Text;
    begin
        SetupMgt.GetDefaultService(Service);

        ResponseText := Post(Service."E-Reporting Endpoint", SbdXml, Service);

        DocumentId := ExtractDocumentId(ResponseText);
        exit(ResponseText);
    end;

    procedure GetStatus(RelativeUrl: Text): Text
    var
        Service: Record "EDoc Service";
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        ResponseText: Text;
    begin
        SetupMgt.GetDefaultService(Service);

        Request.Method := 'GET';
        Request.SetRequestUri(Service."Base URL" + RelativeUrl);

        Request.GetHeaders(Headers);

        Headers.Add(
            'Authorization',
            Service."Token Type" + ' ' + OAuthManager.GetAccessToken());
        Headers.Add('x-correlationId', Format(CreateGuid()));
        Headers.Add('Accept', 'application/json');

        if not HttpHelper.Execute(Request, Response) then
            Error('Unable to connect to Sovos.');

        ResponseText := HttpHelper.ReadResponse(Response);

        if not Response.IsSuccessStatusCode() then
            Error(
                'Sovos returned an error.\Status Code: %1\Response: %2',
                Response.HttpStatusCode(),
                ResponseText);

        exit(ResponseText);
    end;

    /// <summary>
    /// GET /v1/documents/{countryCode}/{documentId}/notifications - retrieves application
    /// responses/status updates for a single previously submitted document.
    /// </summary>
    procedure GetDocumentNotifications(CountryCode: Code[2]; DocumentId: Text): Text
    var
        Service: Record "EDoc Service";
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        ResponseText: Text;
        RelativeUrl: Text;
    begin
        SetupMgt.GetDefaultService(Service);

        RelativeUrl := '/v1/documents/' + CountryCode + '/' + DocumentId + '/notifications?includeAcknowledged=true&includeBinaryData=true';

        Request.Method := 'GET';
        Request.SetRequestUri(Service."Base URL" + RelativeUrl);

        Request.GetHeaders(Headers);

        Headers.Add(
            'Authorization',
            Service."Token Type" + ' ' + OAuthManager.GetAccessToken());
        Headers.Add('x-correlationId', DelChr(Format(CreateGuid()), '<>', '{}'));
        Headers.Add('Accept', 'application/json');

        if not HttpHelper.Execute(Request, Response) then
            Error('Unable to connect to Sovos.');

        ResponseText := HttpHelper.ReadResponse(Response);
        // Message(ResponseText);
        if not Response.IsSuccessStatusCode() then begin
            Logger.LogHttpExchange(
                Enum::"EDoc Log Category"::Invoice,
                1,
                RelativeUrl,
                ResponseText,
                Response.HttpStatusCode(),
                'Notification pull failed',
                'Sovos Client',
                Enum::"EDoc Log Level"::Error);

            Error(
                'Sovos returned an error.\Status Code: %1\Response: %2',
                Response.HttpStatusCode(),
                ResponseText);
        end;

        Logger.LogHttpExchange(
            Enum::"EDoc Log Category"::Invoice,
            1,
            RelativeUrl,
            ResponseText,
            Response.HttpStatusCode(),
            'Notification pull successful',
            'Sovos Client',
            Enum::"EDoc Log Level"::Information);

        exit(ResponseText);
    end;

    local procedure Post(
        RelativeUrl: Text;
        SbdXml: Text;
        Service: Record "EDoc Service"): Text
    var
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Headers: HttpHeaders;
        ResponseText: Text;
        Base64Sbd: Text;
        JsonBody: Text;
        Payload: JsonObject;
        ResponseObject: JsonObject;
    begin
        Base64Sbd := Base64Convert.ToBase64(SbdXml);

        // DownloadXml('SovosRequest.xml', SbdXml);

        Payload.Add('data', Base64Sbd);
        Payload.Add('dataEncoding', 'base64');
        Payload.WriteTo(JsonBody);

        Content.WriteFrom(JsonBody);

        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        Request.Method := 'POST';
        Request.SetRequestUri(Service."Base URL" + RelativeUrl);
        Request.Content := Content;

        Request.GetHeaders(Headers);

        Headers.Add(
            'Authorization',
            Service."Token Type" + ' ' + OAuthManager.GetAccessToken());
        Headers.Add(
    'x-correlationId',
    DelChr(Format(CreateGuid()), '<>', '{}'));
        Headers.Add('Accept', 'application/json');

        if not HttpHelper.Execute(Request, Response) then
            Error('Unable to connect to Sovos.');

        ResponseText := HttpHelper.ReadResponse(Response);
        ResponseObject.ReadFrom(ResponseText);

        // 202 (async, documentId returned) and 200 (sync) are both success statuses.
        if not Response.IsSuccessStatusCode() then begin
            Logger.LogHttpExchange(
   Enum::"EDoc Log Category"::Invoice,
   1,
   format(Payload),
   format(ResponseObject),
   Response.HttpStatusCode(),
   'Invoice Upload failed',
   'Sovos Client',
   Enum::"EDoc Log Level"::Error);

            // Error(
            //     'Sovos returned an error.\Status Code: %1\Response: %2',
            //     Response.HttpStatusCode(),
            //     ResponseText);
        end
        else
            Logger.LogHttpExchange(
        Enum::"EDoc Log Category"::Invoice,
        1,
        format(Payload),
        format(ResponseObject),
        Response.HttpStatusCode(),
        'Invoice Upload Successful',
        'Sovos Client',
        Enum::"EDoc Log Level"::Information);

        exit(ResponseText);
    end;

    /// <summary>
    /// Pulls data.documentId out of the { "data": { "documentId": "..." } } response shape
    /// documented for POST /v1/documents.
    /// </summary>
    local procedure ExtractDocumentId(ResponseText: Text): Text
    var
        JResponse: JsonObject;
        JDataToken: JsonToken;
        JIdToken: JsonToken;
    begin
        if ResponseText = '' then
            exit('');
        if not JResponse.ReadFrom(ResponseText) then
            exit('');
        if not JResponse.Get('data', JDataToken) then
            exit('');
        if not JDataToken.IsObject() then
            exit('');
        if not JDataToken.AsObject().Get('documentId', JIdToken) then
            exit('');

        exit(JIdToken.AsValue().AsText());
    end;

    local procedure DownloadXml(FileName: Text; XmlText: Text)
    var
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(XmlText);

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        DownloadFromStream(
            InStr,
            '',
            '',
            'XML (*.xml)|*.xml',
            FileName);
    end;

    var
        TempBlob: Codeunit "Temp Blob";
}
