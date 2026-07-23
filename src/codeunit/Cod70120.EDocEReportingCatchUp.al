codeunit 70120 "EDoc EReporting Catch-Up"
{
    Access = Internal;

    /// <summary>
    /// Parcourt les factures historiques validées sur une période donnée 
    /// et génère les entrées d'e-reporting manquantes UNIQUEMENT si le N° de TVA est renseigné.
    /// </summary>
    procedure CatchUpPostedInvoices(FromDate: Date; ToDate: Date)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        EReportingDoc: Record "EDoc Document";
        FlowCategorization: Codeunit "EDoc Flow Categorization";
        EReportingImportMgt: Codeunit "EDoc Import Mgt.";
        CreatedCount: Integer;
    begin
        // 1. Filtrer sur la période souhaitée et EXCLURE les N° de TVA vides ('')
        SalesInvHeader.SetRange("Posting Date", FromDate, ToDate);
        SalesInvHeader.SetFilter("VAT Registration No.", '<>%1', '');

        if SalesInvHeader.FindSet() then
            repeat
                // 2. Vérifier si la facture relève bien de l'E-Reporting
                // (On exclut le B2B France qui va en E-Invoicing)
                if FlowCategorization.CategorizeSalesInvoice(SalesInvHeader) <> "EDoc Flow Type"::"Flux 2 - Invoicing" then begin

                    // 3. Vérifier si l'enregistrement n'existe pas déjà dans votre page
                    EReportingDoc.SetRange("Table ID", Database::"Sales Invoice Header");
                    EReportingDoc.SetRange("Document No.", SalesInvHeader."No.");


                    if EReportingDoc.IsEmpty() then begin
                        // 4. Si elle n'existe pas, on l'insère (Statut Pending)
                        Clear(EReportingDoc);
                        EReportingImportMgt.ImportInternationalSalesInvoice(SalesInvHeader."No.", EReportingDoc);
                        CreatedCount += 1;
                    end;
                end;
            until SalesInvHeader.Next() = 0;

        Message('%1 facture(s) historique(s) avec TVA ont été ajoutée(s) à la page E-Reporting.', CreatedCount);
    end;
}
