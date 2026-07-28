codeunit 70124 "EDoc ER XML Helper"
{
    Access = Internal;

    var
        PathStack: List of [Text];


    procedure BeginDocument(var Xml: TextBuilder)
    begin
        Clear(PathStack);

        Xml.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');

        OpenGroup(
            Xml,
            'EReporting');
    end;

    procedure BuildHeader(
        var Xml: TextBuilder;
        CompanyInfo: Record "Company Information")
    begin
        OpenGroup(Xml, 'Header');

        AddElement(
            Xml,
            'SenderSIREN',
            CompanyInfo."EDoc SIREN");

        AddElement(
            Xml,
            'VATNumber',
            CompanyInfo."VAT Registration No.");

        AddElement(
            Xml,
            'CreationDateTime',
            Format(
                CurrentDateTime(),
                0,
                '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));

        CloseGroup(Xml);
    end;

    procedure BuildFlow(
      var Xml: TextBuilder;
      EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Flow');

        AddElement(
            Xml,
            'FlowType',
            GetFlowCode(EDoc."Flow Type"));

        AddElement(
            Xml,
            'DocumentNo',
            EDoc."Document No.");

        AddElement(
            Xml,
            'PostingDate',
            FormatDate(EDoc."Posting Date"));

        AddElement(
            Xml,
            'DocumentDate',
            FormatDate(EDoc."Document Date"));

        CloseGroup(Xml);
    end;

    procedure GetFlowCode(
        FlowType: Enum "EDoc Flow Type"): Code[10]
    begin
        case FlowType of
            FlowType::International:
                exit('10.1');

            FlowType::Collection:
                exit('10.2');

            FlowType::"B2C Reporting":
                exit('10.3');
        end;

        exit('');
    end;

    procedure BuildSeller(
   var Xml: TextBuilder;
   CompanyInfo: Record "Company Information")
    begin
        OpenGroup(Xml, 'Seller');

        AddElement(
            Xml,
            'SIREN',
            CompanyInfo."EDoc SIREN");

        AddElement(
            Xml,
            'VATNumber',
            CompanyInfo."VAT Registration No.");

        AddElement(
            Xml,
            'Name',
            CompanyInfo.Name);
        AddElement(
            Xml,
            'SIRET',
            CompanyInfo."EDoc SIRET");

        AddElement(
            Xml,
            'Endpoint',
            CompanyInfo."EDoc Endpoint ID");
        CloseGroup(Xml);
    end;

    procedure BuildBuyer(
   var Xml: TextBuilder;
   EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Buyer');
        AddElement(
            Xml,
            'SIREN',
            EDoc."Customer SIREN");

        AddElement(
            Xml,
            'SIRET',
            EDoc."Customer SIRET");

        AddElement(
            Xml,
            'Endpoint',
            EDoc."Customer Endpoint");
        AddElement(
            Xml,
            'CustomerNo',
            EDoc."Customer No.");

        AddElement(
            Xml,
            'Name',
            EDoc."Customer Name");

        AddElement(
            Xml,
            'VATNumber',
            EDoc."Customer VAT No.");

        AddElement(
            Xml,
            'Country',
            EDoc."Customer Country");

        CloseGroup(Xml);
    end;

    procedure BuildInvoice(
      var Xml: TextBuilder;
      EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Invoice');

        BuildInvoiceHeader(
            Xml,
            EDoc);

        BuildInvoiceTotals(
            Xml,
            EDoc);

        BuildInvoiceLines(
Xml,
EDoc);

        CloseGroup(Xml);
    end;

    procedure BuildInvoiceHeader(
       var Xml: TextBuilder;
       EDoc: Record "EDoc Document")
    begin
        AddElement(
            Xml,
            'InvoiceNumber',
            EDoc."Invoice No.");

        AddElement(
            Xml,
            'IssueDate',
            FormatDate(EDoc."Issue Date"));

        AddElement(
            Xml,
            'DueDate',
            FormatDate(EDoc."Due Date"));

        AddElement(
            Xml,
            'Currency',
            EDoc."Currency Code");
    end;

    procedure BuildInvoiceTotals(
       var Xml: TextBuilder;
       EDoc: Record "EDoc Document")
    begin

        AddAmount(
            Xml,
            'NetAmount',
            EDoc."Currency Code",
            EDoc."Amount Excl. VAT");

        AddAmount(
            Xml,
            'VATAmount',
            EDoc."Currency Code",
            EDoc."VAT Amount");

        AddAmount(
            Xml,
            'GrossAmount',
            EDoc."Currency Code",
            EDoc."Amount Incl. VAT");
    end;

    procedure BuildInvoiceLines(
       var Xml: TextBuilder;
       EDoc: Record "EDoc Document")
    var
        Line: Record "EDoc Document Line";
    begin
        OpenGroup(Xml, 'InvoiceLines');

        Line.SetRange(
            "Document Entry No.",
            EDoc."Entry No.");

        if Line.FindSet() then
            repeat
                BuildInvoiceLine(
                    Xml,
                    Line,
                    EDoc."Currency Code");
            until Line.Next() = 0;

        CloseGroup(Xml);
    end;

    procedure BuildInvoiceLine(
       var Xml: TextBuilder;
       Line: Record "EDoc Document Line";
       CurrencyCode: Code[10])
    begin
        OpenGroup(Xml, 'InvoiceLine');

        AddElement(
            Xml,
            'LineNo',
            Format(Line."Line No."));

        AddElement(
            Xml,
            'ItemNo',
            Line."No.");

        AddElement(
            Xml,
            'Description',
            Line.Description);

        AddElement(
            Xml,
            'UnitCode',
            Line."Unit Code");

        AddElement(
            Xml,
            'Quantity',
            FormatDecimal(Line.Quantity));

        AddAmount(
            Xml,
            'UnitPrice',
            CurrencyCode,
            Line."Unit Price");

        AddAmount(
            Xml,
            'LineAmount',
            CurrencyCode,
            Line."Line Amount");

        AddAmount(
            Xml,
            'TaxableAmount',
            CurrencyCode,
            Line."Taxable Amount");

        AddAmount(
            Xml,
            'TaxAmount',
            CurrencyCode,
            Line."Tax Amount");

        AddElement(
            Xml,
            'VATCategory',
            Line."VAT Category");

        AddElement(
            Xml,
            'VATPercent',
            FormatDecimal(Line."VAT %"));

        if Line."Tax Exemption Code" <> '' then
            AddElement(
                Xml,
                'TaxExemptionCode',
                Line."Tax Exemption Code");

        if Line."Tax Exemption Reason" <> '' then
            AddElement(
                Xml,
                'TaxExemptionReason',
                Line."Tax Exemption Reason");

        CloseGroup(Xml);
    end;

    procedure BuildVAT(
       var Xml: TextBuilder;
       EDoc: Record "EDoc Document")
    var
        VATBuffer: Record "EDoc VAT Buffer" temporary;
    begin
        BuildVATBuffer(
            VATBuffer,
            EDoc);

        OpenGroup(Xml, 'VAT');

        if VATBuffer.FindSet() then
            repeat

                OpenGroup(Xml, 'Rate');

                AddElement(
                    Xml,
                    'Category',
                    VATBuffer."VAT Category");

                AddElement(
                    Xml,
                    'Percent',
                    FormatDecimal(VATBuffer."VAT %"));

                AddAmount(
                    Xml,
                    'TaxableAmount',
                    EDoc."Currency Code",
                    VATBuffer."Taxable Amount");

                AddAmount(
                    Xml,
                    'TaxAmount',
                    EDoc."Currency Code",
                    VATBuffer."Tax Amount");

                if VATBuffer."Tax Exemption Code" <> '' then
                    AddElement(
                        Xml,
                        'ExemptionCode',
                        VATBuffer."Tax Exemption Code");

                if VATBuffer."Tax Exemption Reason" <> '' then
                    AddElement(
                        Xml,
                        'ExemptionReason',
                        VATBuffer."Tax Exemption Reason");

                CloseGroup(Xml);

            until VATBuffer.Next() = 0;

        CloseGroup(Xml);
    end;

    procedure BuildVATBuffer(
       var VATBuffer: Record "EDoc VAT Buffer" temporary;
       EDoc: Record "EDoc Document")
    var
        Line: Record "EDoc Document Line";
    begin
        VATBuffer.DeleteAll();

        Line.SetRange(
            "Document Entry No.",
            EDoc."Entry No.");

        if Line.FindSet() then
            repeat

                if not VATBuffer.Get(
                    Line."VAT Category",
                    Line."VAT %") then begin

                    VATBuffer.Init();
                    VATBuffer."VAT Category" := Line."VAT Category";
                    VATBuffer."VAT %" := Line."VAT %";
                    VATBuffer.Insert();
                end;

                VATBuffer."Taxable Amount" +=
                    Line."Taxable Amount";

                VATBuffer."Tax Amount" +=
                    Line."Tax Amount";

                VATBuffer."Tax Exemption Code" :=
                    Line."Tax Exemption Code";

                VATBuffer."Tax Exemption Reason" :=
                    Line."Tax Exemption Reason";

                VATBuffer.Modify();

            until Line.Next() = 0;
    end;

    procedure BuildPayment(
       var Xml: TextBuilder;
       EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Payment');

        AddElement(
            Xml,
            'PaymentMeansCode',
            EDoc."Payment Means Code");

        AddElement(
            Xml,
            'DueDate',
            FormatDate(
                EDoc."Due Date"));

        if EDoc."Collection Date" <> 0D then
            AddElement(
                Xml,
                'CollectionDate',
                FormatDate(
                    EDoc."Collection Date"));

        CloseGroup(Xml);
    end;


    procedure BuildCollection(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Collection');

        AddElement(
            Xml,
            'InvoiceNumber',
            EDoc."Invoice No.");

        AddElement(
            Xml,
            'PaymentMeansCode',
            EDoc."Payment Means Code");

        AddElement(
            Xml,
            'CollectionDate',
            FormatDate(
                EDoc."Collection Date"));

        AddAmount(
            Xml,
            'CollectedAmount',
            EDoc."Currency Code",
            EDoc."Collected Amount");

        CloseGroup(Xml);
    end;

    procedure BuildCounterparty(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'Counterparty');

        AddElement(
            Xml,
            'CustomerNo',
            EDoc."Customer No.");

        AddElement(
            Xml,
            'Name',
            EDoc."Customer Name");

        AddElement(
            Xml,
            'Country',
            EDoc."Customer Country");

        AddElement(
            Xml,
            'VATNumber',
            EDoc."Customer VAT No.");

        AddElement(
            Xml,
            'SIREN',
            EDoc."Customer SIREN");

        AddElement(
            Xml,
            'SIRET',
            EDoc."Customer SIRET");

        AddElement(
            Xml,
            'Endpoint',
            EDoc."Customer Endpoint");

        CloseGroup(Xml);
    end;

    procedure BuildPaymentReference(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'PaymentReference');

        AddElement(
            Xml,
            'InvoiceNumber',
            EDoc."Invoice No.");

        AddElement(
            Xml,
            'PaymentMeansCode',
            EDoc."Payment Means Code");

        AddElement(
            Xml,
            'DueDate',
            FormatDate(
                EDoc."Due Date"));

        CloseGroup(Xml);
    end;

    procedure BuildDocumentReference(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'DocumentReference');

        AddElement(
            Xml,
            'DocumentNo',
            EDoc."Document No.");

        AddElement(
            Xml,
            'InvoiceNo',
            EDoc."Invoice No.");

        AddElement(
            Xml,
            'IssueDate',
            FormatDate(
                EDoc."Issue Date"));

        CloseGroup(Xml);
    end;

    procedure BuildMonetarySummary(
        var Xml: TextBuilder;
        EDoc: Record "EDoc Document")
    begin
        OpenGroup(Xml, 'MonetarySummary');

        AddAmount(
            Xml,
            'NetAmount',
            EDoc."Currency Code",
            EDoc."Amount Excl. VAT");

        AddAmount(
            Xml,
            'VATAmount',
            EDoc."Currency Code",
            EDoc."VAT Amount");

        AddAmount(
            Xml,
            'GrossAmount',
            EDoc."Currency Code",
            EDoc."Amount Incl. VAT");

        CloseGroup(Xml);
    end;

    procedure EndDocument(var Xml: TextBuilder)
    begin
        CloseGroup(Xml);
    end;

    procedure OpenTransactions(var Xml: TextBuilder)
    begin
        OpenGroup(
            Xml,
            'Transactions');
    end;

    procedure CloseTransactions(var Xml: TextBuilder)
    begin
        CloseGroup(Xml);
    end;

    procedure BeginTransaction(var Xml: TextBuilder)
    begin
        OpenGroup(
            Xml,
            'Transaction');
    end;

    procedure EndTransaction(var Xml: TextBuilder)
    begin
        CloseGroup(Xml);
    end;

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

        Xml.AppendLine(
            '<' + Element + '>' +
            EscapeXml(Value) +
            '</' + Element + '>');
    end;

    local procedure AddAmount(
    var Xml: TextBuilder;
    Element: Text;
    CurrencyCode: Code[10];
    Amount: Decimal)
    begin
        Xml.AppendLine(
            '<' + Element +
            ' currencyID="' +
            CurrencyCode +
            '">' +
            FormatDecimal(Amount) +
            '</' +
            Element +
            '>');
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        exit(
            Format(
                Value,
                0,
                '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure FormatDecimal(Value: Decimal): Text
    begin
        exit(
            ConvertStr(
                Format(
                    Round(Value, 0.01),
                    0,
                    9),
                ',',
                '.'));
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