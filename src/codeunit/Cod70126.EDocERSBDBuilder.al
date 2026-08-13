
codeunit 70126 "EDoc ER SBD Builder"
{
    Access = Internal;

    var
        MappingInputSchemaEReportingLbl: Label 'FR-SCI-1.0-EREPORTING-1.0', Locked = true;

    procedure BuildEReportingSBD(EReportingXml: Text; StartDate: Date; EndDate: Date; ServiceCode: Code[20]): Text
    var
        EDocService: Record "EDoc Service";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Xml: TextBuilder;
        CreationDateTimeTxt: Text;
    begin
        if (ServiceCode = '') or not EDocService.Get(ServiceCode) then
            SetupMgt.GetDefaultService(EDocService);

        CreationDateTimeTxt := Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>Z');

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        AppendRootOpenTag(Xml);

        AppendEReportingHeader(Xml, StartDate, EndDate, EDocService, CreationDateTimeTxt);

        // Body payload - embed the generated Flux 10.1 <Report> directly inside <svs:SovosDocument>
        Xml.AppendLine('<svs:SovosDocument>');
        Xml.Append(EReportingXml);
        Xml.AppendLine('</svs:SovosDocument>');

        Xml.AppendLine('</sbd:StandardBusinessDocument>');

        exit(Xml.ToText());
    end;

    local procedure AppendRootOpenTag(var Xml: TextBuilder)
    begin
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

    local procedure AppendEReportingHeader(var Xml: TextBuilder; StartDate: Date; EndDate: Date; EDocService: Record "EDoc Service"; CreationDateTimeTxt: Text)
    var
        CompanyInfo: Record "Company Information";
        TransmissionId: Text;
        TimePart: Text;
        GuidPart: Text;
    begin
        CompanyInfo.Get();

        // Safe time formatting without unsupported <Milliseconds> tag
        TimePart := Format(CurrentDateTime(), 0, '<Hours24,2><Minutes,2><Seconds,2>');
        GuidPart := CopyStr(DelChr(Format(CreateGuid()), '<>', '{}'), 1, 6);
        TransmissionId := 'MC_' + FormatDateShort(StartDate) + FormatDateShort(EndDate) + '_' + TimePart + '_' + GuidPart;

        Xml.AppendLine('<sbd:StandardBusinessDocumentHeader>');
        Xml.AppendLine('<sbd:HeaderVersion>1.0</sbd:HeaderVersion>');

        Xml.AppendLine('<sbd:Sender>');
        Xml.AppendLine('<sbd:Identifier Authority="FR">' + EscapeXml(CompanyInfo."EDoc SIREN") + '</sbd:Identifier>');
        Xml.AppendLine('</sbd:Sender>');

        // Receiver PDP identifier
        Xml.AppendLine('<sbd:Receiver>');
        Xml.AppendLine('<sbd:Identifier Authority="FR">PDP_0201</sbd:Identifier>');
        Xml.AppendLine('</sbd:Receiver>');

        Xml.AppendLine('<sbd:DocumentIdentification>');
        Xml.AppendLine('<sbd:Standard>urn:sovos:france:e-reporting</sbd:Standard>');
        Xml.AppendLine('<sbd:TypeVersion>1.0</sbd:TypeVersion>');
        Xml.AppendLine('<sbd:InstanceIdentifier>' + EscapeXml(TransmissionId) + '</sbd:InstanceIdentifier>');
        Xml.AppendLine('<sbd:Type>EReporting</sbd:Type>');
        Xml.AppendLine('<sbd:MultipleType>true</sbd:MultipleType>');
        Xml.AppendLine('<sbd:CreationDateAndTime>' + CreationDateTimeTxt + '</sbd:CreationDateAndTime>');
        Xml.AppendLine('</sbd:DocumentIdentification>');

        AppendEReportingBusinessScope(Xml, TransmissionId, EDocService, CompanyInfo);

        Xml.AppendLine('</sbd:StandardBusinessDocumentHeader>');
    end;

    local procedure AppendEReportingBusinessScope(var Xml: TextBuilder; TransmissionId: Text; EDocService: Record "EDoc Service"; CompanyInfo: Record "Company Information")
    begin
        Xml.AppendLine('<sbd:BusinessScope>');

        AppendScope(Xml, 'Country', CompanyInfo."Country/Region Code");
        AppendScope(Xml, 'CompanyCode', CompanyInfo."EDoc SIREN");
        AppendScope(Xml, 'SenderDocumentId', TransmissionId);
        AppendScope(Xml, 'SenderSystemId', EDocService."Sender ERP System Id");
        AppendScope(Xml, 'ProcessType', 'Outbound');
        AppendBusinessProcessScope(Xml);
        AppendScope(Xml, 'BusinessCategory', 'B2B');

        if EDocService."Sovos Organization Id" <> '' then
            AppendScope(Xml, 'OrganizationId', EDocService."Sovos Organization Id");

        // Declares FR-SCI-1.0-EREPORTING-1.0
        AppendScope(Xml, 'Mapping.InputSchema', MappingInputSchemaEReportingLbl);

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

    local procedure AppendBusinessProcessScope(var Xml: TextBuilder)
    begin
        Xml.AppendLine('<sbd:Scope>');
        Xml.AppendLine('<sbd:Type>BusinessProcess</sbd:Type>');
        Xml.AppendLine('<sbd:InstanceIdentifier/>');
        Xml.AppendLine('<sbd:BusinessService>');
        Xml.AppendLine('<sbd:BusinessServiceName>Default</sbd:BusinessServiceName>');
        Xml.AppendLine('</sbd:BusinessService>');
        Xml.AppendLine('</sbd:Scope>');
    end;

    local procedure FormatDateShort(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Year4><Month,2><Day,2>'));
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