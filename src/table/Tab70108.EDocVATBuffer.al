table 70108 "EDoc VAT Buffer"
{
    TableType = Temporary;

    fields
    {
        field(15; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(1; "VAT Category"; Code[10]) { }
        field(2; "VAT %"; Decimal) { }
        field(3; "Taxable Amount"; Decimal) { }
        field(4; "Tax Amount"; Decimal) { }
        field(5; "Tax Exemption Code"; Code[30]) { }
        field(6; "Tax Exemption Reason"; Text[250]) { }
        field(8; "EDoc Code"; Code[20])
        {
            Caption = 'EDoc Code';
            DataClassification = CustomerContent;
        }
        field(9; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(10; "Base Amount"; Decimal)
        {
            Caption = 'Base Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Taxable Amount" := "Base Amount";
            end;
        }
        field(11; "VAT Amount"; Decimal)
        {
            Caption = 'VAT Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Tax Amount" := "VAT Amount";
            end;
        }
        field(12; "VAT Rate"; Decimal)
        {
            Caption = 'VAT Rate';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "VAT %" := "VAT Rate";
            end;
        }

        // --- Added Field ---
        field(13; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(CategoryKey; "VAT Category", "VAT Rate")
        {
        }
        key(DocKey; "Document No.", "VAT Category", "VAT Rate")
        {
        }
    }
}