codeunit 70124 "EDoc ER Flow 6 Builder"
{
    Access = Public;

    /// <summary>
    /// Génère le XML UN/CEFACT (SCRDMCCBDACIResponseMessage) pour le Flux 6 (Cycle de Vie / CDV).
    /// </summary>
    /// <param name="EDoc">L'en-tête ou le jeu de données EDoc Document</param>
    /// <param name="ServiceCode">Le code service d'intégration (ex: 'SOVOS')</param>
    procedure BuildFlow6Xml(var EDoc: Record "EDoc Document"; var StatusInfo: Record "EDoc CDV Status Info"; var VATBuffer: Record "EDoc VAT Buffer" temporary): Text
    var
        CompanyInfo: Record "Company Information";
        Xml: TextBuilder;
    begin
        // Règle P1.18 / G7.45 : pour le statut Encaissée (212), la ventilation par taux de
        // TVA (MDT-224) est obligatoire, sinon le PPF rejette le cycle de vie.
        if StatusInfo."Process Condition Code" = StatusInfo."Process Condition Code"::Encaissee then
            if VATBuffer.IsEmpty() then
                Error('La ventilation par taux de TVA est obligatoire pour le statut Encaissée (Règle P1.18).');

        CompanyInfo.Get();

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.AppendLine('<rsm:CrossDomainAcknowledgementAndResponse');
        Xml.AppendLine('  xmlns:qdt="urn:un:unece:uncefact:data:standard:QualifiedDataType:100"');
        Xml.AppendLine('  xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100"');
        Xml.AppendLine('  xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"');
        Xml.AppendLine('  xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100"');
        Xml.AppendLine('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');

        // --- CONTROLE DU PROCESSUS (MDB-1) - obligatoire, une seule fois pour le message ---
        BuildExchangedDocumentContext(Xml);

        // --- DOCUMENT D'ECHANGE (MDB-2) - obligatoire, une seule fois pour le message ---
        BuildExchangedDocument(Xml, CompanyInfo, EDoc);

        // --- DOCUMENT REPONSE (MDB-03) - 1..n : un bloc AcknowledgementDocument PAR document ---
        if EDoc.FindSet() then
            repeat
                BuildAcknowledgementDocument(Xml, EDoc, StatusInfo, VATBuffer);
            until EDoc.Next() = 0
        else
            BuildAcknowledgementDocument(Xml, EDoc, StatusInfo, VATBuffer);

        Xml.AppendLine('</rsm:SCRDMCCBDACIResponseMessage>');

        exit(Xml.ToText());
    end;

    local procedure BuildExchangedDocumentContext(var Xml: TextBuilder)
    begin
        Xml.AppendLine('  <rsm:ExchangedDocumentContext>');

        // MDG-2/MDT-2 : Type de processus métier (cadre de facturation) - optionnel (variante)
        // TODO: confirm the business process ID value expected here for Flux 6, if applicable.

        // MDG-3/MDT-3 : Références spécifications - OBLIGATOIRE
        // Précise le profil du message CDV (e-invoicing, e-reporting, annuaire...).
        Xml.AppendLine('    <ram:GuidelineSpecifiedDocumentContextParameter>');
        Xml.AppendLine('      <ram:ID>urn:cdv:flux6:v2.2</ram:ID>'); // TODO: confirm exact profile ID with SOVOS/PPF docs
        Xml.AppendLine('    </ram:GuidelineSpecifiedDocumentContextParameter>');

        Xml.AppendLine('  </rsm:ExchangedDocumentContext>');
    end;

    local procedure BuildExchangedDocument(var Xml: TextBuilder; CompanyInfo: Record "Company Information"; var EDoc: Record "EDoc Document")
    var
        Cust: Record Customer;
    begin
        Xml.AppendLine('  <rsm:ExchangedDocument>');

        // MDT-4 / MDT-5 : Id + Nom du message CDV - OBLIGATOIRES
        // TODO: replace with a real no. series / sequence instead of CreateGuid().
        Xml.AppendLine(StrSubstNo('    <ram:ID>%1</ram:ID>', EscapeXml(DelChr(Format(CreateGuid()), '=', '{}'))));
        Xml.AppendLine('    <ram:Name>CDV-212_Encaissee</ram:Name>');

        // MDG-4/MDT-8(-1) : Horodatage - OBLIGATOIRE, format UNTDID 2379 = 204 (AAAAMMJJHHMMSS)
        Xml.AppendLine('    <ram:IssueDateTime>');
        Xml.AppendLine(StrSubstNo('      <udt:DateTimeString format="204">%1</udt:DateTimeString>', FormatDateTime204(CurrentDateTime)));
        Xml.AppendLine('    </ram:IssueDateTime>');

        // MDG-9 : Emetteur (flux) - OBLIGATOIRE. GlobalID+schemeID + RoleCode sont requis.
        // TODO: source the real GlobalID (SIREN/SIRET) and scheme (ICD 6523, ex 0009=SIRET,
        // 0002=SIREN) from Company Information or a dedicated e-invoicing setup table -
        // Company Information has no SIREN/SIRET field by default in this snippet.
        Xml.AppendLine('    <ram:SenderTradeParty>');
        Xml.AppendLine(StrSubstNo('      <ram:GlobalID schemeID="0009">%1</ram:GlobalID>', '0201'));
        Xml.AppendLine(StrSubstNo('      <ram:Name>%1</ram:Name>', EscapeXml('PDP_0201')));
        Xml.AppendLine('      <ram:RoleCode>WK</ram:RoleCode>'); // WK = plateforme/opérateur de dématérialisation
        Xml.AppendLine('    </ram:SenderTradeParty>');

        if Cust.Get(EDoc."Customer No.") then;

        // MDG-16 : Emetteur (document) - OBLIGATOIRE (bloc), GlobalID+RoleCode requis (MDT-38/40)
        Xml.AppendLine('    <ram:IssuerTradeParty>');
        Xml.AppendLine(StrSubstNo('      <ram:GlobalID schemeID="0009">%1</ram:GlobalID>', EscapeXml(CompanyInfo."EDoc SIRET")));
        Xml.AppendLine(StrSubstNo('      <ram:Name>%1</ram:Name>', EscapeXml(CompanyInfo.Name)));
        Xml.AppendLine('      <ram:RoleCode>SE</ram:RoleCode>'); // SE = Vendeur ; adapter si besoin
        Xml.AppendLine('    </ram:IssuerTradeParty>');

        // MDG-23 : Destinataire - OBLIGATOIRE (bloc)
        // TODO: this should be the recipient of the CDV message itself (e.g. the PPF or the
        // platform that sent the original invoice) - not necessarily the customer on EDoc.
        Xml.AppendLine('    <ram:RecipientTradeParty>');
        Xml.AppendLine(StrSubstNo('      <ram:GlobalID schemeID="0009">%1</ram:GlobalID>', EscapeXml(Cust."EDoc SIRET")));
        Xml.AppendLine(StrSubstNo('      <ram:Name>%1</ram:Name>', EscapeXml(Cust.Name)));
        Xml.AppendLine('      <ram:RoleCode>BY</ram:RoleCode>');
        Xml.AppendLine('    </ram:RecipientTradeParty>');

        Xml.AppendLine('  </rsm:ExchangedDocument>');
    end;

    local procedure BuildAcknowledgementDocument(var Xml: TextBuilder; var EDoc: Record "EDoc Document"; var StatusInfo: Record "EDoc CDV Status Info" temporary; var VATBuffer: Record "EDoc VAT Buffer" temporary)
    begin
        Xml.AppendLine('  <rsm:AcknowledgementDocument>');

        // MDG-30/MDT-74 : Indicateur MONO/MULTI document - OBLIGATOIRE
        // 'false' = ce bloc AcknowledgementDocument porte sur un document unique.
        Xml.AppendLine('    <ram:MultipleReferencesIndicator>');
        Xml.AppendLine('      <udt:Indicator>false</udt:Indicator>');
        Xml.AppendLine('    </ram:MultipleReferencesIndicator>');

        // MDG-31/MDT-78(-1) : Horodatage du statut - OBLIGATOIRE
        Xml.AppendLine('    <ram:IssueDateTime>');
        Xml.AppendLine(StrSubstNo('      <udt:DateTimeString format="204">%1</udt:DateTimeString>', FormatDateTime204(CurrentDateTime)));
        Xml.AppendLine('    </ram:IssueDateTime>');

        // MDG-32 : Objet de la réponse - OBLIGATOIRE (1..1 par AcknowledgementDocument)
        BuildReferenceReferencedDocument(Xml, EDoc, StatusInfo, VATBuffer);

        Xml.AppendLine('  </rsm:AcknowledgementDocument>');
    end;

    local procedure BuildReferenceReferencedDocument(var Xml: TextBuilder; var EDoc: Record "EDoc Document"; var StatusInfo: Record "EDoc CDV Status Info" temporary; var VATBuffer: Record "EDoc VAT Buffer" temporary)
    begin
        Xml.AppendLine('    <ram:ReferenceReferencedDocument>');

        // MDT-87 : IssuerAssignedID - OBLIGATOIRE - ID du flux ou n° de facture référencé
        Xml.AppendLine(StrSubstNo('      <ram:IssuerAssignedID>%1</ram:IssuerAssignedID>', EscapeXml(EDoc."Invoice No.")));

        // MDT-91 : TypeCode - OBLIGATOIRE - (380 : Facture / 381 / 386 ...)
        // TODO: confirm 380 is always right for this flow, or derive from EDoc document type.
        Xml.AppendLine('      <ram:TypeCode>380</ram:TypeCode>');

        // MDG-34/MDT-95(-1) : ReceiptDateTime - date de réception de l'objet référencé
        Xml.AppendLine('      <ram:ReceiptDateTime>');
        Xml.AppendLine(StrSubstNo('        <udt:DateTimeString format="204">%1</udt:DateTimeString>', FormatDateTime204(CreateDateTime(WorkDate(), 0T))));
        Xml.AppendLine('      </ram:ReceiptDateTime>');

        // MDG-35/MDT-100(-1) : FormattedIssueDateTime
        Xml.AppendLine('      <ram:FormattedIssueDateTime>');
        Xml.AppendLine(StrSubstNo('        <udt:DateTimeString format="102">%1</udt:DateTimeString>', Format(WorkDate(), 0, '<Year4><Month,2><Day,2>')));
        Xml.AppendLine('      </ram:FormattedIssueDateTime>');

        // MDT-105(-1) : ProcessConditionCode - OBLIGATOIRE - une seule fois par document référencé
        // (ex: 212 = Encaissée, 200 = Déposée, 210 = Refusée, 213 = Rejetée - cf. onglet "Statuts")
        Xml.AppendLine(StrSubstNo('      <ram:ProcessConditionCode >%1</ram:ProcessConditionCode>', Format(StatusInfo."Status Code (UNTDID 1373)")));

        // MDT-106 : ProcessCondition - libellé optionnel du statut
        if StatusInfo."Process Condition Code" = StatusInfo."Process Condition Code"::Encaissee then
            Xml.AppendLine('      <ram:ProcessCondition>Encaissee</ram:ProcessCondition>');

        // MDG-37 : SpecifiedDocumentStatus (0..n) - ventilation TVA, uniquement pour Encaissée (212)
        if StatusInfo."Process Condition Code" = StatusInfo."Process Condition Code"::Encaissee then
            BuildVATStatusLines(Xml, EDoc, VATBuffer);

        Xml.AppendLine('    </ram:ReferenceReferencedDocument>');
    end;

    local procedure BuildVATStatusLines(var Xml: TextBuilder; var EDoc: Record "EDoc Document"; var VATBuffer: Record "EDoc VAT Buffer" temporary)
    var
        SeqNo: Integer;
    begin
        SeqNo := 0;
        if VATBuffer.FindSet() then
            repeat
                SeqNo += 1;
                Xml.AppendLine('      <ram:SpecifiedDocumentStatus>');

                // MDT-124-2 : SequenceNumeric - OBLIGATOIRE (numéro incrémental)
                Xml.AppendLine(StrSubstNo('        <ram:SequenceNumeric>%1</ram:SequenceNumeric>', SeqNo));

                Xml.AppendLine('        <ram:SpecifiedDocumentCharacteristic>');

                // MDT-207 : TypeCode = MEN (montant encaissé)
                Xml.AppendLine('          <ram:TypeCode>MEN</ram:TypeCode>');

                // MDT-208/209 : ValueChangedIndicator
                Xml.AppendLine('          <ram:ValueChangedIndicator>');
                Xml.AppendLine('            <udt:IndicatorString>false</udt:IndicatorString>');
                Xml.AppendLine('          </ram:ValueChangedIndicator>');

                // MDT-215/216 : ValueAmount + devise - montant encaissé pour ce taux de TVA
                Xml.AppendLine(StrSubstNo('          <ram:ValueAmount currencyID="%1">%2</ram:ValueAmount>',
                    EscapeXml(EDoc."Currency Code"),
                    Format(VATBuffer."Taxable Amount" + VATBuffer."Tax Amount", 0, '<Precision,2:2><Standard Format,0>')));

                // MDT-224 : ValuePercent - taux de TVA applicable (règle P1.18 : requis si montant renseigné)
                Xml.AppendLine(StrSubstNo('          <ram:ValuePercent>%1</ram:ValuePercent>',
                    Format(VATBuffer."VAT %", 0, '<Precision,2:2><Standard Format,0>')));

                Xml.AppendLine('        </ram:SpecifiedDocumentCharacteristic>');
                Xml.AppendLine('      </ram:SpecifiedDocumentStatus>');
            until VATBuffer.Next() = 0;
    end;

    /// <summary>
    /// Initialise un enregistrement StatusInfo temporaire pour un statut Encaissée (212).
    /// </summary>
    procedure GetStatusInfo(EDoc: Record "EDoc Document"; var StatusInfo: Record "EDoc CDV Status Info" temporary)
    begin
        StatusInfo.Init();
        StatusInfo."Referenced Document Id" := EDoc."Invoice No.";
        StatusInfo."Process Condition Code" := StatusInfo."Process Condition Code"::Encaissee;
        StatusInfo."Status Code (UNTDID 1373)" := 212;
        StatusInfo.Insert();
    end;

    /// <summary>
    /// Construit la ventilation TVA (VATBuffer) à partir des lignes EDoc, agrégée par taux.
    /// </summary>
    procedure BuildVATBufferFromEDoc(EDoc: Record "EDoc Document"; var VATBuffer: Record "EDoc VAT Buffer" temporary)
    var
        EDocLine: Record "EDoc Document Line";
        NextEntryNo: Integer;
    begin
        EDocLine.SetRange("Document Entry No.", EDoc."Entry No.");
        if EDocLine.FindSet() then
            repeat
                // Check if this VAT Category and VAT % combination already exists in the buffer
                VATBuffer.Reset();
                VATBuffer.SetRange("VAT Category", EDocLine."VAT Category");
                VATBuffer.SetRange("VAT %", EDocLine."VAT %");
                if VATBuffer.FindFirst() then begin
                    // Update existing accumulated amounts
                    VATBuffer."Taxable Amount" += EDocLine."Taxable Amount";
                    VATBuffer."Tax Amount" += EDocLine."Tax Amount";
                    VATBuffer.Modify();
                end else begin
                    // Determine the next Entry No. for the primary key
                    VATBuffer.Reset();
                    if VATBuffer.FindLast() then
                        NextEntryNo := VATBuffer."Entry No." + 1
                    else
                        NextEntryNo := 1;

                    // Insert a new unique buffer line
                    VATBuffer.Init();
                    VATBuffer."Entry No." := NextEntryNo;
                    VATBuffer."VAT Category" := EDocLine."VAT Category";
                    VATBuffer."VAT %" := EDocLine."VAT %";
                    VATBuffer."Taxable Amount" := EDocLine."Taxable Amount";
                    VATBuffer."Tax Amount" := EDocLine."Tax Amount";
                    VATBuffer.Insert();
                end;
            until EDocLine.Next() = 0;
    end;

    /// <summary>
    /// Formatte une date-heure au format UNTDID 2379 = 204 (AAAAMMJJHHMMSS).
    /// </summary>
    local procedure FormatDateTime204(DT: DateTime): Text
    begin
        exit(Format(DT, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
    end;

    /// <summary>
    /// Echappe les caractères XML spéciaux pour toute donnée injectée depuis BC.
    /// </summary>
    local procedure EscapeXml(InText: Text): Text
    begin
        InText := InText.Replace('&', '&amp;');
        InText := InText.Replace('<', '&lt;');
        InText := InText.Replace('>', '&gt;');
        InText := InText.Replace('"', '&quot;');
        InText := InText.Replace('''', '&apos;');
        exit(InText);
    end;
}