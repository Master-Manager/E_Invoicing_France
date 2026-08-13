codeunit 70136 "EDoc Notification Job"
{

    trigger OnRun()
    begin
        ProcessSubmittedDocuments();
    end;

    local procedure ProcessSubmittedDocuments()
    var
        SovosDocument: Record "EDoc Sovos Document";
        SovosDocumentMgt: Codeunit "EDoc Sovos Document Mgt.";
    begin
        if SovosDocument.FindSet() then
            repeat
                ProcessDocument(
                    SovosDocument,
                    SovosDocumentMgt);
            until SovosDocument.Next() = 0;
    end;

    local procedure ProcessDocument(
        var SovosDocument: Record "EDoc Sovos Document";
        var SovosDocumentMgt: Codeunit "EDoc Sovos Document Mgt.")
    begin
        if SovosDocument."Document Id" = '' then
            exit;

        SovosDocumentMgt.PullNotifications(SovosDocument);

        SovosDocument.UpdateSovosStatus();
        SovosDocument.Modify(true);
    end;
}