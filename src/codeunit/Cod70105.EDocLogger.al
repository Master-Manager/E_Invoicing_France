codeunit 70105 "EDoc Logger"
{
    Access = Internal;

    procedure LogInformation(
        EDocEntryNo: Integer;
        MessageText: Text;
        SourceCodeunit: Text)
    begin
        InsertLog(
            EDocEntryNo,
            Enum::"EDoc Log Level"::Information,
            MessageText,
            SourceCodeunit);
    end;

    procedure LogHttpExchange(
    Category: Enum "EDoc Log Category";
    RelatedEntryNo: Integer;
    RequestText: Text;
    ResponseText: Text;
    StatusCode: Integer;
    MessageText: Text;
    SourceCodeunit: Text;
    LogLevel: Enum "EDoc Log Level")
    var
        LogEntry: Record "EDoc Log";
        OutStr: OutStream;
    begin
        LogEntry.Init();

        LogEntry."EDoc Entry No." := RelatedEntryNo;
        LogEntry."Created At" := CurrentDateTime();
        LogEntry.Level := LogLevel;
        LogEntry.Category := Category;
        LogEntry."HTTP Status Code" := StatusCode;
        LogEntry.Message :=
            CopyStr(MessageText, 1, MaxStrLen(LogEntry.Message));
        LogEntry."Source Codeunit" :=
            CopyStr(SourceCodeunit, 1, MaxStrLen(LogEntry."Source Codeunit"));

        LogEntry.Insert(true);

        if RequestText <> '' then begin
            LogEntry."Request JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(RequestText);
        end;

        if ResponseText <> '' then begin
            LogEntry."Response JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(ResponseText);
        end;

        LogEntry.Modify(true);
    end;

    procedure LogWarning(
        EDocEntryNo: Integer;
        MessageText: Text;
        SourceCodeunit: Text)
    begin
        InsertLog(
            EDocEntryNo,
            Enum::"EDoc Log Level"::Warning,
            MessageText,
            SourceCodeunit);
    end;

    procedure LogError(
        EDocEntryNo: Integer;
        MessageText: Text;
        SourceCodeunit: Text)
    begin
        InsertLog(
            EDocEntryNo,
            Enum::"EDoc Log Level"::Error,
            MessageText,
            SourceCodeunit);
    end;

    local procedure InsertLog(
        EDocEntryNo: Integer;
        LogLevel: Enum "EDoc Log Level";
        MessageText: Text;
        SourceCodeunit: Text)
    var
        LogEntry: Record "EDoc Log";
    begin
        LogEntry.Init();
        LogEntry."EDoc Entry No." := EDocEntryNo;
        LogEntry."Created At" := CurrentDateTime();
        LogEntry.Level := LogLevel;
        LogEntry.Message := CopyStr(MessageText, 1, MaxStrLen(LogEntry.Message));
        LogEntry."Source Codeunit" := CopyStr(SourceCodeunit, 1, MaxStrLen(LogEntry."Source Codeunit"));
        LogEntry.Insert(true);
    end;
}