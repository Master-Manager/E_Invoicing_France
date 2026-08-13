codeunit 70134 "EDoc CDV Queue Processor"
{
    Access = Public;

    /// <summary>
    /// Processes all pending entries in the EDoc CDV Outbound Queue.
    /// Can be called via a Job Queue or automatically upon payment application.
    /// </summary>
    procedure ProcessPendingQueue()
    var
        OutboundQueue: Record "EDoc CDV Outbound Queue";
    begin
        OutboundQueue.SetRange(Status, OutboundQueue.Status::Pending);
        if OutboundQueue.FindSet() then
            repeat
                ProcessQueueEntry(OutboundQueue);
            until OutboundQueue.Next() = 0;
    end;

    local procedure ProcessQueueEntry(var OutboundQueue: Record "EDoc CDV Outbound Queue")
    var
        EDoc: Record "EDoc Document";
        StatusInfo: Record "EDoc CDV Status Info" temporary;
        VATBuffer: Record "EDoc VAT Buffer" temporary;
        Flow6Builder: Codeunit "EDoc ER Flow 6 Builder";
        XmlContent: Text;
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders; // <-- 1. Declare the HttpHeaders variable here
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        HttpStatusCode: Integer;
    begin
        // 1. Find the related EDoc Document by Invoice No.
        EDoc.SetRange("Invoice No.", OutboundQueue."Invoice No.");
        if not EDoc.FindFirst() then begin
            LogTransmissionError(OutboundQueue, 0, StrSubstNo('EDoc Document not found for Invoice No. %1', OutboundQueue."Invoice No."));
            exit;
        end;

        // 2. Prepare Status Info & VAT Buffer for Flow 6 (Encaissée / 212)
        Flow6Builder.GetStatusInfo(EDoc, StatusInfo);
        Flow6Builder.BuildVATBufferFromEDoc(EDoc, VATBuffer);

        // 3. Build XML Content if not already stored in the queue
        XmlContent := OutboundQueue.GetXml();
        if XmlContent = '' then begin
            XmlContent := Flow6Builder.BuildFlow6Xml(EDoc, StatusInfo, VATBuffer);
            OutboundQueue.SetXml(XmlContent);
            OutboundQueue.Modify(true);
        end;

        // 4. Prepare HTTP Content and Headers properly
        Content.Clear();
        Content.WriteFrom(XmlContent);

        // <-- 2. Pass ContentHeaders into GetHeaders() to satisfy the parameter requirement
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/xml; charset=utf-8');

        // 5. Send HTTP Request to your PDP / PPF endpoint
        HttpStatusCode := 0;
        if Client.Post('https://api.your-pdp-endpoint.com/flow6/cdv', Content, ResponseMessage) then begin
            HttpStatusCode := ResponseMessage.HttpStatusCode;
            ResponseMessage.Content.ReadAs(ResponseText);

            if ResponseMessage.IsSuccessStatusCode() then
                LogTransmissionSuccess(OutboundQueue, HttpStatusCode, ResponseText)
            else
                LogTransmissionError(OutboundQueue, HttpStatusCode, ResponseText);
        end else begin
            LogTransmissionError(OutboundQueue, HttpStatusCode, GetLastErrorText());
        end;
    end;

    /// <summary>
    /// Updates the queue entry on transmission failure.
    /// </summary>
    procedure LogTransmissionError(var OutboundQueue: Record "EDoc CDV Outbound Queue"; HttpStatusCode: Integer; ErrorMessage: Text)
    begin
        OutboundQueue.LockTable();
        if OutboundQueue.Find() then begin
            OutboundQueue.Attempts += 1;
            OutboundQueue."Last Attempt DateTime" := CurrentDateTime;
            OutboundQueue."Last HTTP Status Code" := HttpStatusCode;

            if StrLen(ErrorMessage) > MaxStrLen(OutboundQueue."Last Error") then
                OutboundQueue."Last Error" := CopyStr(ErrorMessage, 1, MaxStrLen(OutboundQueue."Last Error"))
            else
                OutboundQueue."Last Error" := CopyStr(ErrorMessage, 1);

            OutboundQueue.Status := OutboundQueue.Status::Error;
            OutboundQueue.Modify(true);
        end;
    end;

    /// <summary>
    /// Updates the queue entry on successful transmission.
    /// </summary>
    procedure LogTransmissionSuccess(var OutboundQueue: Record "EDoc CDV Outbound Queue"; HttpStatusCode: Integer; ResponseText: Text)
    begin
        OutboundQueue.LockTable();
        if OutboundQueue.Find() then begin
            OutboundQueue.Attempts += 1;
            OutboundQueue."Last Attempt DateTime" := CurrentDateTime;
            OutboundQueue."Last HTTP Status Code" := HttpStatusCode;
            OutboundQueue."Last Error" := '';
            OutboundQueue.Status := OutboundQueue.Status::Sent;
            OutboundQueue.SetResponse(ResponseText);
            OutboundQueue.Modify(true);
        end;
    end;
}