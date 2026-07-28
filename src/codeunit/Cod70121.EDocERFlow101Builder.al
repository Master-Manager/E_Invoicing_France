codeunit 70121 "EDoc ER Flow 10.1 Builder"
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

        Helper.BuildFlow(
            Xml,
            EDoc);

        Helper.BuildSeller(
            Xml,
            CompanyInfo);

        Helper.BuildBuyer(
            Xml,
            EDoc);

        Helper.BuildInvoice(
            Xml,
            EDoc);

        Helper.BuildVAT(
            Xml,
            EDoc);

        Helper.BuildPayment(
            Xml,
            EDoc);

        Helper.EndTransaction(Xml);

        Helper.CloseTransactions(Xml);

        Helper.EndDocument(Xml);

        exit(Xml.ToText());
    end;
}