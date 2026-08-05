codeunit 70113 "EDoc Sovos Invoice Builder"
{
    Access = Internal;

    var
        CurrentEDocEntryNo: Integer;
        CurrentLineNo: Integer;
        HeaderSeqNo: Integer;
        LineSeqNo: Integer;
        PathStack: List of [Text];

    procedure BuildInvoiceXml(EDoc: Record "EDoc Document"): Text
    var
        EDocService: Record "EDoc Service";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Xml: TextBuilder;
        Lines: Record "EDoc Document Line";
        TaxBuffer: Record "EDoc VAT Buffer" temporary;
    begin
        InitBuffers(EDoc."Entry No.");

        if (EDoc."Service Code" = '') or not EDocService.Get(EDoc."Service Code") then
            SetupMgt.GetDefaultService(EDocService);

        Xml.AppendLine('<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"');
        Xml.AppendLine('xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"');
        Xml.AppendLine('xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">');
        PathStack.Add('Invoice');

        BuildHeader(Xml, EDoc);
        BuildMandatoryNotes(Xml, EDocService);
        BuildReferences(Xml, EDoc);

        if EDoc."Document Type" = EDoc."Document Type"::CreditMemo then
            BuildBillingReference(Xml, EDoc);

        BuildSupplier(Xml, EDoc);
        BuildCustomer(Xml, EDoc);

        BuildDelivery(Xml, EDoc);
        BuildPaymentMeans(Xml, EDoc, EDocService);
        BuildPaymentTerms(Xml, EDoc);

        BuildAllowanceCharge(Xml, EDoc);

        BuildTaxBuffer(TaxBuffer, EDoc);
        BuildTaxTotal(Xml, EDoc, TaxBuffer);

        BuildMonetaryTotal(Xml, EDoc);

        Lines.SetRange("Document Entry No.", EDoc."Entry No.");
        if Lines.FindSet() then
            repeat
                BuildInvoiceLine(Xml, EDoc, Lines);
            until Lines.Next() = 0;

        PathStack.RemoveAt(PathStack.Count);
        Xml.AppendLine('</Invoice>');

        exit(Xml.ToText());
    end;

    /// <summary>
    /// Clears any previous buffer rows for this entry (in case of a rebuild/retry) and resets
    /// the sequence counters and path stack.
    /// </summary>
    local procedure InitBuffers(EDocEntryNo: Integer)
    var
        HeaderBuffer: Record "EDoc Header XML Buffer";
        LineBuffer: Record "EDoc Line XML Buffer";
    begin
        CurrentEDocEntryNo := EDocEntryNo;
        HeaderSeqNo := 0;
        LineSeqNo := 0;
        Clear(PathStack);

        HeaderBuffer.SetRange("Buffer Entry No.", EDocEntryNo);
        HeaderBuffer.DeleteAll();

        LineBuffer.SetRange("Buffer Entry No.", EDocEntryNo);
        LineBuffer.DeleteAll();
    end;

    local procedure BuildHeader(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        AddElement(Xml, 'cbc:UBLVersionID', EDoc."UBL Version", 'UBL Version');
        AddElement(Xml, 'cbc:CustomizationID', EDoc."Customization ID", 'Customization ID');
        AddElement(Xml, 'cbc:ProfileID', EDoc."Profile ID", 'Profile ID');
        AddElement(Xml, 'cbc:ID', EDoc."Invoice No.", 'Invoice No.');
        AddElement(Xml, 'cbc:IssueDate', FormatDate(EDoc."Issue Date"), 'Issue Date');
        AddElement(Xml, 'cbc:DueDate', FormatDate(EDoc."Due Date"), 'Due Date');
        if EDoc."Document Type" = EDoc."Document Type"::Invoice then
            AddElement(Xml, 'cbc:InvoiceTypeCode', '380', 'Invoice Type Code')
        else if
            EDoc."Document Type" = EDoc."Document Type"::CreditMemo then
            AddElement(Xml, 'cbc:InvoiceTypeCode', '381', 'Invoice Type Code');
        AddElement(Xml, 'cbc:DocumentCurrencyCode', EDoc."Currency Code", 'Currency Code');
        AddElement(Xml, 'cbc:TaxCurrencyCode', EDoc."Tax Currency Code", 'Tax Currency Code');
    end;

    /// <summary>
    /// The three mandatory French B2B legal notices (Code de commerce Art. L.441-6/D.441-5):
    /// late-payment penalty rate (#PMD#), recovery indemnity (#PMT#), and early-payment
    /// discount policy (#AAB#). Text comes from "EDoc Service" setup - blank fields are
    /// skipped entirely rather than emitting placeholder legal wording.
    /// </summary>
    local procedure BuildMandatoryNotes(var Xml: TextBuilder; EDocService: Record "EDoc Service")
    begin
        if EDocService."Recovery Fee Note" <> '' then
            AddElement(Xml, 'cbc:Note', '#PMT#' + EDocService."Recovery Fee Note", 'Recovery Fee Note (#PMT#)');

        if EDocService."Late Payment Penalty Note" <> '' then
            AddElement(Xml, 'cbc:Note', '#PMD#' + EDocService."Late Payment Penalty Note", 'Late Payment Penalty Note (#PMD#)');

        if EDocService."Early Payment Discount Note" <> '' then
            AddElement(Xml, 'cbc:Note', '#AAB#' + EDocService."Early Payment Discount Note", 'Early Payment Discount Note (#AAB#)');
    end;

    /// <summary>
    /// BT-10 (BuyerReference) and BT-13 (OrderReference) - both optional, both skipped if blank.
    /// </summary>
    local procedure BuildReferences(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        if EDoc."Buyer Reference" <> '' then
            AddElement(Xml, 'cbc:BuyerReference', EDoc."Buyer Reference", 'Buyer Reference');

        if EDoc."Order No." <> '' then begin
            OpenGroup(Xml, 'cac:OrderReference');
            AddElement(Xml, 'cbc:ID', EDoc."Order No.", 'Order No.');
            CloseGroup(Xml);
        end;
    end;

    local procedure BuildBillingReference(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        if EDoc."Original Invoice No." = '' then
            exit;

        OpenGroup(Xml, 'cac:BillingReference');

        OpenGroup(Xml, 'cac:InvoiceDocumentReference');

        AddElement(
            Xml,
            'cbc:ID',
            EDoc."Original Invoice No.",
            'Original Invoice No.');

        if EDoc."Original Invoice Date" <> 0D then
            AddElement(
                Xml,
                'cbc:IssueDate',
                FormatDate(EDoc."Original Invoice Date"),
                'Original Invoice Date');

        CloseGroup(Xml);

        CloseGroup(Xml);
    end;

    local procedure BuildSupplier(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'cac:AccountingSupplierParty');
        OpenGroup(Xml, 'cac:Party');

        AddElementWithAttr(Xml, 'cbc:EndpointID', 'schemeID', '0225', EDoc."Supplier Endpoint", 'Supplier Endpoint');

        OpenGroup(Xml, 'cac:PartyIdentification');
        AddElementWithAttr(Xml, 'cbc:ID', 'schemeID', '0002', EDoc."Supplier SIREN", 'Supplier SIREN');
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PartyName');
        AddElement(Xml, 'cbc:Name', EDoc."Supplier Name", 'Supplier Name');
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PostalAddress');
        AddElement(Xml, 'cbc:StreetName', EDoc."Supplier Address", 'Supplier Address');
        AddElement(Xml, 'cbc:CityName', EDoc."Supplier City", 'Supplier City');
        AddElement(Xml, 'cbc:PostalZone', EDoc."Supplier Post Code", 'Supplier Post Code');
        OpenGroup(Xml, 'cac:Country');
        AddElement(Xml, 'cbc:IdentificationCode', EDoc."Supplier Country", 'Supplier Country');
        CloseGroup(Xml);
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PartyTaxScheme');
        AddElement(Xml, 'cbc:CompanyID', EDoc."Supplier VAT No.", 'Supplier VAT No.');
        OpenGroup(Xml, 'cac:TaxScheme');
        AddElement(Xml, 'cbc:ID', 'VAT', 'Tax Scheme (fixed)');
        CloseGroup(Xml);
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PartyLegalEntity');
        AddElement(Xml, 'cbc:RegistrationName', EDoc."Supplier Name", 'Supplier Name');
        AddElementWithAttr(Xml, 'cbc:CompanyID', 'schemeID', '0002', EDoc."Supplier SIREN", 'Supplier SIREN');
        CloseGroup(Xml);

        CloseGroup(Xml);
        CloseGroup(Xml);
    end;

    local procedure BuildCustomer(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'cac:AccountingCustomerParty');
        OpenGroup(Xml, 'cac:Party');

        AddElementWithAttr(Xml, 'cbc:EndpointID', 'schemeID', '0225', EDoc."Customer Endpoint", 'Customer Endpoint');

        OpenGroup(Xml, 'cac:PartyIdentification');
        AddElementWithAttr(Xml, 'cbc:ID', 'schemeID', '0002', EDoc."Customer SIREN", 'Customer SIREN');
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PartyName');
        AddElement(Xml, 'cbc:Name', EDoc."Customer Name", 'Customer Name');
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PostalAddress');
        AddElement(Xml, 'cbc:StreetName', EDoc."Customer Address", 'Customer Address');
        AddElement(Xml, 'cbc:CityName', EDoc."Customer City", 'Customer City');
        AddElement(Xml, 'cbc:PostalZone', EDoc."Customer Post Code", 'Customer Post Code');
        OpenGroup(Xml, 'cac:Country');
        AddElement(Xml, 'cbc:IdentificationCode', EDoc."Customer Country", 'Customer Country');
        CloseGroup(Xml);
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PartyTaxScheme');
        AddElement(Xml, 'cbc:CompanyID', EDoc."Customer VAT No.", 'Customer VAT No.');
        OpenGroup(Xml, 'cac:TaxScheme');
        AddElement(Xml, 'cbc:ID', 'VAT', 'Tax Scheme (fixed)');
        CloseGroup(Xml);
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:PartyLegalEntity');
        AddElement(Xml, 'cbc:RegistrationName', EDoc."Customer Name", 'Customer Name');
        AddElementWithAttr(Xml, 'cbc:CompanyID', 'schemeID', '0002', EDoc."Customer SIREN", 'Customer SIREN');
        CloseGroup(Xml);

        CloseGroup(Xml);
        CloseGroup(Xml);
    end;

    /// <summary>
    /// BT-72 - only emitted when an actual delivery date is known.
    /// </summary>
    local procedure BuildDelivery(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        if EDoc."Actual Delivery Date" = 0D then
            exit;

        OpenGroup(Xml, 'cac:Delivery');
        AddElement(Xml, 'cbc:ActualDeliveryDate', FormatDate(EDoc."Actual Delivery Date"), 'Actual Delivery Date');
        CloseGroup(Xml);
    end;

    /// <summary>
    /// BT-81/82 (payment means code) plus BT-84/85/86 (payee financial account), the latter
    /// pulled from a real Bank Account record via "EDoc Service"."Payee Bank Account Code" -
    /// never fabricated. Skipped entirely if neither a payment means code nor a bank account
    /// is configured.
    /// </summary>
    local procedure BuildPaymentMeans(var Xml: TextBuilder; EDoc: Record "EDoc Document"; EDocService: Record "EDoc Service")
    var
        BankAccount: Record "Bank Account";
        HasBankAccount: Boolean;
        CompanySetup: Record "Company Information";
    begin
        HasBankAccount := (EDocService."Payee Bank Account Code" <> '') and BankAccount.Get(EDocService."Payee Bank Account Code");

        if (EDoc."Payment Means Code" = '') and not HasBankAccount then
            exit;

        OpenGroup(Xml, 'cac:PaymentMeans');

        if EDoc."Payment Means Code" <> '' then
            AddElement(Xml, 'cbc:PaymentMeansCode', EDoc."Payment Means Code", 'Payment Means Code');

        if HasBankAccount then begin
            if (BankAccount.IBAN <> '') then begin
                OpenGroup(Xml, 'cac:PayeeFinancialAccount');
                AddElement(Xml, 'cbc:ID', BankAccount.IBAN, 'Payee IBAN');
                AddElement(Xml, 'cbc:Name', BankAccount.Name, 'Payee Bank Account Name');
                if BankAccount."SWIFT Code" <> '' then begin
                    OpenGroup(Xml, 'cac:FinancialInstitutionBranch');
                    AddElement(Xml, 'cbc:ID', BankAccount."SWIFT Code", 'Payee BIC');
                    CloseGroup(Xml);
                end;
                CloseGroup(Xml);
            end
            else begin
                CompanySetup.get();
                OpenGroup(Xml, 'cac:PayeeFinancialAccount');
                AddElement(Xml, 'cbc:ID', CompanySetup.IBAN, 'Payee IBAN');
                AddElement(Xml, 'cbc:Name', CompanySetup."Bank Name", 'Payee Bank Account Name');
                OpenGroup(Xml, 'cac:FinancialInstitutionBranch');
                AddElement(Xml, 'cbc:ID', CompanySetup."SWIFT Code", 'Payee BIC');
                CloseGroup(Xml);
                CloseGroup(Xml);
            end;
        end;

        CloseGroup(Xml);
    end;

    /// <summary>
    /// BT-20 - the invoice's own payment terms description (see "EDoc Import Mgt."), not
    /// invented text. Skipped if blank.
    /// </summary>
    local procedure BuildPaymentTerms(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        if EDoc."Payment Terms Note" = '' then
            exit;

        OpenGroup(Xml, 'cac:PaymentTerms');
        AddElement(Xml, 'cbc:Note', EDoc."Payment Terms Note", 'Payment Terms Note');
        CloseGroup(Xml);
    end;

    local procedure BuildMonetaryTotal(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    var
        TaxExclusiveAmount: Decimal;
    begin
        TaxExclusiveAmount :=
            EDoc."Amount Excl. VAT";

        OpenGroup(Xml, 'cac:LegalMonetaryTotal');

        AddAmount(
            Xml,
            'cbc:LineExtensionAmount',
            EDoc."Currency Code",
            EDoc."Amount Excl. VAT",
            'Amount Excl. VAT');

        if EDoc."Allowance Amount" <> 0 then
            AddAmount(
                Xml,
                'cbc:AllowanceTotalAmount',
                EDoc."Currency Code",
                EDoc."Allowance Amount",
                'Allowance Amount');

        AddAmount(
            Xml,
            'cbc:TaxExclusiveAmount',
            EDoc."Currency Code",
            TaxExclusiveAmount,
            'Tax Exclusive Amount');

        AddAmount(
            Xml,
            'cbc:TaxInclusiveAmount',
            EDoc."Currency Code",
            TaxExclusiveAmount + EDoc."VAT Amount",
            'Amount Incl. VAT');

        AddAmount(
            Xml,
            'cbc:PayableAmount',
            EDoc."Currency Code",
            EDoc."Payable Amount",
            'Payable Amount');

        CloseGroup(Xml);
    end;

    local procedure BuildTaxBuffer(var TaxBuffer: Record "EDoc VAT Buffer" temporary; EDoc: Record "EDoc Document")
    var
        Line: Record "EDoc Document Line";
    begin

        TaxBuffer.Reset();
        TaxBuffer.DeleteAll();

        Line.SetRange("Document Entry No.", EDoc."Entry No.");
        if Line.FindSet() then
            repeat
                TaxBuffer.SetRange("VAT Category", Line."VAT Category");
                TaxBuffer.SetRange("VAT %", Line."VAT %");
                if not TaxBuffer.FindFirst() then begin
                    TaxBuffer.Init();
                    TaxBuffer."VAT Category" := Line."VAT Category";
                    TaxBuffer."VAT %" := Line."VAT %";
                    TaxBuffer."Tax Exemption Code" := Line."Tax Exemption Code";
                    TaxBuffer."Tax Exemption Reason" := Line."Tax Exemption Reason";
                    TaxBuffer."Taxable Amount" := 0;
                    TaxBuffer."Tax Amount" := 0;
                    TaxBuffer.Insert();
                end;

                TaxBuffer."Taxable Amount" += Line."Taxable Amount";
                TaxBuffer."Tax Amount" += Line."Tax Amount";
                TaxBuffer.Modify();
            until Line.Next() = 0;

        if EDoc."Allowance Amount" <> 0 then begin
            TaxBuffer.SetRange("VAT Category", EDoc."Allowance VAT Category");
            TaxBuffer.SetRange("VAT %", EDoc."Allowance VAT %");

            if TaxBuffer.FindFirst() then begin
                TaxBuffer."Taxable Amount" -= EDoc."Allowance Amount";
                TaxBuffer."Tax Amount" :=
                    Round(
                        TaxBuffer."Taxable Amount" * TaxBuffer."VAT %" / 100,
                        0.01);

                TaxBuffer.Modify();
            end;
        end;
        TaxBuffer.Reset();
    end;

    local procedure BuildTaxTotal(var Xml: TextBuilder; EDoc: Record "EDoc Document"; var TaxBuffer: Record "EDoc VAT Buffer" temporary)
    begin
        OpenGroup(Xml, 'cac:TaxTotal');
        AddAmount(Xml, 'cbc:TaxAmount', EDoc."Currency Code", EDoc."VAT Amount", 'VAT Amount (header)');

        if TaxBuffer.FindSet() then
            repeat
                OpenGroup(Xml, 'cac:TaxSubtotal');
                AddAmount(Xml, 'cbc:TaxableAmount', EDoc."Currency Code", TaxBuffer."Taxable Amount", 'VAT Subtotal - Taxable Amount (' + TaxBuffer."VAT Category" + ')');
                AddAmount(Xml, 'cbc:TaxAmount', EDoc."Currency Code", TaxBuffer."Tax Amount", 'VAT Subtotal - Tax Amount (' + TaxBuffer."VAT Category" + ')');

                OpenGroup(Xml, 'cac:TaxCategory');
                AddElement(Xml, 'cbc:ID', TaxBuffer."VAT Category", 'VAT Category');
                //if (TaxBuffer."VAT %" <> 0) then
                AddElement(Xml, 'cbc:Percent', FormatDecimal(TaxBuffer."VAT %"), 'VAT %');
                if TaxBuffer."Tax Exemption Code" <> '' then
                    AddElement(Xml, 'cbc:TaxExemptionReasonCode', TaxBuffer."Tax Exemption Code", 'Tax Exemption Code');
                if TaxBuffer."Tax Exemption Reason" <> '' then
                    AddElement(Xml, 'cbc:TaxExemptionReason', TaxBuffer."Tax Exemption Reason", 'Tax Exemption Reason');
                OpenGroup(Xml, 'cac:TaxScheme');
                AddElement(Xml, 'cbc:ID', 'VAT', 'Tax Scheme (fixed)');
                CloseGroup(Xml);
                CloseGroup(Xml);

                CloseGroup(Xml);
            until TaxBuffer.Next() = 0;

        CloseGroup(Xml);
    end;

    local procedure BuildInvoiceLine(var Xml: TextBuilder; EDoc: Record "EDoc Document"; Line: Record "EDoc Document Line")
    begin
        CurrentLineNo := Line."Line No.";
        LineSeqNo := 0;

        OpenGroup(Xml, 'cac:InvoiceLine');

        AddLineElement(Xml, 'cbc:ID', Format(Line."Line No."), 'Line No.');
        AddLineElementWithAttr(Xml, 'cbc:InvoicedQuantity', 'unitCode', Line."Unit Code", FormatDecimal(Line.Quantity), 'Quantity');
        AddLineAmount(Xml, 'cbc:LineExtensionAmount', EDoc."Currency Code", Line."Line Amount", 'Line Amount');

        if Line."Line Discount Amount" <> 0 then begin
            OpenGroup(Xml, 'cac:AllowanceCharge');
            AddLineElement(Xml, 'cbc:ChargeIndicator', 'false', 'Discount indicator (fixed)');
            AddLineAmount(Xml, 'cbc:Amount', EDoc."Currency Code", Line."Line Discount Amount", 'Line Discount Amount');
            CloseGroup(Xml);
        end;

        OpenGroup(Xml, 'cac:TaxTotal');
        AddLineAmount(Xml, 'cbc:TaxAmount', EDoc."Currency Code", Line."Tax Amount", 'Tax Amount');
        OpenGroup(Xml, 'cac:TaxSubtotal');
        AddLineAmount(Xml, 'cbc:TaxableAmount', EDoc."Currency Code", Line."Taxable Amount", 'Taxable Amount');
        AddLineAmount(Xml, 'cbc:TaxAmount', EDoc."Currency Code", Line."Tax Amount", 'Tax Amount');
        OpenGroup(Xml, 'cac:TaxCategory');
        AddLineElement(Xml, 'cbc:ID', Line."VAT Category", 'VAT Category');
        AddLineElement(Xml, 'cbc:Percent', FormatDecimal(Line."VAT %"), 'VAT %');
        if Line."Tax Exemption Code" <> '' then
            AddLineElement(Xml, 'cbc:TaxExemptionReasonCode', Line."Tax Exemption Code", 'Tax Exemption Code');
        if Line."Tax Exemption Reason" <> '' then
            AddLineElement(Xml, 'cbc:TaxExemptionReason', Line."Tax Exemption Reason", 'Tax Exemption Reason');
        OpenGroup(Xml, 'cac:TaxScheme');
        AddLineElement(Xml, 'cbc:ID', 'VAT', 'Tax Scheme (fixed)');
        CloseGroup(Xml);
        CloseGroup(Xml);
        CloseGroup(Xml);
        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:Item');
        AddLineElement(Xml, 'cbc:Name', Line.Description, 'Description');
        if Line."Description 2" <> '' then
            AddLineElement(Xml, 'cbc:Description', Line."Description 2", 'Description 2');

        if Line."Seller Item No." <> '' then begin
            OpenGroup(Xml, 'cac:SellersItemIdentification');
            AddLineElement(Xml, 'cbc:ID', Line."Seller Item No.", 'Seller Item No.');
            CloseGroup(Xml);
        end;

        if Line."Buyer Item No." <> '' then begin
            OpenGroup(Xml, 'cac:BuyersItemIdentification');
            AddLineElement(Xml, 'cbc:ID', Line."Buyer Item No.", 'Buyer Item No.');
            CloseGroup(Xml);
        end;

        if Line."Commodity Code" <> '' then begin
            OpenGroup(Xml, 'cac:CommodityClassification');
            AddLineElement(Xml, 'cbc:ItemClassificationCode', Line."Commodity Code", 'Commodity Code');
            CloseGroup(Xml);
        end;

        if Line."Country of Origin" <> '' then begin
            OpenGroup(Xml, 'cac:OriginCountry');
            AddLineElement(Xml, 'cbc:IdentificationCode', Line."Country of Origin", 'Country of Origin');
            CloseGroup(Xml);
        end;

        OpenGroup(Xml, 'cac:ClassifiedTaxCategory');
        AddLineElement(Xml, 'cbc:ID', Line."VAT Category", 'VAT Category');
        // if Line."VAT %" <> 0 then
        AddLineElement(
            Xml,
            'cbc:Percent',
            FormatDecimal(Line."VAT %"),
            'VAT %');
        if Line."Tax Exemption Code" <> '' then
            AddLineElement(
                Xml,
                'cbc:TaxExemptionReasonCode',
                Line."Tax Exemption Code",
                'Tax Exemption Code');

        if Line."Tax Exemption Reason" <> '' then
            AddLineElement(
                Xml,
                'cbc:TaxExemptionReason',
                Line."Tax Exemption Reason",
                'Tax Exemption Reason');
        OpenGroup(Xml, 'cac:TaxScheme');
        AddLineElement(Xml, 'cbc:ID', 'VAT', 'Tax Scheme');
        CloseGroup(Xml);

        CloseGroup(Xml);

        CloseGroup(Xml);

        OpenGroup(Xml, 'cac:Price');
        AddLineAmount(Xml, 'cbc:PriceAmount', EDoc."Currency Code", Line."Unit Price", 'Unit Price');
        if Line."Price Base Quantity" > 0 then
            AddLineElementWithAttr(
                Xml,
                'cbc:BaseQuantity',
                'unitCode',
                Line."Unit Code",
                FormatDecimal(Line."Price Base Quantity"),
                'Price Base Quantity');
        CloseGroup(Xml);

        CloseGroup(Xml);
    end;

    local procedure BuildAllowanceCharge(var Xml: TextBuilder; EDoc: Record "EDoc Document")
    begin
        if EDoc."Allowance Amount" = 0 then
            exit;

        OpenGroup(Xml, 'cac:AllowanceCharge');

        AddElement(Xml, 'cbc:ChargeIndicator', 'false', 'Charge Indicator');

        if EDoc."Allowance Reason" <> '' then
            AddElement(
                Xml,
                'cbc:AllowanceChargeReason',
                EDoc."Allowance Reason",
                'Allowance Reason');

        AddAmount(
            Xml,
            'cbc:Amount',
            EDoc."Currency Code",
            EDoc."Allowance Amount",
            'Allowance Amount');

        OpenGroup(Xml, 'cac:TaxCategory');

        AddElement(
            Xml,
            'cbc:ID',
            EDoc."Allowance VAT Category",
            'Allowance VAT Category');

        if EDoc."Allowance VAT %" <> 0 then
            AddElement(
                Xml,
                'cbc:Percent',
                FormatDecimal(EDoc."Allowance VAT %"),
                'Allowance VAT %');

        OpenGroup(Xml, 'cac:TaxScheme');
        AddElement(Xml, 'cbc:ID', 'VAT', 'Tax Scheme');
        CloseGroup(Xml);

        CloseGroup(Xml);

        CloseGroup(Xml);
    end;
    // ----------------------------------------------------------------------
    // Path-tracking group open/close - every OpenGroup/CloseGroup pair keeps
    // PathStack in sync with what's actually open in the XML at that point.
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

    /// <summary>
    /// Builds the full ancestor path (e.g. "Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID")
    /// from the current PathStack plus the leaf tag being written right now.
    /// </summary>
    local procedure BuildFullPath(LeafTag: Text): Text
    var
        PathBuilder: TextBuilder;
        Segment: Text;
        First: Boolean;
    begin
        First := true;
        foreach Segment in PathStack do begin
            if not First then
                PathBuilder.Append('/');
            PathBuilder.Append(Segment);
            First := false;
        end;

        if PathBuilder.Length() > 0 then
            PathBuilder.Append('/');
        PathBuilder.Append(LeafTag);

        exit(PathBuilder.ToText());
    end;

    // ----------------------------------------------------------------------
    // Header-level helpers: write to XML AND log into "EDoc Header XML Buffer"
    // "XML Tag" now stores the full path, not just the leaf element name.
    // ----------------------------------------------------------------------

    local procedure AddElement(var Xml: TextBuilder; Element: Text; Value: Text; FieldName: Text)
    begin
        LogHeaderField(FieldName, Value, BuildFullPath(Element));

        if Value = '' then
            exit;

        Xml.AppendLine('<' + Element + '>' + EscapeXml(Value) + '</' + Element + '>');
    end;

    local procedure AddElementWithAttr(var Xml: TextBuilder; Element: Text; AttrName: Text; AttrValue: Text; Value: Text; FieldName: Text)
    begin
        LogHeaderField(FieldName, Value, BuildFullPath(Element) + '[@' + AttrName + '="' + AttrValue + '"]');

        Xml.AppendLine('<' + Element + ' ' + AttrName + '="' + AttrValue + '">' + EscapeXml(Value) + '</' + Element + '>');
    end;

    local procedure AddAmount(var Xml: TextBuilder; Element: Text; CurrencyCode: Code[10]; Amount: Decimal; FieldName: Text)
    begin
        LogHeaderField(FieldName, FormatDecimal(Amount), BuildFullPath(Element) + '[@currencyID="' + CurrencyCode + '"]');

        Xml.AppendLine('<' + Element + ' currencyID="' + CurrencyCode + '">' + FormatDecimal(Amount) + '</' + Element + '>');
    end;

    local procedure LogHeaderField(FieldName: Text; Value: Text; XmlTag: Text)
    var
        HeaderBuffer: Record "EDoc Header XML Buffer";
    begin
        HeaderSeqNo += 1;

        HeaderBuffer.Init();
        HeaderBuffer."Buffer Entry No." := CurrentEDocEntryNo;
        HeaderBuffer."Sequence No." := HeaderSeqNo;
        HeaderBuffer."Field Name" := CopyStr(FieldName, 1, MaxStrLen(HeaderBuffer."Field Name"));
        HeaderBuffer."Field Value" := CopyStr(Value, 1, MaxStrLen(HeaderBuffer."Field Value"));
        HeaderBuffer."XML Tag" := CopyStr(XmlTag, 1, MaxStrLen(HeaderBuffer."XML Tag"));
        HeaderBuffer.Insert();
    end;

    // ----------------------------------------------------------------------
    // Line-level helpers: same full-path logging, scoped to the current line.
    // ----------------------------------------------------------------------

    local procedure AddLineElement(var Xml: TextBuilder; Element: Text; Value: Text; FieldName: Text)
    begin
        LogLineField(FieldName, Value, BuildFullPath(Element));

        if Value = '' then
            exit;

        Xml.AppendLine('<' + Element + '>' + EscapeXml(Value) + '</' + Element + '>');
    end;

    local procedure AddLineElementWithAttr(var Xml: TextBuilder; Element: Text; AttrName: Text; AttrValue: Text; Value: Text; FieldName: Text)
    begin
        LogLineField(FieldName, Value, BuildFullPath(Element) + '[@' + AttrName + '="' + AttrValue + '"]');

        Xml.AppendLine('<' + Element + ' ' + AttrName + '="' + AttrValue + '">' + EscapeXml(Value) + '</' + Element + '>');
    end;

    local procedure AddLineAmount(var Xml: TextBuilder; Element: Text; CurrencyCode: Code[10]; Amount: Decimal; FieldName: Text)
    begin
        LogLineField(FieldName, FormatDecimal(Amount), BuildFullPath(Element) + '[@currencyID="' + CurrencyCode + '"]');

        Xml.AppendLine('<' + Element + ' currencyID="' + CurrencyCode + '">' + FormatDecimal(Amount) + '</' + Element + '>');
    end;

    local procedure LogLineField(FieldName: Text; Value: Text; XmlTag: Text)
    var
        LineBuffer: Record "EDoc Line XML Buffer";
    begin
        LineSeqNo += 1;

        LineBuffer.Init();
        LineBuffer."Buffer Entry No." := CurrentEDocEntryNo;
        LineBuffer."Source Line No." := CurrentLineNo;
        LineBuffer."Sequence No." := LineSeqNo;
        LineBuffer."Field Name" := CopyStr(FieldName, 1, MaxStrLen(LineBuffer."Field Name"));
        LineBuffer."Field Value" := CopyStr(Value, 1, MaxStrLen(LineBuffer."Field Value"));
        LineBuffer."XML Tag" := CopyStr(XmlTag, 1, MaxStrLen(LineBuffer."XML Tag"));
        LineBuffer.Insert();
    end;

    // ----------------------------------------------------------------------
    // Formatting
    // ----------------------------------------------------------------------

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
