codeunit 70122 "EDoc ER Flow 10.2 Builder"
{
    Access = Internal;

    var
        XmlHelper: Codeunit "EDoc ER XML Helper";
        Logger: Codeunit "EDoc Logger";

    /// <summary>
    /// Builds periodic B2C payment / collection e-reporting summary (Flux 10.2).
    /// </summary>
    procedure BuildFlow102Xml(StartDate: Date; EndDate: Date; ServiceCode: Code[20]): Text
    var
        CompanyInfo: Record "Company Information";
        EDocService: Record "EDoc Service";
        EDoc: Record "EDoc Document";
        VATBuffer: Record "EDoc VAT Buffer" temporary;
        Xml: TextBuilder;
    begin
        CompanyInfo.Get();
        if ServiceCode <> '' then
            if EDocService.Get(ServiceCode) then;

        EDoc.SetRange("Flow Type", EDoc."Flow Type"::Collection);
        EDoc.SetRange(Status, EDoc.Status::Pending);
        EDoc.SetRange("Collection Date", StartDate, EndDate);

        if EDoc.IsEmpty() then
            Error('No pending flow 10.2 entries found between %1 and %2.', StartDate, EndDate);

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.AppendLine('<rsm:SCRDMCCBDACIResponseMessage xmlns:rsm="urn:un:unece:uncefact:data:standard:SCRDMCCBDACIResponseMessage:100"');
        Xml.AppendLine('  xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"');
        Xml.AppendLine('  xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100">');

        // Header / Exchange Document
        XmlHelper.BuildReportDocument(Xml, CompanyInfo, StartDate, EndDate, EDoc);

        // Body / Transactions Report
        XmlHelper.OpenGroup(Xml, 'TransactionsReport');

        if EDoc.FindSet() then
            repeat
                BuildCollectionTransaction(Xml, EDoc, CompanyInfo, VATBuffer);
            until EDoc.Next() = 0;

        XmlHelper.CloseGroup(Xml); // TransactionsReport

        Xml.AppendLine('</rsm:SCRDMCCBDACIResponseMessage>');

        exit(Xml.ToText());
    end;

    local procedure BuildCollectionTransaction(var Xml: TextBuilder; EDoc: Record "EDoc Document"; CompanyInfo: Record "Company Information"; var VATBuffer: Record "EDoc VAT Buffer" temporary)
    var
        GrossAmount: Decimal;
    begin
        XmlHelper.OpenGroup(Xml, 'ReportedTransaction');

        XmlHelper.AddElement(Xml, 'ID', EDoc."Invoice No.");

        XmlHelper.OpenGroup(Xml, 'FormattedIssueDateTime');
        XmlHelper.AddElementWithAttr(Xml, 'DateTimeString', 'format', '102', XmlHelper.FormatDateShort(EDoc."Collection Date"));
        XmlHelper.CloseGroup(Xml);

        // Seller Info
        XmlHelper.BuildSeller(Xml, EDoc);

        // Multi-tax encaissement breakdown per line/VAT category
        XmlHelper.BuildVATBuffer(EDoc, VATBuffer);

        if VATBuffer.FindSet() then
            repeat
                GrossAmount := VATBuffer."Taxable Amount" + VATBuffer."Tax Amount";

                XmlHelper.OpenGroup(Xml, 'ApplicableTradeSettlementHeaderMonetarySummation');

                XmlHelper.AddAmountWithCustomAttr(Xml, 'LineTotalAmount', 'currencyID', XmlHelper.GetCurrencyCode(EDoc."Currency Code"), VATBuffer."Taxable Amount");
                XmlHelper.AddAmountWithCustomAttr(Xml, 'TaxTotalAmount', 'currencyID', XmlHelper.GetCurrencyCode(EDoc."Currency Code"), VATBuffer."Tax Amount");
                XmlHelper.AddAmountWithCustomAttr(Xml, 'GrandTotalAmount', 'currencyID', XmlHelper.GetCurrencyCode(EDoc."Currency Code"), GrossAmount);

                XmlHelper.OpenGroup(Xml, 'ApplicableTradeTax');
                XmlHelper.AddElement(Xml, 'RateApplicablePercent', XmlHelper.FormatDecimal(VATBuffer."VAT %"));
                XmlHelper.AddElement(Xml, 'CategoryCode', VATBuffer."VAT Category");
                if VATBuffer."Tax Exemption Code" <> '' then
                    XmlHelper.AddElement(Xml, 'ExemptionReasonCode', VATBuffer."Tax Exemption Code");
                XmlHelper.CloseGroup(Xml); // ApplicableTradeTax

                XmlHelper.CloseGroup(Xml); // ApplicableTradeSettlementHeaderMonetarySummation
            until VATBuffer.Next() = 0;

        XmlHelper.CloseGroup(Xml); // ReportedTransaction
    end;
}