codeunit 70135 "EDoc Payment Status Builder"
{
    Access = Internal;

    procedure BuildXml(
        EDoc: Record "EDoc Document"): Text
    var
        Xml: TextBuilder;
    begin
        BeginDocument(Xml);

        BuildContext(Xml);


        BuildExchangedDocument(Xml, EDoc);
        BuildAcknowledgement(Xml, EDoc);

        EndDocument(Xml);

        exit(Xml.ToText());
    end;


    local procedure BeginDocument(var Xml: TextBuilder)
    begin
        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');

        Xml.AppendLine(
            '<rsm:CrossDomainAcknowledgementAndResponse ' +
            'xmlns:qdt="urn:un:unece:uncefact:data:standard:QualifiedDataType:100" ' +
            'xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100" ' +
            'xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100" ' +
            'xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100" ' +
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
    end;


    local procedure BuildContext(var Xml: TextBuilder)
    begin
        Xml.AppendLine('  <rsm:ExchangedDocumentContext>');

        Xml.AppendLine('    <ram:BusinessProcessSpecifiedDocumentContextParameter>');
        Xml.AppendLine('      <ram:ID>REGULATED</ram:ID>');
        Xml.AppendLine('    </ram:BusinessProcessSpecifiedDocumentContextParameter>');

        Xml.AppendLine('    <ram:GuidelineSpecifiedDocumentContextParameter>');
        Xml.AppendLine('      <ram:ID>urn.cpro.gouv.fr:1p0:CDV:invoice</ram:ID>');
        Xml.AppendLine('    </ram:GuidelineSpecifiedDocumentContextParameter>');

        Xml.AppendLine('  </rsm:ExchangedDocumentContext>');
    end;

    local procedure BuildExchangedDocument(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        Xml.AppendLine('  <rsm:ExchangedDocument>');

        BuildDocumentIdentification(Xml, EDoc);

        BuildSender(Xml);

        BuildIssuer(Xml, EDoc);

        BuildRecipient(Xml, EDoc);

        Xml.AppendLine('  </rsm:ExchangedDocument>');
    end;

    local procedure BuildDocumentIdentification(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        Xml.AppendLine(
            StrSubstNo(
                '    <ram:ID>%1</ram:ID>',
                EDoc."Invoice No." + '_CDV-212'));

        Xml.AppendLine(
            '    <ram:Name>CDV-212_Encaissee</ram:Name>');

        Xml.AppendLine('    <ram:IssueDateTime>');

        Xml.AppendLine(
            StrSubstNo(
                '      <udt:DateTimeString format="204">%1</udt:DateTimeString>',
                FormatDateTime204(CurrentDateTime)));

        Xml.AppendLine('    </ram:IssueDateTime>');
    end;

    local procedure BuildSender(
        var Xml: TextBuilder)
    begin
        Xml.AppendLine('    <ram:SenderTradeParty>');
        Xml.AppendLine('      <ram:RoleCode>WK</ram:RoleCode>');
        Xml.AppendLine('    </ram:SenderTradeParty>');
    end;

    local procedure BuildIssuer(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        Xml.AppendLine('    <ram:IssuerTradeParty>');

        Xml.AppendLine(
            StrSubstNo(
                '      <ram:GlobalID schemeID="0002">%1</ram:GlobalID>',
                EDoc."Supplier SIREN"));

        Xml.AppendLine(
            StrSubstNo(
                '      <ram:Name>%1</ram:Name>',
                XmlEscape(EDoc."Supplier Name")));

        Xml.AppendLine('      <ram:RoleCode>SE</ram:RoleCode>');

        Xml.AppendLine('    </ram:IssuerTradeParty>');
    end;

    local procedure BuildRecipient(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        Xml.AppendLine('    <ram:RecipientTradeParty>');

        Xml.AppendLine(
            StrSubstNo(
                '      <ram:GlobalID schemeID="0009">%1</ram:GlobalID>',
                EDoc."Customer SIRET"));

        Xml.AppendLine(
            StrSubstNo(
                '      <ram:Name>%1</ram:Name>',
                XmlEscape(EDoc."Customer Name")));

        Xml.AppendLine('      <ram:RoleCode>BY</ram:RoleCode>');

        Xml.AppendLine('      <ram:URIUniversalCommunication>');

        Xml.AppendLine(
            StrSubstNo(
                '        <ram:URIID schemeID="0225">%1</ram:URIID>',
                EDoc."Customer Endpoint"));

        Xml.AppendLine('      </ram:URIUniversalCommunication>');

        Xml.AppendLine('    </ram:RecipientTradeParty>');
    end;

    local procedure FormatDateTime204(Value: DateTime): Text
    begin
        exit(
            Format(
                Value,
                0,
                '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
    end;

    local procedure XmlEscape(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        Value := Value.Replace('"', '&quot;');
        exit(Value);
    end;


    local procedure BuildAcknowledgement(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        Xml.AppendLine('    <ram:AcknowledgementDocument>');

        BuildReferencedInvoice(Xml, EDoc);

        BuildStatusInformation(Xml, EDoc);

        Xml.AppendLine('    </ram:AcknowledgementDocument>');
    end;

    local procedure BuildReferencedInvoice(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        Xml.AppendLine('      <ram:ReferencedDocument>');

        Xml.AppendLine(
            StrSubstNo(
                '        <ram:IssuerAssignedID>%1</ram:IssuerAssignedID>',
                EDoc."Invoice No."));

        if EDoc."Posting Date" <> 0D then begin

            Xml.AppendLine('        <ram:FormattedIssueDateTime>');

            Xml.AppendLine(
                StrSubstNo(
                    '          <qdt:DateTimeString format="102">%1</qdt:DateTimeString>',
                    FormatDate102(EDoc."Posting Date")));

            Xml.AppendLine('        </ram:FormattedIssueDateTime>');

        end;

        Xml.AppendLine('      </ram:ReferencedDocument>');
    end;

    local procedure BuildStatusInformation(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        Xml.AppendLine('      <ram:AcknowledgementStatus>');

        Xml.AppendLine('        <ram:StatusCode>47</ram:StatusCode>');

        Xml.AppendLine('        <ram:ProcessSpecifiedStatusCondition>');

        Xml.AppendLine('          <ram:ID>212</ram:ID>');

        Xml.AppendLine('          <ram:TypeCode>CDV</ram:TypeCode>');

        Xml.AppendLine('          <ram:Description>Encaissee</ram:Description>');

        if EDoc."Payment Date" <> 0D then begin

            Xml.AppendLine('          <ram:EffectiveDateTime>');

            Xml.AppendLine(
                StrSubstNo(
                    '            <qdt:DateTimeString format="102">%1</qdt:DateTimeString>',
                    FormatDate102(EDoc."Payment Date")));

            Xml.AppendLine('          </ram:EffectiveDateTime>');

        end;

        Xml.AppendLine('        </ram:ProcessSpecifiedStatusCondition>');

        Xml.AppendLine('      </ram:AcknowledgementStatus>');
    end;

    local procedure FormatDate102(Value: Date): Text
    begin
        exit(
            Format(
                Value,
                0,
                '<Year4><Month,2><Day,2>'));
    end;

    local procedure EndDocument(var Xml: TextBuilder)
    begin
        Xml.AppendLine('</rsm:CrossDomainAcknowledgementAndResponse>');
    end;
}