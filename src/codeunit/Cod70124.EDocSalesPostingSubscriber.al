codeunit 70124 "EDoc Sales Posting Subscriber"
{
    Access = Internal;



    //INVOICES
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure OnAfterSalesInvHeaderInsert(
        var SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CommitIsSuppressed: Boolean;
        PreviewMode: Boolean)
    var
        EDoc: Record "EDoc Document";
        ImportMgt: Codeunit "EDoc Import Mgt.";
    begin
        if PreviewMode then
            exit;

        // Prevent duplicate imports
        EDoc.SetRange("Table ID", Database::"Sales Invoice Header");
        EDoc.SetRange("Document No.", SalesInvHeader."No.");
        if EDoc.FindFirst() then
            exit;

        ImportMgt.ImportSalesInvoice(
            SalesInvHeader."No.",
            EDoc);
    end;

    //CREDIT MEMOS
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(
     var SalesCrMemoHeader: Record "Sales Cr.Memo Header";
     SalesHeader: Record "Sales Header";
     CommitIsSuppressed: Boolean)
    var
        EDoc: Record "EDoc Document";
        ImportMgt: Codeunit "EDoc Import Mgt.";
    begin
        EDoc.SetRange("Table ID", Database::"Sales Cr.Memo Header");
        EDoc.SetRange("Document No.", SalesCrMemoHeader."No.");
        if EDoc.FindFirst() then
            exit;

        ImportMgt.ImportPostedSalesCreditMemo(
            SalesCrMemoHeader."No.",
            EDoc);
    end;
}