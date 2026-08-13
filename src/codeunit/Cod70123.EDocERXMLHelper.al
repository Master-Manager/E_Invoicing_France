codeunit 70123 "EDoc ER XML Helper"
{
    Access = Internal;

    var
        PathStack: List of [Text];
        PlatformIdLbl: Label '0201', Locked = true;
        PlatformSchemeIdLbl: Label '0238', Locked = true;
        PlatformNameLbl: Label 'PDP_0201', Locked = true;
        PlatformRoleCodeLbl: Label 'WK', Locked = true;
        PlatformEmailLbl: Label 'PDP_0201@pdp.fr', Locked = true;

    procedure OpenGroup(var Xml: TextBuilder; Tag: Text)
    begin
        Xml.AppendLine('<' + Tag + '>');
        PathStack.Add(Tag);
    end;

    procedure CloseGroup(var Xml: TextBuilder)
    var
        Tag: Text;
    begin
        Tag := PathStack.Get(PathStack.Count);
        PathStack.RemoveAt(PathStack.Count);
        Xml.AppendLine('</' + Tag + '>');
    end;

    procedure AddElement(var Xml: TextBuilder; Element: Text; Value: Text)
    begin
        if Value = '' then
            exit;
        Xml.AppendLine('<' + Element + '>' + EscapeXml(Value) + '</' + Element + '>');
    end;

    procedure AddElementWithAttr(var Xml: TextBuilder; Element: Text; AttrName: Text; AttrValue: Text; Value: Text)
    begin
        if Value = '' then
            exit;
        Xml.AppendLine('<' + Element + ' ' + AttrName + '="' + EscapeXml(AttrValue) + '">' + EscapeXml(Value) + '</' + Element + '>');
    end;

    procedure AddAmountPlain(var Xml: TextBuilder; Element: Text; Amount: Decimal)
    begin
        Xml.AppendLine('<' + Element + '>' + FormatDecimal(Amount) + '</' + Element + '>');
    end;

    procedure AddAmountWithCurrency(var Xml: TextBuilder; Element: Text; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        Xml.AppendLine('<' + Element + ' CurrencyCode="' + CurrencyCode + '">' + FormatDecimal(Amount) + '</' + Element + '>');
    end;

    procedure AddAmountWithCustomAttr(var Xml: TextBuilder; Element: Text; AttrName: Text; AttrValue: Text; Amount: Decimal)
    begin
        Xml.AppendLine('<' + Element + ' ' + AttrName + '="' + EscapeXml(AttrValue) + '">' + FormatDecimal(Amount) + '</' + Element + '>');
    end;

    procedure FormatDateShort(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Year4><Month,2><Day,2>'));
    end;

    procedure FormatDateTime(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
    end;

    procedure FormatDecimal(Value: Decimal): Text
    begin
        exit(ConvertStr(Format(Round(Value, 0.0001), 0, 9), ',', '.'));
    end;

    procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode = '' then
            exit('EUR');
        exit(CurrencyCode);
    end;

    procedure EscapeXml(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        Value := Value.Replace('"', '&quot;');
        Value := Value.Replace('''', '&apos;');
        exit(Value);
    end;

    procedure BuildReportDocument(var Xml: TextBuilder; CompanyInfo: Record "Company Information"; StartDate: Date; EndDate: Date; EDoc: Record "EDoc Document")
    var
        TransmissionId: Text;
    begin
        TransmissionId := StrSubstNo('MC_%1', EDoc."Entry No.");

        OpenGroup(Xml, 'ReportDocument');
        AddElement(Xml, 'Id', TransmissionId);
        AddElement(Xml, 'Name', 'REP-' + TransmissionId);

        OpenGroup(Xml, 'IssueDateTime');
        AddElement(Xml, 'DateTimeString', FormatDateTime(CurrentDateTime()));
        CloseGroup(Xml);

        AddElement(Xml, 'TypeCode', 'IN');

        BuildSender(Xml);
        BuildIssuer(Xml, CompanyInfo);

        CloseGroup(Xml);
    end;

    local procedure BuildSender(var Xml: TextBuilder)
    begin
        OpenGroup(Xml, 'Sender');
        AddElementWithAttr(Xml, 'Id', 'schemeId', PlatformSchemeIdLbl, PlatformIdLbl);
        AddElement(Xml, 'Name', PlatformNameLbl);
        AddElement(Xml, 'RoleCode', PlatformRoleCodeLbl);

        OpenGroup(Xml, 'URIUniversalCommunication');
        AddElement(Xml, 'URIID', PlatformEmailLbl);
        CloseGroup(Xml);

        CloseGroup(Xml);
    end;

    local procedure BuildIssuer(var Xml: TextBuilder; CompanyInfo: Record "Company Information")
    begin
        OpenGroup(Xml, 'Issuer');
        AddElementWithAttr(Xml, 'Id', 'schemeId', '0002', CompanyInfo."EDoc SIREN");
        AddElement(Xml, 'Name', CompanyInfo.Name);
        AddElement(Xml, 'RoleCode', 'SE');

        OpenGroup(Xml, 'URIUniversalCommunication');
        AddElement(Xml, 'URIID', CompanyInfo."E-Mail");
        CloseGroup(Xml);

        CloseGroup(Xml);
    end;

    procedure BuildSeller(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Seller');
        AddElementWithAttr(Xml, 'CompanyId', 'schemeId', '0002', EDoc."Supplier SIREN");
        AddElementWithAttr(Xml, 'TaxRegistrationId', 'qualifyingId', 'VAT', EDoc."Supplier VAT No.");

        OpenGroup(Xml, 'PostalAddress');
        AddElement(Xml, 'CountryId', EDoc."Supplier Country");
        CloseGroup(Xml);
        CloseGroup(Xml);
    end;

    procedure BuildBuyer(var Xml: TextBuilder; CompanyInfo: Record "Company Information"; EDoc: Record "EDoc Document")
    var
        CompanyId: Text;
        SchemeId: Code[4];
        CountryCode: Code[10];
        VATNo: Text;
    begin
        // If EDoc has customer fields populated, use them; otherwise fallback to CompanyInfo (for inbound/purchase)
        if EDoc."Customer SIREN" <> '' then begin
            CompanyId := EDoc."Customer SIREN";
            SchemeId := '0002';
            CountryCode := EDoc."Customer Country";
            VATNo := EDoc."Customer VAT No.";
        end else begin
            if CompanyInfo."EDoc SIREN" <> '' then
                CompanyId := CompanyInfo."EDoc SIREN"
            else if CompanyInfo."Registration No." <> '' then
                CompanyId := CompanyInfo."Registration No."
            else
                CompanyId := CompanyInfo."VAT Registration No.";

            SchemeId := GetBuyerSchemeId(CompanyInfo."Country/Region Code");
            CountryCode := CompanyInfo."Country/Region Code";
            VATNo := CompanyInfo."VAT Registration No.";
        end;

        OpenGroup(Xml, 'Buyer');
        AddElementWithAttr(Xml, 'CompanyId', 'schemeId', SchemeId, CompanyId);
        AddElementWithAttr(Xml, 'TaxRegistrationId', 'qualifyingId', 'VAT', VATNo);

        if CountryCode <> '' then begin
            OpenGroup(Xml, 'PostalAddress');
            AddElement(Xml, 'CountryId', CountryCode);
            CloseGroup(Xml);
        end;

        CloseGroup(Xml);
    end;

    procedure GetBuyerSchemeId(CountryCode: Code[10]): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryCode in ['FR', 'FRA', ''] then
            exit('0002');

        if CountryRegion.Get(CountryCode) then
            if CountryCode in [
                'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE',
                'EL', 'ES', 'FI', 'GR', 'HR', 'HU', 'IE', 'IS', 'IT',
                'LT', 'LU', 'LV', 'MT', 'NL', 'PL', 'PT', 'RO',
                'SE', 'SI', 'SK'
            ] then
                exit('0223');

        exit('0227');
    end;

    procedure BuildDelivery(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        if (EDoc."Customer Address" = '') and (EDoc."Customer City" = '') then
            exit;

        OpenGroup(Xml, 'Delivery');
        OpenGroup(Xml, 'Location');
        AddElement(Xml, 'LineOne', EDoc."Customer Address");
        AddElement(Xml, 'CityName', EDoc."Customer City");
        AddElement(Xml, 'PostalZone', EDoc."Customer Post Code");
        AddElement(Xml, 'CountryId', EDoc."Customer Country");
        CloseGroup(Xml);
        CloseGroup(Xml);
    end;

    procedure BuildInvoiceNotes(var Xml: TextBuilder; CompanyInfo: Record "Company Information"; EDocService: Record "EDoc Service")
    var
        AAIContent: Text;
    begin
        AddNote(Xml, 'ABL', 'RCS ' + CompanyInfo.City + ' ' + CompanyInfo."EDoc SIREN");

        AAIContent := CompanyInfo.Address + ', ' + CompanyInfo."Post Code" + ' ' + CompanyInfo.City +
            ', ' + CompanyInfo."Country/Region Code" + ' – contact@' + CompanyInfo.Name + ' – N° TVA : ' + CompanyInfo."VAT Registration No.";
        AddNote(Xml, 'AAI', AAIContent);

        AddNote(Xml, 'PMD', EDocService."Late Payment Penalty Note");
        AddNote(Xml, 'PMT', EDocService."Recovery Fee Note");
        AddNote(Xml, 'AAB', EDocService."Early Payment Discount Note");
    end;

    local procedure AddNote(var Xml: TextBuilder; Subject: Text; Content: Text)
    begin
        if Content = '' then
            exit;
        OpenGroup(Xml, 'IncludedNote');
        AddElement(Xml, 'Subject', Subject);
        AddElement(Xml, 'Content', Content);
        CloseGroup(Xml);
    end;

    procedure BuildVATBuffer(EDocHeader: Record "EDoc Document"; var TempVATBuffer: Record "EDoc VAT Buffer" temporary)
    var
        EDocLine: Record "EDoc Document Line";
        TaxCategory: Code[10];
        ProrataFactor: Decimal;
    begin
        TempVATBuffer.Reset();
        TempVATBuffer.DeleteAll();

        ProrataFactor := 1;
        if (EDocHeader."Amount Incl. VAT" > 0) and (EDocHeader."Amount Paid" > 0) then
            ProrataFactor := EDocHeader."Amount Paid" / EDocHeader."Amount Incl. VAT";

        EDocLine.SetRange("Document Entry No.", EDocHeader."Entry No.");
        if EDocLine.FindSet() then
            repeat
                TaxCategory := GetTaxCategoryCode(EDocLine."VAT Bus. Posting Group", EDocLine."VAT Prod. Posting Group");

                TempVATBuffer.SetRange("VAT Category", TaxCategory);
                TempVATBuffer.SetRange("VAT Rate", EDocLine."VAT %");

                if TempVATBuffer.FindFirst() then begin
                    TempVATBuffer."Taxable Amount" += Round(EDocLine."Taxable Amount" * ProrataFactor, 0.01);
                    TempVATBuffer."Tax Amount" += Round(EDocLine."Tax Amount" * ProrataFactor, 0.01);
                    TempVATBuffer.Modify();
                end else begin
                    TempVATBuffer.Init();
                    TempVATBuffer."Entry No." := TempVATBuffer.Count + 1;
                    TempVATBuffer."Document No." := EDocHeader."Document No.";
                    TempVATBuffer."VAT Category" := TaxCategory;
                    TempVATBuffer."VAT Rate" := EDocLine."VAT %";
                    TempVATBuffer."Taxable Amount" := Round(EDocLine."Taxable Amount" * ProrataFactor, 0.01);
                    TempVATBuffer."Tax Amount" := Round(EDocLine."Tax Amount" * ProrataFactor, 0.01);
                    TempVATBuffer.Insert();
                end;
            until EDocLine.Next() = 0;
    end;

    procedure GetTaxCategoryCode(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            if VATPostingSetup."Sovos VAT Category" <> '' then
                exit(VATPostingSetup."Sovos VAT Category");

        exit('S');
    end;
}