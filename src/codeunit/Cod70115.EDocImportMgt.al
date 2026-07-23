codeunit 70115 "EDoc Import Mgt."
{
    Access = Internal;

    //====================================================================
    // E-INVOICING (Flux 2 - domestic B2B) - UNCHANGED
    //====================================================================

    procedure CreateFromPostedInvoice(var EDoc: Record "EDoc Document")
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if Page.RunModal(Page::"Posted Sales Invoices", SalesInvHeader) <> Action::LookupOK then
            exit;

        /*ImportPostedSalesInvoice(
        SalesInvHeader."No.",
            EDoc);*/
        ImportSalesInvoice(
                   SalesInvHeader."No.",
                   EDoc);

    end;


    procedure ImportSalesInvoice(
        InvoiceNo: Code[20];
        var EDoc: Record "EDoc Document")
    var
        FlowType: Enum "EDoc Flow Type";
    begin
        FlowType := DetermineFlow(InvoiceNo);

        case FlowType of
            FlowType::Domestic:
                ImportPostedSalesInvoice(InvoiceNo, EDoc);
            FlowType::International,
            FlowType::Collection:
                ImportInternationalSalesInvoice(InvoiceNo, EDoc);
        end;
    end;

    local procedure DetermineFlow(InvoiceNo: Code[20]): Enum "EDoc Flow Type"
    var
        SalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
    begin
        SalesInvHeader.Get(InvoiceNo);
        Customer.Get(SalesInvHeader."Bill-to Customer No.");

        if Customer."Country/Region Code" = 'FR' then
            exit("EDoc Flow Type"::Domestic);

        exit("EDoc Flow Type"::International);
    end;


    procedure ImportPostedSalesInvoice(
    InvoiceNo: Code[20];
    var EDoc: Record "EDoc Document")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
    begin
        SalesInvHeader.Get(InvoiceNo);

        CompanyInfo.Get();

        Customer.Get(SalesInvHeader."Bill-to Customer No.");


        EDoc.SetRange("Table ID", Database::"Sales Invoice Header");
        EDoc.SetRange("Document No.", SalesInvHeader."No.");
        if EDoc.FindFirst() then begin
            EDoc.SetRange("Table ID");
            EDoc.SetRange("Document No.");
        end else begin

            EDoc.SetRange("Table ID");
            EDoc.SetRange("Document No.");
            EDoc.Init();
            EDoc."Table ID" := Database::"Sales Invoice Header";
            EDoc."Document No." := SalesInvHeader."No.";
            EDoc.Insert(true);
        end;

        CopyHeader(
            SalesInvHeader,
            CompanyInfo,
            Customer,
            EDoc);

        CopyLines(
            SalesInvHeader,
            EDoc);

        EDoc.Modify(true);
    end;

    local procedure CopyHeader(
    SalesInvHeader: Record "Sales Invoice Header";
    CompanyInfo: Record "Company Information";
    Customer: Record Customer;
    var EDoc: Record "EDoc Document")
    begin
        //---------------------------------------
        // Source
        //---------------------------------------

        EDoc."Document Record ID" := SalesInvHeader.RecordId();
        EDoc."Document No." := SalesInvHeader."No.";
        EDoc."Document Date" := SalesInvHeader."Document Date";
        EDoc."Posting Date" := SalesInvHeader."Posting Date";
        EDoc."Bill-to/Pay-to No." := SalesInvHeader."Bill-to Customer No.";
        EDoc."Bill-to/Pay-to Name" := SalesInvHeader."Bill-to Name";
        EDoc."Table ID" := Database::"Sales Invoice Header";

        //---------------------------------------
        // General
        //---------------------------------------

        EDoc."Invoice No." := SalesInvHeader."No.";
        EDoc."Document Type" := EDoc."Document Type"::Invoice;
        EDoc.Status := EDoc.Status::Open;

        EDoc."Issue Date" := SalesInvHeader."Posting Date";
        EDoc."Due Date" := SalesInvHeader."Due Date";

        //---------------------------------------
        // Currency
        //---------------------------------------

        EDoc."Currency Code" := SalesInvHeader."Currency Code";

        if EDoc."Currency Code" = '' then
            EDoc."Currency Code" := 'EUR';

        EDoc."Tax Currency Code" := EDoc."Currency Code";

        //---------------------------------------
        // References (BT-10, BT-13, BT-72) - sourced straight from the invoice, as you said
        //---------------------------------------

        EDoc."Buyer Reference" := SalesInvHeader."Your Reference";
        EDoc."Order No." := SalesInvHeader."Order No.";
        // Sales Invoice Header doesn't carry a dedicated "actual delivery date" field;
        // "Shipment Date" is the closest standard field representing when goods went out.
        // Flag for confirmation if Pluxee's definition of BT-72 needs to differ from this.
        EDoc."Actual Delivery Date" := SalesInvHeader."Shipment Date";

        //---------------------------------------
        // Payment (BT-20, BT-81) - from the invoice's own payment terms/method
        //---------------------------------------

        EDoc."Payment Means Code" := ResolvePaymentMeansCode(SalesInvHeader."Payment Method Code");
        EDoc."Payment Terms Note" := ResolvePaymentTermsNote(SalesInvHeader."Payment Terms Code");

        //---------------------------------------
        // Supplier
        //---------------------------------------

        EDoc."Supplier Name" := CompanyInfo.Name;
        EDoc."Supplier VAT No." := CompanyInfo."VAT Registration No.";
        EDoc."Supplier Address" := CompanyInfo.Address;
        EDoc."Supplier City" := CompanyInfo.City;
        EDoc."Supplier Post Code" := CompanyInfo."Post Code";
        EDoc."Supplier Country" := CompanyInfo."Country/Region Code";


        EDoc."Supplier SIREN" := CompanyInfo."EDoc SIREN";
        EDoc."Supplier SIRET" := CompanyInfo."EDoc SIRET";
        EDoc."Supplier Endpoint" := CompanyInfo."EDoc Endpoint ID";

        //---------------------------------------
        // Customer
        //---------------------------------------

        EDoc."Customer No." := Customer."No.";
        EDoc."Customer Name" := Customer.Name;
        EDoc."Customer VAT No." := Customer."VAT Registration No.";
        EDoc."Customer Address" := Customer.Address;
        EDoc."Customer City" := Customer.City;
        EDoc."Customer Post Code" := Customer."Post Code";
        EDoc."Customer Country" := Customer."Country/Region Code";


        EDoc."Customer SIREN" := Customer."EDoc SIREN";
        EDoc."Customer SIRET" := Customer."EDoc SIRET";
        EDoc."Customer Endpoint" := Customer."EDoc Endpoint ID";

        //---------------------------------------
        // Totals
        //---------------------------------------
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        EDoc."Amount Excl. VAT" := SalesInvHeader.Amount;

        EDoc."VAT Amount" :=
            SalesInvHeader."Amount Including VAT" -
            SalesInvHeader.Amount;

        EDoc."Amount Incl. VAT" :=
            SalesInvHeader."Amount Including VAT";

        EDoc."Payable Amount" :=
            SalesInvHeader."Amount Including VAT";

        EDoc.Modify(true);
    end;

    /// <summary>
    /// Maps the invoice's own BC Payment Method Code to the UNTDID 4461 code Sovos expects
    /// for BT-81, via "EDoc Payment Means Map" (falls back to "30" - Credit transfer).
    /// </summary>
    local procedure ResolvePaymentMeansCode(PaymentMethodCode: Code[10]): Code[10]
    var
        PaymentMeansMap: Record "EDoc Payment Means Map";
    begin
        exit(PaymentMeansMap.ResolveCode(PaymentMethodCode));
    end;

    /// <summary>
    /// Pulls the free-text payment terms straight from the invoice's own Payment Terms Code
    /// (BC "Payment Terms".Description) rather than inventing wording.
    /// </summary>
    local procedure ResolvePaymentTermsNote(PaymentTermsCode: Code[10]): Text[250]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTermsCode = '' then
            exit('');
        if not PaymentTerms.Get(PaymentTermsCode) then
            exit('');
        exit(CopyStr(PaymentTerms.Description, 1, 250));
    end;

    local procedure CopyLines(
     SalesInvHeader: Record "Sales Invoice Header";
     EDoc: Record "EDoc Document")
    var
        SalesInvLine: Record "Sales Invoice Line";
        EDocLine: Record "EDoc Document Line";
    begin
        EDocLine.SetRange("Document Entry No.", EDoc."Entry No.");

        if not EDocLine.IsEmpty then
            EDocLine.DeleteAll();

        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");

        if SalesInvLine.FindSet() then
            repeat
                EDocLine.Init();

                EDocLine."Document Entry No." := EDoc."Entry No.";
                EDocLine."Line No." := SalesInvLine."Line No.";

                //---------------------------------------
                // Source
                //---------------------------------------

                EDocLine."Source Line No." := SalesInvLine."Line No.";
                EDocLine.Type := SalesInvLine.Type;
                EDocLine."No." := SalesInvLine."No.";

                //---------------------------------------
                // Description
                //---------------------------------------

                EDocLine.Description := SalesInvLine.Description;
                EDocLine."Description 2" := SalesInvLine."Description 2";

                //---------------------------------------
                // Quantity
                //---------------------------------------

                EDocLine.Quantity := SalesInvLine.Quantity;
                EDocLine."Unit of Measure" := SalesInvLine."Unit of Measure Code";
                EDocLine."Unit Code" := 'C62';
                EDocLine."Base Quantity" := SalesInvLine.Quantity;
                EDocLine."Price Base Quantity" := 1;

                //---------------------------------------
                // Prices
                //---------------------------------------

                EDocLine."Unit Price" := SalesInvLine."Unit Price";
                EDocLine."Line Amount" := SalesInvLine."Line Amount";
                EDocLine."Line Discount Amount" := SalesInvLine."Line Discount Amount";

                //---------------------------------------
                // VAT
                //---------------------------------------

                EDocLine."VAT %" := SalesInvLine."VAT %";
                EDocLine."Taxable Amount" := SalesInvLine."Line Amount";
                EDocLine."Tax Amount" :=
                    SalesInvLine."Amount Including VAT" -
                    SalesInvLine."Line Amount";
                EDocLine."Amount Including VAT" := SalesInvLine."Amount Including VAT";

                case SalesInvLine."VAT %" of
                    0:
                        begin
                            EDocLine."VAT Category" := 'O';
                            EDocLine."Tax Exemption Code" := 'VATEX-EU-O';
                            EDocLine."Tax Exemption Reason" := 'Not subject to VAT';
                        end;
                    else
                        EDocLine."VAT Category" := 'S';
                end;

                //---------------------------------------
                // References
                //---------------------------------------

                EDocLine."Order No." := SalesInvHeader."Order No.";
                EDocLine."Order Line No." := 0;

                //---------------------------------------
                // Future
                //---------------------------------------

                EDocLine."Buyer Item No." := '';
                EDocLine."Seller Item No." := SalesInvLine."No.";
                EDocLine."Commodity Code" := '';
                EDocLine."Country of Origin" := '';
                EDocLine."Start Date" := SalesInvHeader."Posting Date";
                EDocLine."End Date" := SalesInvHeader."Posting Date";

                EDocLine.Insert();
            until SalesInvLine.Next() = 0;
    end;

    //====================================================================
    // E-REPORTING (International / Collection / B2C) - ADDED, fully separate
    // from the e-invoicing procedures above. Only CopyLines() is reused
    // (read-only call, no shared header/state), so nothing here can affect
    // the e-invoicing flow.
    //====================================================================

    procedure ImportInternationalSalesInvoice(InvoiceNo: Code[20]; var EReportingDoc: Record "EDoc Document")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Service: Record "EDoc Service";
        VATRate: Decimal;
        VATCategory: Code[10];
        CompanyInfo: Record "Company Information";
    begin
        SalesInvHeader.Get(InvoiceNo);
        Customer.Get(SalesInvHeader."Bill-to Customer No.");
        SetupMgt.GetDefaultService(Service);


        EReportingDoc.SetRange("Table ID", Database::"Sales Invoice Header");
        EReportingDoc.SetRange("Document No.", SalesInvHeader."No.");
        if not EReportingDoc.FindFirst() then begin
            EReportingDoc.Init();
            EReportingDoc."Table ID" := Database::"Sales Invoice Header";
            EReportingDoc."Document No." := SalesInvHeader."No.";
            EReportingDoc."Bill-to/Pay-to No." := SalesInvHeader."Bill-to Customer No.";
            EReportingDoc."Bill-to/Pay-to Name" := SalesInvHeader."Bill-to Name";
            EReportingDoc.Insert(true);
        end;
        EReportingDoc.SetRange("Table ID");
        EReportingDoc.SetRange("Document No.");

        CopyEReportingHeader(SalesInvHeader, Customer, EReportingDoc);
        CopyLines(SalesInvHeader, EReportingDoc);

        ResolveVATRateAndCategory(SalesInvHeader."No.", VATRate, VATCategory);
        EReportingDoc."VAT Rate" := VATRate;
        EReportingDoc."VAT Category" := VATCategory;

        EReportingDoc."Document Type" := EReportingDoc."Document Type"::"E-Reporting";
        EReportingDoc."Flow Type" := "EDoc Flow Type"::International;
        EReportingDoc."Service Code" := Service.Code;
        EReportingDoc.Status := EReportingDoc.Status::Pending;
        EReportingDoc."Created At" := CurrentDateTime();

        EReportingDoc.Modify(true);
    end;

    procedure ImportCollectionFromApplication(OriginalEReportingDoc: Record "EDoc Document"; CollectedAmount: Decimal; CollectionDate: Date; var NewEReportingDoc: Record "EDoc Document")

    begin
        NewEReportingDoc.Init();

        NewEReportingDoc."Document Type" := OriginalEReportingDoc."Document Type";
        NewEReportingDoc."Flow Type" := "EDoc Flow Type"::Collection;
        NewEReportingDoc."Service Code" := OriginalEReportingDoc."Service Code";
        NewEReportingDoc."Table ID" := OriginalEReportingDoc."Table ID";
        NewEReportingDoc."Document No." := OriginalEReportingDoc."Document No.";
        NewEReportingDoc."Document Record ID" := OriginalEReportingDoc."Document Record ID";
        NewEReportingDoc."Posting Date" := OriginalEReportingDoc."Posting Date";
        NewEReportingDoc."Invoice No." := OriginalEReportingDoc."Invoice No.";
        NewEReportingDoc."Issue Date" := OriginalEReportingDoc."Issue Date";
        NewEReportingDoc."Due Date" := OriginalEReportingDoc."Due Date";
        NewEReportingDoc."Collection Date" := CollectionDate;
        NewEReportingDoc."Counterparty Type" := OriginalEReportingDoc."Counterparty Type";
        NewEReportingDoc."Customer No." := OriginalEReportingDoc."Customer No.";
        NewEReportingDoc."Customer Name" := OriginalEReportingDoc."Customer Name";
        NewEReportingDoc."Customer VAT No." := OriginalEReportingDoc."Customer VAT No.";
        NewEReportingDoc."Customer Country" := OriginalEReportingDoc."Customer Country";
        NewEReportingDoc."Currency Code" := OriginalEReportingDoc."Currency Code";
        NewEReportingDoc."VAT Rate" := OriginalEReportingDoc."VAT Rate";
        NewEReportingDoc."VAT Category" := OriginalEReportingDoc."VAT Category";
        NewEReportingDoc."Amount Incl. VAT" := CollectedAmount;

        if NewEReportingDoc."VAT Rate" <> 0 then begin
            NewEReportingDoc."VAT Amount" := Round(CollectedAmount * NewEReportingDoc."VAT Rate" / (100 + NewEReportingDoc."VAT Rate"), 0.01);
            NewEReportingDoc."Amount Excl. VAT" := CollectedAmount - NewEReportingDoc."VAT Amount";
        end else begin
            NewEReportingDoc."VAT Amount" := 0;
            NewEReportingDoc."Amount Excl. VAT" := CollectedAmount;
        end;

        NewEReportingDoc.Status := NewEReportingDoc.Status::Pending;
        NewEReportingDoc."Created At" := CurrentDateTime();
        NewEReportingDoc.Insert(true);
    end;

    /// <summary>
    /// E-reporting's own header mapping - deliberately separate from CopyHeader() above
    /// (which stays e-invoicing-only) even though several fields overlap, so that changes
    /// to one flow can never accidentally affect the other.
    /// </summary>
    local procedure CopyEReportingHeader(SalesInvHeader: Record "Sales Invoice Header"; Customer: Record Customer; var EReportingDoc: Record "EDoc Document")
    Var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        EReportingDoc."Document Record ID" := SalesInvHeader.RecordId();
        EReportingDoc."Posting Date" := SalesInvHeader."Posting Date";
        EReportingDoc."Document Date" := SalesInvHeader."Document Date";
        EReportingDoc."Invoice No." := SalesInvHeader."No.";
        EReportingDoc."Issue Date" := SalesInvHeader."Posting Date";
        EReportingDoc."Due Date" := SalesInvHeader."Due Date";

        EReportingDoc."Supplier Name" := CompanyInfo.Name;
        EReportingDoc."Supplier VAT No." := CompanyInfo."VAT Registration No.";
        EReportingDoc."Supplier Address" := CompanyInfo.Address;
        EReportingDoc."Supplier City" := CompanyInfo.City;
        EReportingDoc."Supplier Post Code" := CompanyInfo."Post Code";
        EReportingDoc."Supplier Country" := CompanyInfo."Country/Region Code";


        EReportingDoc."Supplier SIREN" := CompanyInfo."EDoc SIREN";
        EReportingDoc."Supplier SIRET" := CompanyInfo."EDoc SIRET";
        EReportingDoc."Supplier Endpoint" := CompanyInfo."EDoc Endpoint ID";

        EReportingDoc."Counterparty Type" := "EDoc Source Type"::Customer;
        EReportingDoc."Customer No." := Customer."No.";
        EReportingDoc."Customer Name" := Customer.Name;
        EReportingDoc."Customer VAT No." := Customer."VAT Registration No.";
        EReportingDoc."Customer Country" := Customer."Country/Region Code";
        EReportingDoc."Customer VAT No." := Customer."VAT Registration No.";
        EReportingDoc."Customer Address" := Customer.Address;
        EReportingDoc."Customer City" := Customer.City;
        EReportingDoc."Customer Post Code" := Customer."Post Code";
        EReportingDoc."Customer Country" := Customer."Country/Region Code";

        EReportingDoc."Customer SIREN" := Customer."EDoc SIREN";
        EReportingDoc."Customer SIRET" := Customer."EDoc SIRET";

        EReportingDoc."Currency Code" := SalesInvHeader."Currency Code";
        if EReportingDoc."Currency Code" = '' then
            EReportingDoc."Currency Code" := 'EUR';
        EReportingDoc."Tax Currency Code" := EReportingDoc."Currency Code";

        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
        EReportingDoc."Amount Excl. VAT" := SalesInvHeader.Amount;
        EReportingDoc."VAT Amount" := SalesInvHeader."Amount Including VAT" - SalesInvHeader.Amount;
        EReportingDoc."Amount Incl. VAT" := SalesInvHeader."Amount Including VAT";
    end;

    /// <summary>
    /// Resolves VAT rate/category for e-reporting from the invoice's first significant line
    /// (avoids the "average rate" distortion of computing it off header totals).
    /// </summary>
    local procedure ResolveVATRateAndCategory(SalesInvoiceNo: Code[20]; var VATRate: Decimal; var VATCategory: Code[10])
    var
        SalesInvLine: Record "Sales Invoice Line";
        VATCategoryMap: Record "EDoc VAT Category Map";
    begin
        SalesInvLine.SetRange("Document No.", SalesInvoiceNo);
        SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
        SalesInvLine.SetFilter("VAT %", '<>%1', 0);
        if SalesInvLine.FindFirst() then begin
            VATRate := SalesInvLine."VAT %";
            VATCategory := VATCategoryMap.ResolveCategory(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group", VATRate);
            exit;
        end;

        SalesInvLine.SetRange("VAT %");
        if SalesInvLine.FindFirst() then begin
            VATRate := SalesInvLine."VAT %";
            VATCategory := VATCategoryMap.ResolveCategory(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group", VATRate);
            exit;
        end;

        VATRate := 0;
        VATCategory := '';
    end;
}
