table 50101 "EDoc Service"
{
    Caption = 'E-Document Service';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
        }

        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }

        field(10; Provider; Enum "EDoc Provider")
        {
        }

        field(20; Environment; Enum "EDoc Environment")
        {
        }

        field(30; Enabled; Boolean)
        {
        }

        field(40; "Base URL"; Text[250])
        {
        }

        field(50; "OAuth URL"; Text[250])
        {
        }

        field(60; "Client ID"; Text[150])
        {
        }

        field(70; "Client Secret"; Text[250])
        {
        }

        field(80; "Company VAT No."; Code[30])
        {
        }

        field(90; "Sender Identifier"; Code[50])
        {
        }

        field(100; Timeout; Integer)
        {
            InitValue = 60;
        }

        field(110; "Access Token"; Text[2048])
        {
            Caption = 'Access Token';
        }

        field(120; "Token Expiration"; DateTime)
        {
            Caption = 'Token Expiration';
        }

        field(130; "Token Type"; Text[30])
        {
            Caption = 'Token Type';
        }

        field(140; "Token Expires In"; Integer)
        {
            Caption = 'Token Expires In (Seconds)';
        }
        field(150; "Invoice Endpoint"; Text[250])
        {
            Caption = 'Invoice Endpoint';
        }

        field(160; "E-Reporting Endpoint"; Text[250])
        {
            Caption = 'E-Reporting Endpoint';
        }

        field(170; "Status Endpoint"; Text[250])
        {
            Caption = 'Status Endpoint';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}