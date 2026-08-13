table 70107 "EDoc Document Line"
{
    Caption = 'E-Document Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Entry No."; Integer)
        {
            Caption = 'Document Entry No.';
            TableRelation = "EDoc Document";
        }

        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }

        field(4; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }

        field(5; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        //------------------------------------
        // Source
        //------------------------------------

        field(10; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }

        field(20; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
        }

        field(30; "No."; Code[20])
        {
            Caption = 'No.';
        }

        //------------------------------------
        // Description
        //------------------------------------

        field(100; Description; Text[100])
        {
        }

        field(110; "Description 2"; Text[100])
        {
        }

        //------------------------------------
        // Quantities
        //------------------------------------

        field(200; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(210; "Unit of Measure"; Code[20])
        {
        }

        field(220; "Unit Code"; Code[10])
        {
            Caption = 'UBL Unit Code';
        }

        //------------------------------------
        // Prices
        //------------------------------------

        field(300; "Unit Price"; Decimal)
        {
            DecimalPlaces = 2 : 5;
        }

        field(310; "Line Amount"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        field(320; "Line Discount Amount"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        //------------------------------------
        // VAT
        //------------------------------------

        field(400; "VAT %"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(410; "VAT Category"; Code[10])
        {
        }

        field(420; "Tax Exemption Reason"; Text[250])
        {
        }

        field(430; "Tax Exemption Code"; Code[30])
        {
        }

        //------------------------------------
        // References
        //------------------------------------

        field(500; "Order No."; Code[35])
        {
        }

        field(510; "Order Line No."; Integer)
        {
        }

        //------------------------------------
        // Amounts
        //------------------------------------

        field(600; "Taxable Amount"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        field(610; "Tax Amount"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        field(620; "Amount Including VAT"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        //------------------------------------
        // Future UBL Fields
        //------------------------------------

        field(700; "Base Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(710; "Price Base Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }

        field(720; "Buyer Item No."; Code[35])
        {
        }

        field(730; "Seller Item No."; Code[35])
        {
        }

        field(740; "Commodity Code"; Code[35])
        {
        }

        field(750; "Country of Origin"; Code[10])
        {
        }

        field(760; "Start Date"; Date)
        {
        }

        field(770; "End Date"; Date)
        {
        }
    }

    keys
    {
        key(PK; "Document Entry No.", "Line No.")
        {
            Clustered = true;
        }

        key(Item; "No.")
        {
        }
    }
}