// Façade e-reporting : le flux 10.1 est un rapport de PÉRIODE (un XML = N factures).
// Les appels par ligne unique (BuildEReportingXml(EDoc)) ne sont plus supportés pour 10.1.
codeunit 70117 "EDoc Sovos EReporting Builder"
{
    Access = Internal;

    var
        CurrentEDocEntryNo: Integer;
        CurrentLineNo: Integer;
        HeaderSeqNo: Integer;
        LineSeqNo: Integer;
        PathStack: List of [Text];

    procedure BuildFlow101Xml(var EDoc: Record "EDoc Document"; ServiceCode: Code[20]): Text


    var
        Flow101: Codeunit "EDoc ER Flow 10.1 Builder";
    begin
        InitBuffers(EDoc."Entry No.");
        exit(Flow101.BuildFlow101Xml(EDoc, ServiceCode));
    end;

    procedure InitBuffers(EDocEntryNo: Integer)
    var
        HeaderBuffer: Record "EDoc Header XML Buffer";
        LineBuffer: Record "EDoc Line XML Buffer";
    begin
        CurrentEDocEntryNo := EDocEntryNo;
        HeaderSeqNo := 0;
        LineSeqNo := 0;
        Clear(PathStack);

        HeaderBuffer.SetRange("Buffer Entry No.", EDocEntryNo);
        HeaderBuffer.DeleteAll();

        LineBuffer.SetRange("Buffer Entry No.", EDocEntryNo);
        LineBuffer.DeleteAll();
    end;
}

