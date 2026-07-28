codeunit 70123 "EDoc ER Flow 10.3 Builder"
{
    Access = Internal;

    procedure BuildXml(
        EDoc: Record "EDoc Document"): Text
    var
        CompanyInfo: Record "Company Information";
        Xml: TextBuilder;
        Helper: Codeunit "EDoc ER XML Helper";
    begin
        CompanyInfo.Get();

        Helper.BeginDocument(Xml);

        Helper.BuildHeader(
            Xml,
            CompanyInfo);

        Helper.OpenTransactions(Xml);

        Helper.BeginTransaction(Xml);

        //-----------------------------------------
        // Flow
        //-----------------------------------------

        Helper.BuildFlow(
            Xml,
            EDoc);

        //-----------------------------------------
        // Seller
        //-----------------------------------------

        Helper.BuildSeller(
            Xml,
            CompanyInfo);

        //-----------------------------------------
        // Consumer / Counterparty
        //-----------------------------------------

        Helper.BuildCounterparty(
            Xml,
            EDoc);

        //-----------------------------------------
        // Monetary summary
        //-----------------------------------------

        Helper.BuildMonetarySummary(
            Xml,
            EDoc);

        //-----------------------------------------
        // VAT breakdown
        //-----------------------------------------

        Helper.BuildVAT(
            Xml,
            EDoc);

        //-----------------------------------------
        // Payment
        //-----------------------------------------

        Helper.BuildPayment(
            Xml,
            EDoc);

        Helper.EndTransaction(Xml);

        Helper.CloseTransactions(Xml);

        Helper.EndDocument(Xml);

        exit(Xml.ToText());
    end;
}