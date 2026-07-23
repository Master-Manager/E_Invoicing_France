codeunit 50103 "Sovos Client"
{
    Access = Internal;

    var
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        OAuthManager: Codeunit "OAuth Manager";
        HttpHelper: Codeunit "EDoc HTTP Helper";

    procedure SendInvoice(JsonBody: Text): Text
    var
        Service: Record "EDoc Service";
    begin
        SetupMgt.GetDefaultService(Service);

        exit(Post(
            Service."Invoice Endpoint",
            JsonBody,
            Service));
    end;

    procedure SendEReporting(JsonBody: Text): Text
    var
        Service: Record "EDoc Service";
    begin
        SetupMgt.GetDefaultService(Service);

        exit(Post(
            Service."E-Reporting Endpoint",
            JsonBody,
            Service));
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

    local procedure Post(
        RelativeUrl: Text;
        JsonBody: Text;
        Service: Record "EDoc Service"): Text
    var
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Headers: HttpHeaders;
        ResponseText: Text;
    begin
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
}