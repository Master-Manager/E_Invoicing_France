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
    begin
        NotificationId := GetJsonText(NotificationObj, 'notificationId');

        // Idempotent: skip if we've already stored this exact notification.
        Notification.SetRange("Notification Id", NotificationId);
        if (NotificationId <> '') and not Notification.IsEmpty() then
            exit;

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
