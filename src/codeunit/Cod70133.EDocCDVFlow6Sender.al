codeunit 70133 "EDoc CDV Flow6 Sender"
{
    // Two entry points:
    //   - Enqueue(...)      : call this from the event subscriber (fast, transactional, no HTTP).
    //   - ProcessQueue()     : call this from a Job Queue Entry (Codeunit ID = this codeunit,
    //                          e.g. every 5 minutes) - does the actual HTTP send, outside of
    //                          any posting transaction.
    //
    // TODO: swap the actual HTTP call in TrySendOne() for your existing Flux 2 transport logic
    // if one already exists (correct headers/cert handling for your specific PDP/PPF may differ
    // from the generic Bearer-token pattern assumed below).

    /// <summary>
    /// Fast, transaction-safe: stores the XML for later sending. Call this from the event
    /// subscriber instead of sending HTTP directly.
    /// </summary>
    procedure Enqueue(InvoiceNo: Code[35]; Xml: Text)
    var
        QueueEntry: Record "EDoc CDV Outbound Queue";
    begin
        QueueEntry.Init();
        QueueEntry."Invoice No." := InvoiceNo;
        QueueEntry."Created DateTime" := CurrentDateTime;
        QueueEntry.Status := QueueEntry.Status::Pending;
        QueueEntry.Insert(true);
        QueueEntry.SetXml(Xml);
        QueueEntry.Modify();
    end;

    /// <summary>
    /// Call from a Job Queue Entry (recurring, e.g. every 5 min). Sends all pending items.
    /// Never raises an error out of this procedure - failures are logged on the queue record
    /// so one bad message doesn't stop the batch or fail the job queue entry itself.
    /// </summary>
    procedure ProcessQueue()
    var
        QueueEntry: Record "EDoc CDV Outbound Queue";
        Setup: Record "EDoc CDV Setup";
    begin
        Setup := Setup.GetSetup();

        QueueEntry.SetRange(Status, QueueEntry.Status::Pending);
        if QueueEntry.FindSet(true) then
            repeat
                if QueueEntry.Attempts < Setup."Max Send Attempts" then
                    SendOne(QueueEntry, Setup);
            until QueueEntry.Next() = 0;
    end;

    local procedure SendOne(var QueueEntry: Record "EDoc CDV Outbound Queue"; Setup: Record "EDoc CDV Setup")
    var
        StatusCode: Integer;
        ResponseText: Text;
        ErrorText: Text;
        Success: Boolean;
    begin
        QueueEntry.Attempts += 1;
        QueueEntry."Last Attempt DateTime" := CurrentDateTime;

        Success := TrySendXml(QueueEntry.GetXml(), Setup, StatusCode, ResponseText, ErrorText);

        QueueEntry."Last HTTP Status Code" := StatusCode;
        QueueEntry.SetResponse(ResponseText);

        if Success then begin
            QueueEntry.Status := QueueEntry.Status::Sent;
            QueueEntry."Last Error" := '';
        end else begin
            QueueEntry."Last Error" := CopyStr(ErrorText, 1, MaxStrLen(QueueEntry."Last Error"));
            if QueueEntry.Attempts >= Setup."Max Send Attempts" then
                QueueEntry.Status := QueueEntry.Status::Error;
            // else stays Pending - will be retried on the next ProcessQueue run
        end;

        QueueEntry.Modify();
    end;

    [TryFunction]
    local procedure TrySendXml(Xml: Text; Setup: Record "EDoc CDV Setup"; var StatusCode: Integer; var ResponseText: Text; var ErrorText: Text)
    var
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        ApiKey: Text;
    begin
        if Setup."PPF Endpoint URL" = '' then begin
            ErrorText := 'PPF Endpoint URL is not configured in EDoc CDV Setup.';
            StatusCode := 0;
            exit(false);
        end;

        Content.WriteFrom(Xml);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/xml; charset=utf-8');

        RequestMsg.Method := 'POST';
        RequestMsg.SetRequestUri(Setup."PPF Endpoint URL");
        RequestMsg.Content := Content;

        RequestMsg.GetHeaders(RequestHeaders);
        case Setup."Authentication Type" of
            Setup."Authentication Type"::"API Key":
                begin
                    ApiKey := GetApiKeyFromSetup();
                    RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', Format(ApiKey)));
                end;
            Setup."Authentication Type"::"OAuth2 Client Credentials":
                begin
                    // TODO: implement OAuth2 client-credentials token acquisition/caching here
                    // (or reuse your existing Flux 2 OAuth logic) before setting the header.
                    ErrorText := 'OAuth2 client credentials flow not yet implemented - see TODO.';
                    exit(false);
                end;
        end;

        Client.Timeout := Setup."Request Timeout (sec.)" * 1000;

        if not Client.Send(RequestMsg, ResponseMsg) then begin
            ErrorText := 'HTTP request failed to send (network/timeout).';
            StatusCode := 0;
            exit(false);
        end;

        StatusCode := ResponseMsg.HttpStatusCode();
        ResponseMsg.Content.ReadAs(ResponseText);

        if not ResponseMsg.IsSuccessStatusCode() then begin
            ErrorText := StrSubstNo('PPF returned HTTP %1: %2', StatusCode, CopyStr(ResponseText, 1, 200));
            exit(false);
        end;

        exit(true);
    end;

    local procedure GetApiKeyFromSetup(): Text
    var
        Setup: Record "EDoc CDV Setup";
    begin
        Setup := Setup.GetSetup();
        exit(Setup.GetApiKey());
    end;
}
