codeunit 70125 "EDoc Sales Posting Subscriber"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(
        var SalesHeader: Record "Sales Header";
        var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        SalesShptHdrNo: Code[20];
        RetRcpHdrNo: Code[20];
        SalesInvHdrNo: Code[20];
        SalesCrMemoHdrNo: Code[20];
        CommitIsSuppressed: Boolean;
        InvtPickPutaway: Boolean;
        var CustLedgerEntry: Record "Cust. Ledger Entry";
        WhseShip: Boolean;
        WhseReceiv: Boolean;
        PreviewMode: Boolean)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if PreviewMode then
            exit;


        if (SalesInvHdrNo = '') and (SalesCrMemoHdrNo = '') then
            exit;

        // Sales Invoice
        if SalesInvHdrNo <> '' then begin
            if SalesInvHeader.Get(SalesInvHdrNo) then
                CreateEDocFromPostedInvoice(SalesInvHeader);
        end;

        // Sales Credit Memo
        if SalesCrMemoHdrNo <> '' then begin
            if SalesCrMemoHeader.Get(SalesCrMemoHdrNo) then
                CreateEDocFromPostedCreditMemo(SalesCrMemoHeader);
        end;
    end;


    local procedure CreateEDocFromPostedInvoice(
    SalesInvHeader: Record "Sales Invoice Header")
    var
        EDoc: Record "EDoc Document";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        ImportMgt: Codeunit "EDoc Import Mgt.";
        Builder: Codeunit "EDoc Sovos Invoice Builder";
        SBDBuilder: Codeunit "SBD Builder";
        Sovos: Codeunit "Sovos Client";
        SovosDocMgt: Codeunit "EDoc Sovos Document Mgt.";
        Xml: Text;
        SBD: Text;
        DocumentId: Text;
        Response: Text;
    begin
        // Prevent duplicate EDoc creation.
        EDoc.SetRange("Table ID", Database::"Sales Invoice Header");
        EDoc.SetRange("Document No.", SalesInvHeader."No.");

        if EDoc.FindFirst() then
            exit;

        // Get Customer and Supplier

        Customer.Get(SalesInvHeader."Bill-to Customer No.");
        CompanyInfo.Get();

        // Validate E-Document master data

        ImportMgt.CheckEdocumentVendorCustomer(
            Customer,
            CompanyInfo);

        // Create EDoc from posted invoice

        ImportMgt.ImportSalesInvoice(
            SalesInvHeader."No.",
            EDoc);

        // Build Sovos XML

        Xml := Builder.BuildInvoiceXml(EDoc);

        // Build SBD wrapper

        SBD := SBDBuilder.BuildSBD(
            Xml,
            EDoc);

        if edoc."Flow Type" = edoc."Flow Type"::"Flux 2 - Invoicing" then begin
            // Send to Sovos.
            Response :=
                Sovos.SendInvoice(
                    SBD,
                    DocumentId);

            // Create Sovos tracking record.
            if DocumentId <> '' then begin
                EDoc."Sovos Document Id" := DocumentId;

                SovosDocMgt.CreateFromSubmission(
                    EDoc,
                    Response,
                    DocumentId);
            end;

            EDoc.Status := EDoc.Status::Sent;
            EDoc.Modify(true);
        end;
    end;


    local procedure CreateEDocFromPostedCreditMemo(
    SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        EDoc: Record "EDoc Document";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        ImportMgt: Codeunit "EDoc Import Mgt.";
        Builder: Codeunit "EDoc Sovos Invoice Builder";
        SBDBuilder: Codeunit "SBD Builder";
        Sovos: Codeunit "Sovos Client";
        SovosDocMgt: Codeunit "EDoc Sovos Document Mgt.";
        Xml: Text;
        SBD: Text;
        DocumentId: Text;
        Response: Text;
    begin
        // Prevent duplicate EDoc creation.
        EDoc.SetRange("Table ID", Database::"Sales Cr.Memo Header");
        EDoc.SetRange("Document No.", SalesCrMemoHeader."No.");

        if EDoc.FindFirst() then
            exit;

        // Get Customer and Supplier

        Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
        CompanyInfo.Get();

        // Validate E-Document master data

        ImportMgt.CheckEdocumentVendorCustomer(
            Customer,
            CompanyInfo);

        // Create EDoc from posted credit memo

        ImportMgt.ImportPostedSalesCreditMemo(
            SalesCrMemoHeader."No.",
            EDoc);

        // Build Sovos XML

        Xml := Builder.BuildInvoiceXml(EDoc);

        // Build SBD wrapper

        SBD := SBDBuilder.BuildSBD(
            Xml,
            EDoc);

        if edoc."Flow Type" = edoc."Flow Type"::"Flux 2 - Invoicing" then begin
            // Send to Sovos.
            Response :=
                Sovos.SendInvoice(
                    SBD,
                    DocumentId);

            // Create Sovos tracking record.
            if DocumentId <> '' then begin
                EDoc."Sovos Document Id" := DocumentId;

                SovosDocMgt.CreateFromSubmission(
                    EDoc,
                    Response,
                    DocumentId);
            end;

            EDoc.Status := EDoc.Status::Sent;
            EDoc.Modify(true);
        end;
    end;
}