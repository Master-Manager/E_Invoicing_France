codeunit 70130 "EDoc ER Flow 10.1 Pur Builder"
{
    Access = Internal;

    var
        Helper: Codeunit "EDoc ER XML Helper";
        BusinessProcessTypeIdLbl: Label 'urn.cpro.gouv.fr:1p0:ereporting', Locked = true;

    procedure BuildPurchaseFlow101Xml(var EDoc: Record "EDoc Document"; ServiceCode: Code[20]): Text
    var
        CompanyInfo: Record "Company Information";
        EDocService: Record "EDoc Service";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        EDocERBldr: Codeunit "EDoc Sovos EReporting Builder";
        Xml: TextBuilder;
    begin
        EDocERBldr.InitBuffers(EDoc."Entry No.");
        CompanyInfo.Get();
        if (ServiceCode = '') or not EDocService.Get(ServiceCode) then
            SetupMgt.GetDefaultService(EDocService);

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.AppendLine('<Report xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');

        // Bloc 1 : ReportDocument basé sur la date de la facture unique
        Helper.BuildReportDocument(Xml, CompanyInfo, EDoc."Issue Date", EDoc."Issue Date", EDoc);

        // Bloc 2 : TransactionsReport pour cette facture d'achat unique
        BuildPurchaseTransactionsReport(Xml, CompanyInfo, EDocService, EDoc);

        Xml.AppendLine('</Report>');

        exit(Xml.ToText());
    end;

    local procedure BuildPurchaseTransactionsReport(
            var Xml: TextBuilder;
            CompanyInfo: Record "Company Information";
            EDocService: Record "EDoc Service";
            EDoc: Record "EDoc Document")
    begin
        Helper.OpenGroup(Xml, 'TransactionsReport');

        Helper.OpenGroup(Xml, 'ReportPeriod');
        Helper.AddElement(Xml, 'StartDate', Helper.FormatDateShort(EDoc."Issue Date"));
        Helper.AddElement(Xml, 'EndDate', Helper.FormatDateShort(EDoc."Issue Date"));
        Helper.CloseGroup(Xml);

        // Appel de la construction de la facture d'achat unitaire
        BuildPurchaseInvoice(Xml, EDoc, CompanyInfo, EDocService);

        Helper.CloseGroup(Xml); // Fin TransactionsReport
    end;

    local procedure BuildPurchaseInvoice(var Xml: TextBuilder; EDoc: Record "EDoc Document"; CompanyInfo: Record "Company Information"; EDocService: Record "EDoc Service")
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

        Helper.OpenGroup(Xml, 'BusinessProcess');
        Helper.AddElement(Xml, 'ID', 'S1');
        Helper.AddElement(Xml, 'TypeID', BusinessProcessTypeIdLbl);
        Helper.CloseGroup(Xml);

        // In Purchases: Seller is the external vendor, Buyer is your Company Information
        BuildExternalSeller(Xml, EDoc);
        BuildBuyerAsCompany(Xml, CompanyInfo);

        Helper.OpenGroup(Xml, 'MonetaryTotal');
        Helper.AddAmountPlain(Xml, 'TaxExclusiveAmount', EDoc."Amount Excl. VAT");
        Helper.AddAmountWithCurrency(Xml, 'TaxAmount', EDoc."Currency Code", EDoc."VAT Amount");
        Helper.CloseGroup(Xml);

        BuildTaxSubTotal(Xml, EDoc);
        BuildInvoiceLines(Xml, EDoc);

        Helper.CloseGroup(Xml);
    end;

    local procedure BuildExternalSeller(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        Helper.OpenGroup(Xml, 'Seller');
        Helper.AddElementWithAttr(Xml, 'CompanyId', 'schemeId', '0002', EDoc."Supplier SIREN");
        Helper.AddElementWithAttr(Xml, 'TaxRegistrationId', 'qualifyingId', 'VAT', EDoc."Supplier VAT No.");

        Helper.OpenGroup(Xml, 'PostalAddress');
        Helper.AddElement(Xml, 'CountryId', EDoc."Supplier Country");
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
            Helper.OpenGroup(Xml, 'Line');
            Helper.AddElementWithAttr(Xml, 'BilledQuantity', 'UnitCode', 'NAR', Helper.FormatDecimal(Line.Quantity));

            Helper.OpenGroup(Xml, 'Price');
            Helper.AddAmountPlain(Xml, 'PriceAmount', Line."Unit Price");
            Helper.CloseGroup(Xml);

            if Line.Description <> '' then begin
                Helper.OpenGroup(Xml, 'Product');
                Helper.AddElement(Xml, 'Name', Line.Description);
                Helper.CloseGroup(Xml);
            end;

            Helper.CloseGroup(Xml);
        until Line.Next() = 0;
    end;

    procedure BuildBuyerAsCompany(var Xml: TextBuilder; CompanyInfo: Record "Company Information")
    begin
        Helper.OpenGroup(Xml, 'Buyer');
        Helper.AddElementWithAttr(Xml, 'CompanyId', 'schemeId', '0002', CompanyInfo."EDoc SIREN");
        Helper.AddElementWithAttr(Xml, 'TaxRegistrationId', 'qualifyingId', 'VAT', CompanyInfo."VAT Registration No.");

        Helper.OpenGroup(Xml, 'PostalAddress');
        Helper.AddElement(Xml, 'CountryId', CompanyInfo."Country/Region Code");
        Helper.CloseGroup(Xml);

        Helper.CloseGroup(Xml);
    end;
}