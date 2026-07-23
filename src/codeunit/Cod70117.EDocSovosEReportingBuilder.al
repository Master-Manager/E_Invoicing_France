// À CONFIRMER AVEC SOVOS : la structure XML ci-dessous (balises EReportingTransaction/
// Counterparty/MonetaryTotal...) est une proposition raisonnable par analogie avec le
// schéma UBL Invoice déjà utilisé pour le flux 2, mais Sovos documente probablement un
// schéma dédié pour le flux 10 (JSON ou XML propre à l'e-reporting français) qu'il faudra
// obtenir avant la mise en production. Ne pas considérer ce mapping comme définitif.
codeunit 70117 "EDoc Sovos EReporting Builder"
{
    Access = Internal;

    var
        PathStack: List of [Text];

    procedure BuildEReportingXml(EReportingDoc: Record "EDoc Document"): Text
    var
        CompanyInfo: Record "Company Information";
        Xml: TextBuilder;
    begin
        CompanyInfo.Get();
        Clear(PathStack);

        Xml.AppendLine('<EReportingTransaction xmlns="urn:sovos:france:e-reporting:transaction-1">');
        PathStack.Add('EReportingTransaction');

        BuildHeader(Xml, EReportingDoc);
        BuildDeclarant(Xml, CompanyInfo);
        BuildCounterparty(Xml, EReportingDoc);
        BuildMonetaryDetails(Xml, EReportingDoc);

        PathStack.RemoveAt(PathStack.Count);
        Xml.AppendLine('</EReportingTransaction>');

        exit(Xml.ToText());
    end;

    local procedure BuildHeader(var Xml: TextBuilder; EReportingDoc: Record "EDoc Document")
    begin
        AddElement(Xml, 'FlowType', ResolveFlowTypeCode(EReportingDoc."Flow Type"));
        AddElement(Xml, 'SourceDocumentNo', EReportingDoc."Document No.");
        AddElement(Xml, 'TransactionDate', FormatDate(EReportingDoc."Posting Date"));

        if EReportingDoc."Collection Date" <> 0D then
            AddElement(Xml, 'CollectionDate', FormatDate(EReportingDoc."Collection Date"));
    end;

    local procedure BuildDeclarant(var Xml: TextBuilder; CompanyInfo: Record "Company Information")
    begin
        OpenGroup(Xml, 'Declarant');
        AddElement(Xml, 'Name', CompanyInfo.Name);
        AddElement(Xml, 'SIREN', CompanyInfo."EDoc SIREN");
        AddElement(Xml, 'VATNo', CompanyInfo."VAT Registration No.");
        AddElement(Xml, 'CountryCode', CompanyInfo."Country/Region Code");
        CloseGroup(Xml);
    end;

    local procedure BuildCounterparty(var Xml: TextBuilder; EReportingDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Counterparty');
        AddElement(Xml, 'Type', Format(EReportingDoc."Counterparty Type"));
        AddElement(Xml, 'No', EReportingDoc."Customer No.");
        AddElement(Xml, 'Name', EReportingDoc."Customer Name");
        AddElement(Xml, 'VATNo', EReportingDoc."Customer VAT No.");
        AddElement(Xml, 'CountryCode', EReportingDoc."Customer Country");
        CloseGroup(Xml);
    end;

    local procedure BuildMonetaryDetails(var Xml: TextBuilder; EReportingDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'MonetaryDetails');
        AddAmount(Xml, 'AmountExclVAT', EReportingDoc."Currency Code", EReportingDoc."Amount Excl. VAT");
        AddAmount(Xml, 'VATAmount', EReportingDoc."Currency Code", EReportingDoc."VAT Amount");
        AddAmount(Xml, 'AmountInclVAT', EReportingDoc."Currency Code", EReportingDoc."Amount Incl. VAT");
        AddElement(Xml, 'VATRate', FormatDecimal(EReportingDoc."VAT Rate"));
        AddElement(Xml, 'VATCategory', EReportingDoc."VAT Category");
        CloseGroup(Xml);
    end;

    /// <summary>
    /// Code de flux transmis à Sovos - valeurs placeholder ("10.1"/"10.2"/"10.3") en
    /// attendant la nomenclature réelle attendue par l'API.
    /// </summary>
    local procedure ResolveFlowTypeCode(FlowType: Enum "EDoc Flow Type"): Text
    begin
        case FlowType of
            "EDoc Flow Type"::International:
                exit('10.1');
            "EDoc Flow Type"::Collection:
                exit('10.2');
            "EDoc Flow Type"::"B2C Reporting":
                exit('10.3');
            else
                exit(Format(FlowType));
        end;
    end;

    // ----------------------------------------------------------------------
    // Helpers - même pattern que "EDoc Sovos Invoice Builder" (OpenGroup/CloseGroup,
    // AddElement/AddAmount), simplifié : pas de buffer de traçabilité champ par champ ici
    // (à ajouter par la suite si le besoin d'audit XML détaillé se confirme pour l'e-reporting,
    // en réutilisant "EDoc Header XML Buffer" / "EDoc Line XML Buffer").
    // ----------------------------------------------------------------------

    local procedure OpenGroup(var Xml: TextBuilder; Tag: Text)
    begin
        Xml.AppendLine('<' + Tag + '>');
        PathStack.Add(Tag);
    end;

    local procedure CloseGroup(var Xml: TextBuilder)
    var
        Tag: Text;
    begin
        Tag := PathStack.Get(PathStack.Count);
        PathStack.RemoveAt(PathStack.Count);
        Xml.AppendLine('</' + Tag + '>');
    end;

    local procedure AddElement(var Xml: TextBuilder; Element: Text; Value: Text)
    begin
        if Value = '' then
            exit;
        Xml.AppendLine('<' + Element + '>' + EscapeXml(Value) + '</' + Element + '>');
    end;

    local procedure AddAmount(var Xml: TextBuilder; Element: Text; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        Xml.AppendLine('<' + Element + ' currencyID="' + CurrencyCode + '">' + FormatDecimal(Amount) + '</' + Element + '>');
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure FormatDecimal(Value: Decimal): Text
    begin
        exit(ConvertStr(Format(Round(Value, 0.01), 0, 9), ',', '.'));
    end;

    local procedure EscapeXml(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        Value := Value.Replace('"', '&quot;');
        Value := Value.Replace('''', '&apos;');
        exit(Value);
    end;
}
