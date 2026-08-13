// Orchestre l'envoi d'un rapport e-reporting de PÉRIODE : construit le XML métier (flux
// 10.1, 10.2 ou 6), l'enveloppe en SBD, l'envoie à Sovos, puis marque TOUTES les entrées
// "EDoc Document" incluses dans cette période comme Sent.
codeunit 70127 "EDoc ER Send Mgt."
{
    Access = Internal;

    var
        Logger: Codeunit "EDoc Logger";
        Flow101Builder: Codeunit "EDoc ER Flow 10.1 Builder";
        Flow102Builder: Codeunit "EDoc ER Flow 10.2 Builder";
        Flow6Builder: Codeunit "EDoc ER Flow 6 Builder";
        SbdBuilder: Codeunit "EDoc ER SBD Builder";
        SovosClient: Codeunit "Sovos Client";

    /// <summary>
    /// Envoie le flux 10.1 (International) pour toute la période donnée : construit un seul
    /// XML regroupant toutes les factures Pending de la période, l'envoie en un seul appel,
    /// puis marque CHAQUE entrée incluse comme Sent (ou Error si l'envoi échoue).
    /// </summary>
    procedure SendFlow101(StartDate: Date; EndDate: Date; ServiceCode: Code[20])
    var
        EDoc: Record "EDoc Document";
        BodyXml: Text;
        SbdXml: Text;
        SovosDocumentId: Text;
    begin
        EDoc.SetRange("Flow Type", EDoc."Flow Type"::International);
        EDoc.SetRange(Status, EDoc.Status::Pending);
        EDoc.SetRange("Posting Date", StartDate, EndDate);
        if not EDoc.FindSet() then
            Error('No pending flow 10.1 entries found between %1 and %2.', StartDate, EndDate);

        Logger.LogInformation(0,
            StrSubstNo('Starting flow 10.1 e-reporting export for %1 to %2.', StartDate, EndDate),
            'EDoc ER Send Mgt.');

        repeat
            Clear(SovosDocumentId);

            // 1. Génération du XML pour la facture courante
            BodyXml := Flow101Builder.BuildFlow101Xml(EDoc, ServiceCode);

            // 2. Construction du SBD basé sur la date de la facture
            SbdXml := SbdBuilder.BuildEReportingSBD(BodyXml, EDoc."Posting Date", EDoc."Posting Date", ServiceCode);

            // 3. Envoi via Sovos
            SovosClient.SendEReporting(SbdXml, SovosDocumentId);

            // 4. Mise à jour du statut pour cette facture
            MarkEntriesSent(EDoc, SovosDocumentId);

        until EDoc.Next() = 0;

        Logger.LogInformation(0,
            StrSubstNo('Flow 10.1 e-reporting for %1 to %2 sent successfully.', StartDate, EndDate),
            'EDoc ER Send Mgt.');
    end;

    /// <summary>
    /// Envoie le flux 10.2 (Collection/Paiement) pour toute la période donnée.
    /// </summary>
    /*procedure SendFlow102(StartDate: Date; EndDate: Date; ServiceCode: Code[20])
    var
        EDoc: Record "EDoc Document";
        BodyXml: Text;
        SbdXml: Text;
        SovosDocumentId: Text;
    begin
        EDoc.SetRange("Flow Type", EDoc."Flow Type"::Collection);
        EDoc.SetRange(Status, EDoc.Status::Pending);
        EDoc.SetRange("Collection Date", StartDate, EndDate);
        if EDoc.IsEmpty() then
            Error('No pending flow 10.2 entries found between %1 and %2.', StartDate, EndDate);

        Logger.LogInformation(0,
            StrSubstNo('Starting flow 10.2 e-reporting export for %1 to %2.', StartDate, EndDate),
            'EDoc ER Send Mgt.');

        BodyXml := Flow102Builder.BuildFlow102Xml(StartDate, EndDate, ServiceCode);
        SbdXml := SbdBuilder.BuildEReportingSBD(BodyXml, StartDate, EndDate, ServiceCode);
        SovosClient.SendEReporting(SbdXml, SovosDocumentId);

        MarkEntriesSent(EDoc, SovosDocumentId);

        Logger.LogInformation(0,
            StrSubstNo('Flow 10.2 e-reporting for %1 to %2 sent successfully (documentId=%3).', StartDate, EndDate, SovosDocumentId),
            'EDoc ER Send Mgt.');
    end;
*/
    /// <summary>
    /// Envoie le flux 6 (Cycle de Vie / CDV - Encaissée, Déposée, etc.) pour les entrées sélectionnées.
    /// </summary>
    /*procedure SendFlow6(var EDoc: Record "EDoc Document"; ServiceCode: Code[20])
    var
        StatusInfo: Record "EDoc CDV Status Info" temporary;
        VATBuffer: Record "EDoc VAT Buffer" temporary;
        XmlHelper: Codeunit "EDoc ER XML Helper"; // Replace with your exact XML Helper codeunit name if different
        BodyXml: Text;
        SbdXml: Text;
        SovosDocumentId: Text;
    begin
        if EDoc.IsEmpty() then
            Error('No pending flow 6 entries provided.');

        Logger.LogInformation(0, 'Starting flow 6 (Cycle de Vie) export.', 'EDoc ER Send Mgt.');

        // 1. Populate temporary buffers for VAT breakdown and CDV Status Info
        XmlHelper.BuildVATBuffer(EDoc, VATBuffer);
        GetStatusInfo(EDoc, StatusInfo); // Retrieve/populate status info according to your logic

        // 2. Call BuildFlow6Xml with all 3 required formal parameters
        BodyXml := Flow6Builder.BuildFlow6Xml(EDoc, StatusInfo, VATBuffer);

        // 3. Package and dispatch to Sovos
        SbdXml := SbdBuilder.BuildEReportingSBD(BodyXml, WorkDate(), WorkDate(), ServiceCode);
        SovosClient.SendEReporting(SbdXml, SovosDocumentId);

        MarkEntriesSent(EDoc, SovosDocumentId);

        Logger.LogInformation(0,
            StrSubstNo('Flow 6 (Cycle de Vie) sent successfully (documentId=%1).', SovosDocumentId),
            'EDoc ER Send Mgt.');
    end;
*/
    /// <summary>
    /// Marque comme Sent toutes les entrées passées par référence.
    /// Appelé uniquement APRÈS un envoi réussi.
    /// </summary>
    local procedure MarkEntriesSent(var EDoc: Record "EDoc Document"; SovosDocumentId: Text)
    begin
        if EDoc.FindSet(true) then
            repeat
                if SovosDocumentId <> '' then
                    EDoc."Sovos Document Id" := CopyStr(SovosDocumentId, 1, MaxStrLen(EDoc."Sovos Document Id"));
                EDoc.Status := EDoc.Status::Sent;
                EDoc."Sent At" := CurrentDateTime();
                EDoc.Modify(true);
            until EDoc.Next() = 0;
    end;

    local procedure GetStatusInfo(var EDoc: Record "EDoc Document"; var StatusInfo: Record "EDoc CDV Status Info" temporary)
    begin
        StatusInfo.Init();
        StatusInfo."Referenced Document Id" := EDoc."Invoice No.";
        StatusInfo."CDV Document Name" := 'CDV-212_Encaissee';
        StatusInfo."Status Code (UNTDID 1373)" := 47;
        StatusInfo."Document Type Code" := '380';

        // Assign using the Enum value
        StatusInfo."Process Condition Code" := StatusInfo."Process Condition Code"::Encaissee;
        StatusInfo."Process Condition Label" := 'Encaissee';
        StatusInfo."Is Error Status" := false;
        StatusInfo.Insert();
    end;
}