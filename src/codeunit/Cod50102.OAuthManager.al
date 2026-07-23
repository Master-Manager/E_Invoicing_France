codeunit 50102 "OAuth Manager"
{
    Access = Internal;

    var
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        HttpHelper: Codeunit "EDoc HTTP Helper";
        Base64Convert: Codeunit "Base64 Convert";
        Logger: Codeunit "EDoc Logger";

    procedure GetAccessToken(): Text
    var
        Service: Record "EDoc Service";
    begin
        SetupMgt.GetDefaultService(Service);

        if TokenIsValid(Service) then
            exit(Service."Access Token");

        RequestNewToken(Service);

        exit(Service."Access Token");
    end;

    local procedure TokenIsValid(Service: Record "EDoc Service"): Boolean
    begin
        if Service."Access Token" = '' then
            exit(false);

        if Service."Token Expiration" <= CurrentDateTime() then
            exit(false);

        exit(true);
    end;

    local procedure RequestNewToken(var Service: Record "EDoc Service")
    var
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseText: Text;
        Body: Text;
        Authorization: Text;
    begin
        Body := 'grant_type=client_credentials';

        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);

        Headers.Clear();
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        Request.Method := 'POST';
        Request.SetRequestUri(Service."OAuth URL");
        Request.Content := Content;

        Request.GetHeaders(Headers);

        Authorization :=
            'Basic ' +
            Base64Convert.ToBase64(
                Service."Client ID" + ':' + Service."Client Secret");

        Headers.Add('Authorization', Authorization);

        if not HttpHelper.Execute(Request, Response) then
            Error('Unable to connect to Sovos.');

        ResponseText := HttpHelper.ReadResponse(Response);

        if not Response.IsSuccessStatusCode() then begin
            Logger.LogHttpExchange(
        Enum::"EDoc Log Category"::OAuth,
        0,
        Body,
        ResponseText,
        Response.HttpStatusCode(),
        'OAuth authentication failed.',
        'OAuth Manager');
            Error(
                'OAuth authentication failed.\Status Code: %1\Response: %2',
                Response.HttpStatusCode(),
                ResponseText);
        end;

        Logger.LogHttpExchange(
     Enum::"EDoc Log Category"::OAuth,
     0,
     Body,
     ResponseText,
     Response.HttpStatusCode(),
     'OAuth token generated successfully.',
     'OAuth Manager');

        ParseTokenResponse(ResponseText, Service);
    end;

    local procedure ParseTokenResponse(ResponseText: Text; var Service: Record "EDoc Service")
    var
        JObject: JsonObject;
        JToken: JsonToken;

        AccessToken: Text;
        TokenType: Text;
        ExpiresIn: Integer;
    begin
        JObject.ReadFrom(ResponseText);

        if not JObject.Get('access_token', JToken) then
            Error('access_token was not returned by Sovos.');

        AccessToken := JToken.AsValue().AsText();

        if JObject.Get('token_type', JToken) then
            TokenType := JToken.AsValue().AsText();

        if JObject.Get('expires_in', JToken) then
            Evaluate(ExpiresIn, JToken.AsValue().AsText());

        Service."Access Token" := AccessToken;
        Service."Token Type" := TokenType;
        Service."Token Expires In" := ExpiresIn;

        // Refresh the token 60 seconds before expiration
        Service."Token Expiration" :=
            CurrentDateTime() + ((ExpiresIn - 60) * 1000);

        Service.Modify(true);
    end;

    procedure ClearToken()
    var
        Service: Record "EDoc Service";
    begin
        SetupMgt.GetDefaultService(Service);

        Clear(Service."Access Token");
        Clear(Service."Token Type");
        Clear(Service."Token Expiration");
        Clear(Service."Token Expires In");

        Service.Modify(true);
    end;
}