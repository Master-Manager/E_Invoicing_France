table 50102 "EDoc Entry"
{
    Caption = 'E-Document Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }

        field(10; "Document Type"; Enum "EDoc Document Type")
        {
        }

        field(20; "Document No."; Code[20])
        {
        }

        field(30; "External Document No."; Text[50])
        {
        }

        field(40; Status; Enum "EDoc Entry Status")
        {
        }

        field(50; "Service Code"; Code[20])
        {
        }

        field(60; "Request JSON"; Blob)
        {
        }

        field(70; "Response JSON"; Blob)
        {
        }

        field(80; "Sovos Document Id"; Text[100])
        {
        }

        field(90; "Error Message"; Text[2048])
        {
        }

        field(100; "Created At"; DateTime)
        {
        }

        field(110; "Sent At"; DateTime)
        {
        }

        field(120; "Last Modified At"; DateTime)
        {
        }

    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(K1; "Document No.")
        {
        }

        key(K2; Status)
        {
        }
    }
}