codeunit 70122 "EDoc ER Flow 10.2 Builder"
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
        // Flow information
        //-----------------------------------------

        Helper.BuildFlow(
            Xml,
            EDoc);

        //-----------------------------------------
        // Declarant
        //-----------------------------------------

        Helper.BuildSeller(
            Xml,
            CompanyInfo);

        //-----------------------------------------
        // Customer
        //-----------------------------------------

        Helper.BuildCounterparty(
            Xml,
            EDoc);

        //-----------------------------------------
        // Invoice reference
        //-----------------------------------------

        Helper.BuildDocumentReference(
            Xml,
            EDoc);

        //-----------------------------------------
        // Collection information
        //-----------------------------------------

        Helper.BuildCollection(
            Xml,
            EDoc);

        //-----------------------------------------
        // Payment reference
        //-----------------------------------------

        Helper.BuildPaymentReference(
            Xml,
            EDoc);

        Helper.EndTransaction(Xml);

        Helper.CloseTransactions(Xml);

        Helper.EndDocument(Xml);

        exit(Xml.ToText());
    end;
}