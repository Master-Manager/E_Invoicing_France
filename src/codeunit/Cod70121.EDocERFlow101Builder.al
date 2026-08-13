codeunit 70121 "EDoc ER Flow 10.1 Builder"
{
    Access = Internal;

    var
        Helper: Codeunit "EDoc ER XML Helper";
        BusinessProcessTypeIdLbl: Label 'urn.cpro.gouv.fr:1p0:ereporting', Locked = true;
    /*procedure BuildPeriodicFlow101Xml(StartDate: Date; EndDate: Date; ServiceCode: Code[20]): Text
        var
            CompanyInfo: Record "Company Information";
            EDocService: Record "EDoc Service";
            SetupMgt: Codeunit "EDoc Setup Mgt.";
            EDocDoc: Record "EDoc Document";
            Xml: TextBuilder;
            BatchId: Text;
            FormattedNow: Text;
        begin
            CompanyInfo.Get();
            if (ServiceCode = '') or not EDocService.Get(ServiceCode) then
                SetupMgt.GetDefaultService(EDocService);

            Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
            Xml.AppendLine('<Report xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');

            // ==========================================
            // 1. BLOC 1 : REPORT DOCUMENT (Transmission Header)
            // ==========================================
            Helper.OpenGroup(Xml, 'ReportDocument');

            BatchId := StrSubstNo('MC_%1', Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>'));
            Helper.AddElement(Xml, 'Id', BatchId);
            Helper.AddElement(Xml, 'Name', 'REP-' + BatchId);

            FormattedNow := Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>');
            Helper.OpenGroup(Xml, 'IssueDateTime');
            Helper.AddElement(Xml, 'DateTimeString', FormattedNow);
            Helper.CloseGroup(Xml);

            Helper.AddElement(Xml, 'TypeCode', 'IN');

            BuildSender(Xml);
            BuildIssuer(Xml, CompanyInfo);

            Helper.CloseGroup(Xml); // Fin ReportDocument

            // ==========================================
            // 2. BLOC 2 : TRANSACTIONS REPORT (Periodic Multiple Invoices)
            // ==========================================
            Helper.OpenGroup(Xml, 'TransactionsReport');

            Helper.OpenGroup(Xml, 'ReportPeriod');
            Helper.AddElement(Xml, 'StartDate', Format(StartDate, 0, '<Year4><Month,2><Day,2>'));
            Helper.AddElement(Xml, 'EndDate', Format(EndDate, 0, '<Year4><Month,2><Day,2>'));
            Helper.CloseGroup(Xml);

            // Loop through all documents inside the selected period range
            EDocDoc.Reset();
            EDocDoc.SetRange("Issue Date", StartDate, EndDate);
            if EDocDoc.FindSet() then
                repeat
                    BuildInvoice(Xml, EDocDoc, CompanyInfo, EDocService);
                until EDocDoc.Next() = 0;

            Helper.CloseGroup(Xml); // Fin TransactionsReport
            Xml.AppendLine('</Report>');

            exit(Xml.ToText());
        end;
        */
    procedure BuildFlow101Xml(var EDoc: Record "EDoc Document"; ServiceCode: Code[20]): Text
    var
        CompanyInfo: Record "Company Information";
        EDocService: Record "EDoc Service";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Xml: TextBuilder;
        TransId: Text;
        FormattedNow: Text;
    begin
        CompanyInfo.Get();
        if (ServiceCode = '') or not EDocService.Get(ServiceCode) then
            SetupMgt.GetDefaultService(EDocService);

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.AppendLine('<Report xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');

        // ==========================================
        // 1. BLOC 1 : REPORT DOCUMENT
        // ==========================================
        Helper.OpenGroup(Xml, 'ReportDocument');

        TransId := StrSubstNo('MC_%1', EDoc."Entry No.");
        Helper.AddElement(Xml, 'Id', TransId);
        Helper.AddElement(Xml, 'Name', 'REP-' + TransId);

        FormattedNow := Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>');
        Helper.OpenGroup(Xml, 'IssueDateTime');
        Helper.AddElement(Xml, 'DateTimeString', FormattedNow);
        Helper.CloseGroup(Xml);

        Helper.AddElement(Xml, 'TypeCode', 'IN');

        BuildSender(Xml);
        BuildIssuer(Xml, CompanyInfo);

        Helper.CloseGroup(Xml); // Fin ReportDocument (Bloc 1)

        // ==========================================
        // 2. BLOC 2 : TRANSACTIONS REPORT (Contient l'Invoice)
        // ==========================================
        BuildTransactionsReportForSingleInvoice(Xml, CompanyInfo, EDocService, EDoc);

        Xml.AppendLine('</Report>');

        exit(Xml.ToText());
    end;

    local procedure BuildTransactionsReportForSingleInvoice(
            var Xml: TextBuilder;
            CompanyInfo: Record "Company Information";
            EDocService: Record "EDoc Service";
            EDoc: Record "EDoc Document")
    begin
        Helper.OpenGroup(Xml, 'TransactionsReport');

        // Période du rapport basée sur la date de la facture
        Helper.OpenGroup(Xml, 'ReportPeriod');
        Helper.AddElement(Xml, 'StartDate', Helper.FormatDateShort(EDoc."Issue Date"));
        Helper.AddElement(Xml, 'EndDate', Helper.FormatDateShort(EDoc."Issue Date"));
        Helper.CloseGroup(Xml);

        // Génération de la facture unique dans le rapport
        BuildInvoice(Xml, EDoc, CompanyInfo, EDocService);

        Helper.CloseGroup(Xml); // Fin TransactionsReport (Bloc 2)
    end;

    local procedure BuildIssuer(var Xml: TextBuilder; CompanyInfo: Record "Company Information")
    begin
        Helper.OpenGroup(Xml, 'Issuer');
        Helper.AddElementWithAttr(Xml, 'Id', 'schemeId', '0002', CompanyInfo."Registration No.");
        Helper.AddElement(Xml, 'Name', CompanyInfo.Name);
        Helper.AddElement(Xml, 'RoleCode', 'SE');

        // Ajout du bloc URIUniversalCommunication pour correspondre au modèle
        Helper.OpenGroup(Xml, 'URIUniversalCommunication');
        Helper.AddElement(Xml, 'URIID', CompanyInfo."E-Mail");
        Helper.CloseGroup(Xml);

        Helper.CloseGroup(Xml);
    end;

    local procedure BuildSender(var Xml: TextBuilder)
    begin
        Helper.OpenGroup(Xml, 'Sender');
        Helper.AddElementWithAttr(Xml, 'Id', 'schemeId', '0238', '0201');
        Helper.AddElement(Xml, 'Name', 'PDP_0201');
        Helper.AddElement(Xml, 'RoleCode', 'WK');
        Helper.OpenGroup(Xml, 'URIUniversalCommunication');
        Helper.AddElement(Xml, 'URIID', 'PDP_0201@pdp.fr');
        Helper.CloseGroup(Xml);
        Helper.CloseGroup(Xml);
    end;

    local procedure BuildInvoice(var Xml: TextBuilder; EDoc: Record "EDoc Document"; CompanyInfo: Record "Company Information"; EDocService: Record "EDoc Service")
    begin
        Helper.OpenGroup(Xml, 'Invoice');
        Helper.AddElement(Xml, 'ID', EDoc."Invoice No.");
        Helper.AddElement(Xml, 'IssueDate', Helper.FormatDateShort(EDoc."Issue Date"));

        if EDoc."Document Type" = EDoc."Document Type"::CreditMemo then
            Helper.AddElement(Xml, 'TypeCode', '381')
        else
            Helper.AddElement(Xml, 'TypeCode', '380');

        Helper.AddElement(Xml, 'CurrencyCode', EDoc."Currency Code");
        if EDoc."Due Date" <> 0D then
            Helper.AddElement(Xml, 'DueDate', Helper.FormatDateShort(EDoc."Due Date"));

        Helper.BuildInvoiceNotes(Xml, CompanyInfo, EDocService);

        Helper.OpenGroup(Xml, 'BusinessProcess');
        Helper.AddElement(Xml, 'ID', 'S1');
        Helper.AddElement(Xml, 'TypeID', BusinessProcessTypeIdLbl);
        Helper.CloseGroup(Xml);

        // Outbound: Local Company is Seller (SE), External Customer is Buyer (BY) using direct schema tags
        BuildLocalSeller(Xml, CompanyInfo);
        BuildCustomerAsBuyer(Xml, EDoc);
        BuildDelivery(Xml, EDoc);

        Helper.OpenGroup(Xml, 'InvoicePeriod');
        Helper.AddElement(Xml, 'StartDate', Helper.FormatDateShort(EDoc."Issue Date"));
        Helper.AddElement(Xml, 'EndDate', Helper.FormatDateShort(EDoc."Issue Date"));
        Helper.CloseGroup(Xml);

        Helper.OpenGroup(Xml, 'MonetaryTotal');
        Helper.AddAmountPlain(Xml, 'TaxExclusiveAmount', EDoc."Amount Excl. VAT");
        Helper.AddAmountWithCurrency(Xml, 'TaxAmount', EDoc."Currency Code", EDoc."VAT Amount");
        Helper.CloseGroup(Xml);

        BuildTaxSubTotal(Xml, EDoc);
        BuildInvoiceLines(Xml, EDoc);

        Helper.CloseGroup(Xml);
    end;

    local procedure BuildLocalSeller(var Xml: TextBuilder; CompanyInfo: Record "Company Information")
    begin
        // Flow 10 direct Seller element (No AccountingSupplierParty / Party wrappers)
        Helper.OpenGroup(Xml, 'Seller');
        Helper.AddElementWithAttr(Xml, 'CompanyId', 'schemeId', '0002', CompanyInfo."Registration No.");
        Helper.AddElementWithAttr(Xml, 'TaxRegistrationId', 'qualifyingId', 'VAT', CompanyInfo."VAT Registration No.");

        Helper.OpenGroup(Xml, 'PostalAddress');
        Helper.AddElement(Xml, 'CountryId', CompanyInfo."Country/Region Code");
        Helper.CloseGroup(Xml);

        Helper.CloseGroup(Xml);
    end;

    local procedure BuildCustomerAsBuyer(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    var
        SchemeId: Text;
    begin
        SchemeId := Helper.GetBuyerSchemeId(EDoc."Customer Country");
        if SchemeId = '' then
            SchemeId := '0002';

        // Flow 10 direct Buyer element (No AccountingCustomerParty / Party wrappers)
        Helper.OpenGroup(Xml, 'Buyer');
        if EDoc."Customer SIREN" <> '' then
            Helper.AddElementWithAttr(Xml, 'CompanyId', 'schemeId', '0002', EDoc."Customer SIREN")
        else
            Helper.AddElementWithAttr(Xml, 'CompanyId', 'schemeId', SchemeId, EDoc."Customer VAT No.");

        Helper.AddElementWithAttr(Xml, 'TaxRegistrationId', 'qualifyingId', 'VAT', EDoc."Customer VAT No.");

        Helper.OpenGroup(Xml, 'PostalAddress');
        Helper.AddElement(Xml, 'CountryId', EDoc."Customer Country");
        Helper.CloseGroup(Xml);

        Helper.CloseGroup(Xml);
    end;



    local procedure BuildDelivery(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        if (EDoc."Customer Address" = '') and (EDoc."Customer City" = '') then
            exit;

        Helper.OpenGroup(Xml, 'Delivery');
        Helper.OpenGroup(Xml, 'Location');
        Helper.AddElement(Xml, 'LineOne', EDoc."Customer Address");
        Helper.AddElement(Xml, 'CityName', EDoc."Customer City");
        Helper.AddElement(Xml, 'PostalZone', EDoc."Customer Post Code");
        Helper.AddElement(Xml, 'CountryId', EDoc."Customer Country");
        Helper.CloseGroup(Xml);
        Helper.CloseGroup(Xml);
    end;

    local procedure BuildTaxSubTotal(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    var
        VATBuffer: Record "EDoc VAT Buffer" temporary;
    begin
        VATBuffer.Reset();
        VATBuffer.DeleteAll();

        Helper.BuildVATBuffer(EDoc, VATBuffer);
        if VATBuffer.FindSet() then
            repeat
                Helper.OpenGroup(Xml, 'TaxSubTotal');
                Helper.AddAmountPlain(Xml, 'TaxableAmount', VATBuffer."Taxable Amount");
                Helper.AddAmountPlain(Xml, 'TaxAmount', VATBuffer."Tax Amount");

                Helper.OpenGroup(Xml, 'TaxCategory');
                Helper.AddElement(Xml, 'Code', VATBuffer."VAT Category");
                Helper.AddElement(Xml, 'Percent', Helper.FormatDecimal(VATBuffer."VAT %"));

                if VATBuffer."Tax Exemption Reason" <> '' then
                    Helper.AddElement(Xml, 'TaxExemptionReason', VATBuffer."Tax Exemption Reason");
                if VATBuffer."Tax Exemption Code" <> '' then
                    Helper.AddElement(Xml, 'TaxExemptionReasonCode', VATBuffer."Tax Exemption Code");

                Helper.CloseGroup(Xml);
                Helper.CloseGroup(Xml);
            until VATBuffer.Next() = 0;
    end;

    local procedure BuildInvoiceLines(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    var
        Line: Record "EDoc Document Line";
    begin
        if EDoc."Entry No." = 0 then
            exit;

        Line.Reset();
        Line.SetRange("Document Entry No.", EDoc."Entry No.");
        if not Line.FindSet() then
            exit;

        repeat
            if (Line.Quantity <> 0) or (Line."Unit Price" <> 0) then begin
                Helper.OpenGroup(Xml, 'Line');
                Helper.AddElementWithAttr(Xml, 'BilledQuantity', 'UnitCode', 'NAR', Helper.FormatDecimal(Line.Quantity));

                if (Line."Start Date" <> 0D) and (Line."End Date" <> 0D) then begin
                    Helper.OpenGroup(Xml, 'InvoicePeriod');
                    Helper.AddElement(Xml, 'StartDate', Helper.FormatDateShort(Line."Start Date"));
                    Helper.AddElement(Xml, 'EndDate', Helper.FormatDateShort(Line."End Date"));
                    Helper.CloseGroup(Xml);
                end;

                Helper.OpenGroup(Xml, 'Price');
                Helper.AddAmountPlain(Xml, 'PriceAmount', Line."Unit Price");
                Helper.AddAmountPlain(Xml, 'AllowanceChargeAmount', Line."Line Discount Amount");
                Helper.AddAmountPlain(Xml, 'AllowanceChargeBaseAmount', Line."Unit Price");
                Helper.CloseGroup(Xml);

                if Line.Description <> '' then begin
                    Helper.OpenGroup(Xml, 'Product');
                    Helper.AddElement(Xml, 'Name', Line.Description);
                    Helper.CloseGroup(Xml);
                end;

                Helper.CloseGroup(Xml);
            end;
        until Line.Next() = 0;
    end;
}