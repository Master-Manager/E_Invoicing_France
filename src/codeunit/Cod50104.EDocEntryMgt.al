codeunit 50104 "EDoc Entry Mgt."
{
    Access = Internal;

    procedure CreateEntry(DocumentType: Enum "EDoc Document Type"; DocumentNo: Code[20]): Integer
    var
        Entry: Record "EDoc Entry";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Service: Record "EDoc Service";
    begin
        SetupMgt.GetDefaultService(Service);

        Entry.Init();
        Entry."Document Type" := DocumentType;
        Entry."Document No." := DocumentNo;
        Entry."Service Code" := Service.Code;
        Entry.Status := Entry.Status::Pending;
        Entry."Created At" := CurrentDateTime();
        Entry."Last Modified At" := CurrentDateTime();

        Entry.Insert(true);

        exit(Entry."Entry No.");
    end;

    procedure SetRequestJson(var Entry: Record "EDoc Entry"; JsonText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Entry."Request JSON");

        Entry."Request JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);

        Entry."Last Modified At" := CurrentDateTime();

        Entry.Modify(true);
    end;

    procedure SetResponseJson(var Entry: Record "EDoc Entry"; JsonText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Entry."Response JSON");

        Entry."Response JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);

        Entry."Last Modified At" := CurrentDateTime();

        Entry.Modify(true);
    end;

    procedure GetRequestJson(Entry: Record "EDoc Entry"): Text
    var
        InStr: InStream;
        JsonText: Text;
    begin
        if not Entry."Request JSON".HasValue() then
            exit('');

        Entry.CalcFields("Request JSON");

        Entry."Request JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(JsonText);

        exit(JsonText);
    end;

    procedure GetResponseJson(Entry: Record "EDoc Entry"): Text
    var
        InStr: InStream;
        JsonText: Text;
    begin
        if not Entry."Response JSON".HasValue() then
            exit('');

        Entry.CalcFields("Response JSON");

        Entry."Response JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(JsonText);

        exit(JsonText);
    end;

    procedure SetStatus(var Entry: Record "EDoc Entry"; NewStatus: Enum "EDoc Entry Status")
    begin
        Entry.Status := NewStatus;
        Entry."Last Modified At" := CurrentDateTime();

        if NewStatus = Entry.Status::Sent then
            Entry."Sent At" := CurrentDateTime();

        Entry.Modify(true);
    end;

    procedure SetError(var Entry: Record "EDoc Entry"; ErrorMessage: Text)
    begin
        Entry.Status := Entry.Status::Error;
        Entry."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(Entry."Error Message"));
        Entry."Last Modified At" := CurrentDateTime();

        Entry.Modify(true);
    end;

    procedure SetSovosDocumentId(var Entry: Record "EDoc Entry"; DocumentId: Text)
    begin
        Entry."Sovos Document Id" := CopyStr(DocumentId, 1, MaxStrLen(Entry."Sovos Document Id"));
        Entry."Last Modified At" := CurrentDateTime();

        Entry.Modify(true);
    end;
}