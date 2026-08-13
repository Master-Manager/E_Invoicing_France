codeunit 70116 "EDoc Sovos Document Mgt."
{
    Access = Internal;

    /// <summary>
    /// Creates (or updates, on resend) the "EDoc Sovos Document" tracking row after a
    /// successful POST /v1/documents, copying quick-reference info from the source
    /// EDoc Document and parsing the transactionId out of the raw response.
    /// </summary>
    procedure CreateFromSubmission(EDoc: Record "EDoc Document"; ResponseText: Text; DocumentId: Text): Integer
    var
        SovosDoc: Record "EDoc Sovos Document";
    begin
        SovosDoc.SetRange("EDoc Document Entry No.", EDoc."Entry No.");
        SovosDoc.SetRange("Document Id", DocumentId);
        if not SovosDoc.FindFirst() then begin
            SovosDoc.Init();
            SovosDoc."EDoc Document Entry No." := EDoc."Entry No.";
            SovosDoc."Document Id" := CopyStr(DocumentId, 1, MaxStrLen(SovosDoc."Document Id"));
            SovosDoc."Country Code" := 'FR';
            SovosDoc.Insert(true);
        end;

        SovosDoc."Transaction Id" := CopyStr(ExtractTransactionId(ResponseText), 1, MaxStrLen(SovosDoc."Transaction Id"));
        SovosDoc."Invoice No." := EDoc."Invoice No.";
        SovosDoc."Supplier Name" := EDoc."Supplier Name";
        SovosDoc."Customer Name" := EDoc."Customer Name";
        SovosDoc."Amount Incl. VAT" := EDoc."Amount Incl. VAT";
        SovosDoc."Currency Code" := EDoc."Currency Code";
        SovosDoc."Sent At" := CurrentDateTime();
        SovosDoc.SetSubmissionResponse(ResponseText);
        SovosDoc.Modify(true);

        exit(SovosDoc."Entry No.");
    end;

    /// <summary>
    /// Calls GET /v1/documents/{countryCode}/{documentId}/notifications and stores every
    /// notification not already known (matched on Notification Id, so repeated polling is safe).
    /// </summary>
    procedure PullNotifications(var SovosDoc: Record "EDoc Sovos Document")
    var
        SovosClient: Codeunit "Sovos Client";
        ResponseText: Text;
    begin
        if SovosDoc."Document Id" = '' then
            Error('This entry has no Sovos Document Id.');

        ResponseText := SovosClient.GetDocumentNotifications(SovosDoc."Country Code", SovosDoc."Document Id");

        SovosDoc.UpdateSovosStatus();

        ParseAndStoreNotifications(SovosDoc."Entry No.", ResponseText);

        SovosDoc."Last Notification Check At" := CurrentDateTime();
        SovosDoc.Modify(true);
    end;

    local procedure ParseAndStoreNotifications(SovosDocEntryNo: Integer; ResponseText: Text)
    var
        JResponse: JsonObject;
        JDataToken: JsonToken;
        JNotificationsToken: JsonToken;
        JNotificationToken: JsonToken;
    begin
        if ResponseText = '' then
            exit;
        if not JResponse.ReadFrom(ResponseText) then
            exit;
        if not JResponse.Get('data', JDataToken) then
            exit;
        if not JDataToken.IsObject() then
            exit;
        if not JDataToken.AsObject().Get('notifications', JNotificationsToken) then
            exit;
        if not JNotificationsToken.IsArray() then
            exit;

        foreach JNotificationToken in JNotificationsToken.AsArray() do
            StoreNotificationIfNew(SovosDocEntryNo, JNotificationToken.AsObject());
    end;

    local procedure StoreNotificationIfNew(SovosDocEntryNo: Integer; NotificationObj: JsonObject)
    var
        Notification: Record "EDoc Sovos Notification";
        MetadataObj: JsonObject;
        NotificationId: Text;
        NotificationJson: Text;
        SovosDocument: Record "EDoc Sovos Document";
        NotificationEntryNo: Integer;
    begin
        NotificationId := GetJsonText(NotificationObj, 'notificationId');

        // ---------------------------------------------------------
        // Check if this exact notification already exists
        // ---------------------------------------------------------
        Notification.Reset();
        Notification.SetRange("Sovos Document Entry No.", SovosDocEntryNo);
        Notification.SetRange("Notification Id", NotificationId);

        if (NotificationId <> '') and Notification.FindFirst() then begin

            // Notification already exists.
            // Re-process its errors if it is an RE notification.
            if Notification."SCI Response Code" = 'RE' then begin
                InsertEDocErrors(
                    GetEDocEntryNoFromSovosDocument(SovosDocEntryNo),
                    Notification."Entry No.",
                    NotificationObj);
            end;

            exit;
        end;

        MetadataObj := GetJsonObject(NotificationObj, 'metadata');

        Notification.Init();
        Notification."Sovos Document Entry No." := SovosDocEntryNo;
        Notification."Notification Id" := CopyStr(NotificationId, 1, MaxStrLen(Notification."Notification Id"));
        Notification."Correlation Id" := CopyStr(GetJsonText(NotificationObj, 'correlationId'), 1, MaxStrLen(Notification."Correlation Id"));
        Notification."Created Date" := ParseEpochMillis(GetJsonText(NotificationObj, 'createdDate'));

        Notification."Product Id" := CopyStr(GetJsonText(MetadataObj, 'productId'), 1, MaxStrLen(Notification."Product Id"));
        Notification."ERP Document Id" := CopyStr(GetJsonText(MetadataObj, 'erpDocumentId'), 1, MaxStrLen(Notification."ERP Document Id"));
        Notification."ERP System Id" := CopyStr(GetJsonText(MetadataObj, 'erpSystemId'), 1, MaxStrLen(Notification."ERP System Id"));
        Notification."Process Type" := CopyStr(GetJsonText(MetadataObj, 'processType'), 1, MaxStrLen(Notification."Process Type"));
        Notification."Tax Id" := CopyStr(GetJsonText(MetadataObj, 'taxId'), 1, MaxStrLen(Notification."Tax Id"));
        Notification."SCI Cloud Status Code" := CopyStr(GetJsonText(MetadataObj, 'sciCloudStatusCode'), 1, MaxStrLen(Notification."SCI Cloud Status Code"));
        Notification."SCI Response Code" := CopyStr(GetJsonText(MetadataObj, 'sciResponseCode'), 1, MaxStrLen(Notification."SCI Response Code"));
        Notification."SCI Status Action" := CopyStr(GetJsonText(MetadataObj, 'sciStatusAction'), 1, MaxStrLen(Notification."SCI Status Action"));

        Notification."Retrieved At" := CurrentDateTime();

        Notification.Insert(true);

        Notification.SetContentBase64(GetJsonText(NotificationObj, 'content'));

        NotificationObj.WriteTo(NotificationJson);
        Notification.SetRawJson(NotificationJson);
        Notification.Modify(true);

        // Parse errors for a newly inserted RE notification
        if Notification."SCI Response Code" = 'RE' then begin
            InsertEDocErrors(
                GetEDocEntryNoFromSovosDocument(SovosDocEntryNo),
                Notification."Entry No.",
                NotificationObj);
        end;

    end;

    local procedure GetEDocEntryNoFromSovosDocument(
        SovosDocEntryNo: Integer): Integer
    var
        SovosDoc: Record "EDoc Sovos Document";
    begin
        if SovosDoc.Get(SovosDocEntryNo) then
            exit(SovosDoc."EDoc Document Entry No.");

        exit(0);
    end;

    local procedure InsertEDocErrors(
     EDocEntryNo: Integer;
     NotificationEntryNo: Integer;
     NotificationObj: JsonObject)
    var
        Base64Convert: Codeunit "Base64 Convert";
        EDocError: Record "EDoc Error";

        ContentText: Text;
        XmlText: Text;

        XmlDoc: XmlDocument;
        StatusNodes: XmlNodeList;
        StatusReasonNodes: XmlNodeList;

        StatusNode: XmlNode;
        StatusReasonNode: XmlNode;

        StatusElement: XmlElement;

        StatusReasonCode: Text;
        GeneralMessage: Text;
        DetailedMessage: Text;

        ReasonCount: Integer;
    begin
        ContentText :=
            GetJsonText(
                NotificationObj,
                'content');

        if ContentText = '' then
            exit;

        XmlText :=
            Base64Convert.FromBase64(
                ContentText,
                TextEncoding::UTF8);

        if XmlText = '' then
            exit;

        if not XmlDocument.ReadFrom(
            XmlText,
            XmlDoc)
        then
            exit;

        if not XmlDoc.SelectNodes(
            '//*[local-name()="DocumentResponse"]/*[local-name()="Response"]/*[local-name()="Status"]',
            StatusNodes)
        then
            exit;

        foreach StatusNode in StatusNodes do begin

            if StatusNode.IsXmlElement() then begin

                StatusElement :=
                    StatusNode.AsXmlElement();

                Clear(StatusReasonCode);
                Clear(GeneralMessage);
                Clear(DetailedMessage);
                Clear(ReasonCount);

                //-----------------------------------------
                // StatusReasonCode
                //-----------------------------------------

                if StatusElement.SelectNodes(
                    '*[local-name()="StatusReasonCode"]',
                    StatusReasonNodes)
                then begin

                    foreach StatusReasonNode in StatusReasonNodes do begin

                        if StatusReasonNode.IsXmlElement() then begin

                            StatusReasonCode :=
                                StatusReasonNode.AsXmlElement().InnerText();

                            // We only need the first StatusReasonCode.
                            ReasonCount := 0;
                        end;
                    end;
                end;

                //-----------------------------------------
                // StatusReason
                //-----------------------------------------

                Clear(ReasonCount);

                if StatusElement.SelectNodes(
                    '*[local-name()="StatusReason"]',
                    StatusReasonNodes)
                then begin

                    foreach StatusReasonNode in StatusReasonNodes do begin

                        if StatusReasonNode.IsXmlElement() then begin

                            ReasonCount += 1;

                            if ReasonCount = 1 then begin

                                // First StatusReason
                                GeneralMessage :=
                                    StatusReasonNode.AsXmlElement().InnerText();

                            end else begin

                                // Additional StatusReason
                                if DetailedMessage <> '' then
                                    DetailedMessage += '\';

                                DetailedMessage :=
                                    DetailedMessage +
                                    StatusReasonNode.AsXmlElement().InnerText();
                            end;
                        end;
                    end;
                end;

                //-----------------------------------------
                // Create EDoc Error
                //-----------------------------------------

                if (StatusReasonCode <> '') or
                   (GeneralMessage <> '') or
                   (DetailedMessage <> '')
                then begin

                    // Check if this exact error already exists
                    EDocError.Reset();
                    EDocError.SetRange(
                        "Notification Entry No.",
                        NotificationEntryNo);

                    EDocError.SetRange(
                        "Error Code",
                        StatusReasonCode);
                    EDocError.SetRange("EDoc Entry No.", EDocEntryNo);
                    if not EDocError.FindFirst() then begin

                        // Start with a completely clean record
                        Clear(EDocError);
                        EDocError.Init();

                        EDocError."EDoc Entry No." :=
                            EDocEntryNo;
                        EDocError."Notification Entry No." :=
                            NotificationEntryNo;

                        EDocError."Error Code" :=
                            CopyStr(
                                StatusReasonCode,
                                1,
                                MaxStrLen(EDocError."Error Code"));

                        EDocError."General Message" :=
                            CopyStr(
                                GeneralMessage,
                                1,
                                MaxStrLen(EDocError."General Message"));

                        EDocError."Error Message" :=
                            CopyStr(
                                DetailedMessage,
                                1,
                                MaxStrLen(EDocError."Error Message"));

                        EDocError."Created At" :=
                            CurrentDateTime();
                        EDocError.Insert(true);
                    end;
                end;
            end;
        end;
    end;

    local procedure GetJsonObject(Parent: JsonObject; PropertyName: Text): JsonObject
    var
        JToken: JsonToken;
        Empty: JsonObject;
    begin
        if Parent.Get(PropertyName, JToken) then
            if JToken.IsObject() then
                exit(JToken.AsObject());
        exit(Empty);
    end;

    local procedure GetJsonText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyName, JToken) then
            exit('');
        if JToken.AsValue().IsNull() then
            exit('');
        // createdDate can come back as either a JSON number or a quoted string depending on
        // the endpoint/version - AsText() on a JsonValue handles both without erroring.
        exit(JToken.AsValue().AsText());
    end;

    /// <summary>
    /// Sovos timestamps (e.g. "createdDate", the top-level "timestamp") are epoch milliseconds.
    /// </summary>
    local procedure ParseEpochMillis(EpochText: Text): DateTime
    var
        EpochMillis: BigInteger;
        Epoch: DateTime;
    begin
        if EpochText = '' then
            exit(0DT);
        if not Evaluate(EpochMillis, EpochText) then
            exit(0DT);

        Epoch := CreateDateTime(19700101D, 0T);
        exit(Epoch + EpochMillis);
    end;

    local procedure ExtractTransactionId(ResponseText: Text): Text
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
        if not JDataToken.AsObject().Get('transactionId', JIdToken) then
            exit('');

        exit(JIdToken.AsValue().AsText());
    end;
}
