codeunit 70114 "SBD Builder"
{
    Access = Internal;

    // Mandatory per Sovos's France invoice-body spec - identifies the input schema/format
    // being submitted. Fixed value for the SCI (Sovos Canonical Invoice) format, version 1.0.
    var
        MappingInputSchemaLbl: Label 'FR-SCI-1.0-INVOICE-1.0', Locked = true;
        BusinessServiceNameLbl: Label 'Default', Locked = true;
        MappingInputSchemaEReportingLbl: Label 'FR-SCI-1.0-EREPORTING-1.0', Locked = true;

    /// <summary>
    /// Wraps a generated Invoice XML in a full StandardBusinessDocument, matching Sovos's
    /// production SBD structure (sbd: prefix, Authority="FR", full BusinessScope block).
    /// </summary>
    procedure BuildSBD(InvoiceXml: Text; EDoc: Record "EDoc Document"): Text
    var
        EDocService: Record "EDoc Service";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Xml: TextBuilder;
        CreationDateTimeTxt: Text;
    begin
        if (EDoc."Service Code" = '') or not EDocService.Get(EDoc."Service Code") then
            SetupMgt.GetDefaultService(EDocService);

        CreationDateTimeTxt := Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>Z');

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        AppendRootOpenTag(Xml);

        AppendHeader(Xml, EDoc, EDocService, CreationDateTimeTxt);

        Xml.AppendLine('<svs:SovosDocument>');
        Xml.AppendLine('<sci:SovosCanonicalInvoice>');
        Xml.Append(InvoiceXml); // embedded as-is: own xmlns, no prefix rewriting
        Xml.AppendLine('</sci:SovosCanonicalInvoice>');
        Xml.AppendLine('</svs:SovosDocument>');

        Xml.AppendLine('</sbd:StandardBusinessDocument>');

        exit(Xml.ToText());
    end;

    local procedure AppendRootOpenTag(var Xml: TextBuilder)
    begin
        // Full namespace set matching Sovos's production example. Several of these (crn, dbn,
        // xades, ds, sac, sbc, ad) aren't used by a plain invoice submission, but are kept to
        // match the reference structure exactly and avoid any strict-validation surprises.
        Xml.AppendLine('<sbd:StandardBusinessDocument ' +
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
            'xmlns="http://uri.etsi.org/01903/v1.4.1#" ' +
            'xmlns:ad="http://www.sovos.com/namespaces/additionalData" ' +
            'xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ' +
            'xmlns:n0="urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2" ' +
            'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
            'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' +
            'xmlns:crn="urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2" ' +
            'xmlns:dbn="urn:oasis:names:specification:ubl:schema:xsd:DebitNote-2" ' +
            'xmlns:enc="http://www.sovos.com/namespaces/base64Document" ' +
            'xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ' +
            'xmlns:inv="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" ' +
            'xmlns:qdt="urn:oasis:names:specification:ubl:schema:xsd:QualifiedDataTypes-2" ' +
            'xmlns:sac="urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2" ' +
            'xmlns:sbc="urn:oasis:names:specification:ubl:schema:xsd:SignatureBasicComponents-2" ' +
            'xmlns:sbd="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader" ' +
            'xmlns:sci="http://www.sovos.com/namespaces/sovosCanonicalInvoice" ' +
            'xmlns:sov="http://www.sovos.com/namespaces/sovosExtensions" ' +
            'xmlns:svs="http://www.sovos.com/namespaces/sovosDocument" ' +
            'xmlns:udt="urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2" ' +
            'xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" ' +
            'xmlns:ccts-cct="urn:un:unece:uncefact:data:specification:CoreComponentTypeSchemaModule:2">');
    end;

    local procedure AppendHeader(var Xml: TextBuilder; EDoc: Record "EDoc Document"; EDocService: Record "EDoc Service"; CreationDateTimeTxt: Text)
    begin
        Xml.AppendLine('<sbd:StandardBusinessDocumentHeader>');
        Xml.AppendLine('<sbd:HeaderVersion>1.0</sbd:HeaderVersion>');

        Xml.AppendLine('<sbd:Sender>');
        Xml.AppendLine('<sbd:Identifier Authority="FR">' + EscapeXml(EDoc."Supplier SIREN") + '</sbd:Identifier>');
        Xml.AppendLine('</sbd:Sender>');

        Xml.AppendLine('<sbd:Receiver>');
        Xml.AppendLine('<sbd:Identifier Authority="FR">' + EscapeXml(EDoc."Customer SIREN") + '</sbd:Identifier>');
        Xml.AppendLine('</sbd:Receiver>');

        Xml.AppendLine('<sbd:DocumentIdentification>');
        Xml.AppendLine('<sbd:Standard>urn:oasis:names:specification:ubl:schema:xsd:Invoice-2</sbd:Standard>');
        Xml.AppendLine('<sbd:TypeVersion>2.1</sbd:TypeVersion>');
        Xml.AppendLine('<sbd:InstanceIdentifier>' + EscapeXml(EDoc."Invoice No.") + '</sbd:InstanceIdentifier>');
        Xml.AppendLine('<sbd:Type>Invoice</sbd:Type>');
        Xml.AppendLine('<sbd:MultipleType>false</sbd:MultipleType>');
        Xml.AppendLine('<sbd:CreationDateAndTime>' + CreationDateTimeTxt + '</sbd:CreationDateAndTime>');
        Xml.AppendLine('</sbd:DocumentIdentification>');

        AppendBusinessScope(Xml, EDoc, EDocService);

        Xml.AppendLine('</sbd:StandardBusinessDocumentHeader>');
    end;

    local procedure AppendBusinessScope(var Xml: TextBuilder; EDoc: Record "EDoc Document"; EDocService: Record "EDoc Service")
    begin
        Xml.AppendLine('<sbd:BusinessScope>');

        AppendScope(Xml, 'Country', EDoc."Supplier Country");
        AppendScope(Xml, 'CompanyCode', EDoc."Supplier SIREN");
        AppendScope(Xml, 'SenderDocumentId', EDoc."Invoice No.");
        AppendScope(Xml, 'SenderSystemId', EDocService."Sender ERP System Id");
        AppendScope(Xml, 'ProcessType', 'Outbound');
        AppendBusinessProcessScope(Xml);
        AppendScope(Xml, 'BusinessCategory', 'B2B');

        if EDocService."Sovos Organization Id" <> '' then
            AppendScope(Xml, 'OrganizationId', EDocService."Sovos Organization Id");

        AppendScope(Xml, 'Mapping.InputSchema', MappingInputSchemaLbl);

        Xml.AppendLine('</sbd:BusinessScope>');
    end;

    local procedure AppendScope(var Xml: TextBuilder; ScopeType: Text; Identifier: Text)
    begin
        Xml.AppendLine('<sbd:Scope>');
        Xml.AppendLine('<sbd:Type>' + ScopeType + '</sbd:Type>');
        Xml.AppendLine('<sbd:InstanceIdentifier/>');
        Xml.AppendLine('<sbd:Identifier>' + EscapeXml(Identifier) + '</sbd:Identifier>');
        Xml.AppendLine('</sbd:Scope>');
    end;

    /// <summary>
    /// BusinessProcess scope has a nested BusinessService/BusinessServiceName instead of a
    /// flat Identifier, so it can't reuse AppendScope.
    /// </summary>
    local procedure AppendBusinessProcessScope(var Xml: TextBuilder)
    begin
        Xml.AppendLine('<sbd:Scope>');
        Xml.AppendLine('<sbd:Type>BusinessProcess</sbd:Type>');
        Xml.AppendLine('<sbd:InstanceIdentifier/>');
        Xml.AppendLine('<sbd:BusinessService>');
        Xml.AppendLine('<sbd:BusinessServiceName>' + BusinessServiceNameLbl + '</sbd:BusinessServiceName>');
        Xml.AppendLine('</sbd:BusinessService>');
        Xml.AppendLine('</sbd:Scope>');
    end;

    /// <summary>
    /// Variante e-reporting de BuildSBD, pour les flux 10.1 (international) et 10.2
    /// (encaissement). Réutilise la même enveloppe StandardBusinessDocument, mais avec
    /// un Mapping.InputSchema et un sbd:Type différents.
    /// À CONFIRMER AVEC SOVOS avant mise en production : la valeur exacte de
    /// Mapping.InputSchema pour l'e-reporting (MappingInputSchemaEReportingLbl ci-dessus
    /// est un nom plausible par analogie avec 'FR-SCI-1.0-INVOICE-1.0', mais n'a pas été
    /// vérifiée dans la documentation Sovos), ainsi que le nom exact du corps XML/JSON
    /// attendu à la place de sci:SovosCanonicalInvoice (ici svs:SovosEReporting, à valider).
    /// </summary>
    procedure BuildEReportingSBD(EReportingXml: Text; EReportingDoc: Record "EDoc Document"): Text
    var
        EDocService: Record "EDoc Service";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Xml: TextBuilder;
        CreationDateTimeTxt: Text;
    begin
        if (EReportingDoc."Service Code" = '') or not EDocService.Get(EReportingDoc."Service Code") then
            SetupMgt.GetDefaultService(EDocService);

        CreationDateTimeTxt := Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>Z');

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        AppendRootOpenTag(Xml);

        AppendEReportingHeader(Xml, EReportingDoc, EDocService, CreationDateTimeTxt);

        // Corps du message - nom de balise à confirmer (placeholder svs:SovosEReporting)
        Xml.AppendLine('<svs:SovosDocument>');
        Xml.AppendLine('<svs:SovosEReporting>');
        Xml.Append(EReportingXml);
        Xml.AppendLine('</svs:SovosEReporting>');
        Xml.AppendLine('</svs:SovosDocument>');

        Xml.AppendLine('</sbd:StandardBusinessDocument>');

        exit(Xml.ToText());
    end;

    local procedure AppendEReportingHeader(var Xml: TextBuilder; EReportingDoc: Record "EDoc Document"; EDocService: Record "EDoc Service"; CreationDateTimeTxt: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        Xml.AppendLine('<sbd:StandardBusinessDocumentHeader>');
        Xml.AppendLine('<sbd:HeaderVersion>1.0</sbd:HeaderVersion>');

        Xml.AppendLine('<sbd:Sender>');
        Xml.AppendLine('<sbd:Identifier Authority="FR">' + EscapeXml(CompanyInfo."EDoc SIREN") + '</sbd:Identifier>');
        Xml.AppendLine('</sbd:Sender>');

        Xml.AppendLine('<sbd:Receiver>');
        Xml.AppendLine('<sbd:Identifier Authority="FR">' + EscapeXml(EReportingDoc."Customer No.") + '</sbd:Identifier>');
        Xml.AppendLine('</sbd:Receiver>');

        Xml.AppendLine('<sbd:DocumentIdentification>');
        // "Standard"/"Type" à confirmer pour l'e-reporting - valeurs placeholder
        Xml.AppendLine('<sbd:Standard>urn:sovos:france:e-reporting</sbd:Standard>');
        Xml.AppendLine('<sbd:TypeVersion>1.0</sbd:TypeVersion>');
        Xml.AppendLine('<sbd:InstanceIdentifier>' + EscapeXml(Format(EReportingDoc."Entry No.")) + '</sbd:InstanceIdentifier>');
        Xml.AppendLine('<sbd:Type>EReporting</sbd:Type>');
        Xml.AppendLine('<sbd:MultipleType>false</sbd:MultipleType>');
        Xml.AppendLine('<sbd:CreationDateAndTime>' + CreationDateTimeTxt + '</sbd:CreationDateAndTime>');
        Xml.AppendLine('</sbd:DocumentIdentification>');

        AppendEReportingBusinessScope(Xml, EReportingDoc, EDocService, CompanyInfo);

        Xml.AppendLine('</sbd:StandardBusinessDocumentHeader>');
    end;

    local procedure AppendEReportingBusinessScope(var Xml: TextBuilder; EReportingDoc: Record "EDoc Document"; EDocService: Record "EDoc Service"; CompanyInfo: Record "Company Information")
    begin
        Xml.AppendLine('<sbd:BusinessScope>');

        AppendScope(Xml, 'Country', CompanyInfo."Country/Region Code");
        AppendScope(Xml, 'CompanyCode', CompanyInfo."EDoc SIREN");
        AppendScope(Xml, 'SenderDocumentId', Format(EReportingDoc."Entry No."));
        AppendScope(Xml, 'SenderSystemId', EDocService."Sender ERP System Id");
        AppendScope(Xml, 'ProcessType', 'Outbound');
        AppendBusinessProcessScope(Xml);
        AppendScope(Xml, 'BusinessCategory', 'B2B');

        if EDocService."Sovos Organization Id" <> '' then
            AppendScope(Xml, 'OrganizationId', EDocService."Sovos Organization Id");

        AppendScope(Xml, 'Mapping.InputSchema', MappingInputSchemaEReportingLbl);

        Xml.AppendLine('</sbd:BusinessScope>');
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
