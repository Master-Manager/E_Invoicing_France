// NOTE : contrairement à "EDoc Sovos Integration" (invoice), qui appelle SovosClient
// directement sans passer par "SBD Builder" (l'appel à InvoiceBuilder.BuildInvoiceXml y est
// d'ailleurs commenté, donc XmlText part vide - probablement un TODO en cours côté invoice),
// ce codeunit chaîne explicitement les 3 étapes : Builder -> SBD Builder -> Sovos Client.
// Si ce câblage complet convient, il pourrait valoir la peine d'aligner "EDoc Sovos
// Integration" dessus une fois "EDoc Sovos Invoice Builder" prêt à être branché.
codeunit 70119 "EDoc Sovos EReporting Integr."
{
    Access = Internal;

    var
        Logger: Codeunit "EDoc Logger";
        SovosBuilder: Codeunit "EDoc Sovos EReporting Builder";
        SbdBuilder: Codeunit "SBD Builder";
        SovosClient: Codeunit "Sovos Client";

    procedure SendEReportingEntry(var EReportingDoc: Record "EDoc Document")
    var
        BodyXml: Text;
        SbdXml: Text;
        ResponseText: Text;
        SovosDocumentId: Text;
    begin
        Logger.LogInformation(
            0,
            StrSubstNo('Starting e-reporting export for entry %1 (%2).', EReportingDoc."Entry No.", EReportingDoc."Document No."),
            'EDoc Sovos EReporting Integr.');


        BodyXml := SovosBuilder.BuildEReportingXml(EReportingDoc);
        SbdXml := SbdBuilder.BuildEReportingSBD(BodyXml, EReportingDoc);


        ResponseText := SovosClient.SendEReporting(SbdXml, SovosDocumentId);


        if SovosDocumentId <> '' then
            EReportingDoc."Sovos Document Id" := CopyStr(SovosDocumentId, 1, MaxStrLen(EReportingDoc."Sovos Document Id"));

        EReportingDoc.Status := EReportingDoc.Status::Sent;
        EReportingDoc."Sent At" := CurrentDateTime();
        EReportingDoc.Modify(true);

        Logger.LogInformation(
            0,
            StrSubstNo('E-reporting entry %1 successfully sent to Sovos (documentId=%2).', EReportingDoc."Entry No.", SovosDocumentId),
            'EDoc Sovos EReporting Integr.');
    end;

    /// <summary>
    /// Envoie toutes les entrées d'e-reporting au statut "Open", en continuant même si
    /// certaines échouent (chaque échec est loggé individuellement plutôt que d'interrompre
    /// tout le batch quotidien).
    /// </summary>
    procedure SendPendingEntries()
    var
        EReportingDoc: Record "EDoc Document";
        SentCount: Integer;
        ErrorCount: Integer;
    begin
        EReportingDoc.SetRange(Status, EReportingDoc.Status::Pending);
        if EReportingDoc.FindSet(true) then
            repeat
                if TrySendEntry(EReportingDoc) then
                    SentCount += 1
                else
                    ErrorCount += 1;
            until EReportingDoc.Next() = 0;

        Message('Batch e-reporting : %1 entrée(s) transmise(s), %2 en erreur.', SentCount, ErrorCount);
    end;

    [TryFunction]
    local procedure TrySendEntry(var EReportingDoc: Record "EDoc Document")
    begin
        SendEReportingEntry(EReportingDoc);
    end;
}
