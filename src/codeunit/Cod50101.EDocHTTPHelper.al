codeunit 50101 "EDoc HTTP Helper"
{
    Access = Internal;

    procedure Execute(var Request: HttpRequestMessage; var Response: HttpResponseMessage): Boolean
    var
        Client: HttpClient;
    begin
        exit(Client.Send(Request, Response));
    end;

    procedure ReadResponse(var Response: HttpResponseMessage): Text
    var
        ResponseText: Text;
    begin
        if Response.Content.ReadAs(ResponseText) then;

        exit(ResponseText);
    end;
}