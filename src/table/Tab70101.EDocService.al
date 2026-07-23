table 70101 "EDoc Service"
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

        field(81; "Seller SIREN"; Code[9])
        {
            Caption = 'SIREN émetteur (9 chiffres)';
        }

        field(82; "Sender ERP System Id"; Text[50])
        {
            Caption = 'SenderSystemId (SBDH)';
            InitValue = 'DefaultSystemERP';
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

        field(180; "Sovos Organization Id"; Text[50])
        {
            Caption = 'Sovos Organization Id (optionnel)';
            // Only used for multi-organization Sovos setups submitting as workspace_admin.
            // Leave blank if not applicable - the BusinessScope "OrganizationId" entry is
            // only emitted when this has a value.
        }

        field(190; "Payee Bank Account Code"; Code[20])
        {
            Caption = 'Compte bancaire bénéficiaire';
            TableRelation = "Bank Account";
            // Source for cac:PaymentMeans/cac:PayeeFinancialAccount (BT-84/85/86). Points at a
            // real Bank Account record rather than duplicating IBAN/BIC as free text here.
        }

        field(200; "Late Payment Penalty Note"; Text[250])
        {
            Caption = 'Mention pénalités de retard (#PMD#)';
            // BT-21=PMD / BT-22. Mandatory on French B2B invoices (Code de commerce
            // Art. L.441-6 / D.441-5). Leave blank until Pluxee's legal/fiscal team has
            // confirmed the exact wording - the builder skips this Note entirely if blank
            // rather than emit placeholder legal text.
        }

        field(210; "Recovery Fee Note"; Text[250])
        {
            Caption = 'Mention indemnité de recouvrement (#PMT#)';
            // BT-21=PMT / BT-22. Same mandatory-disclosure caveat as above.
        }

        field(220; "Early Payment Discount Note"; Text[250])
        {
            Caption = 'Mention escompte (#AAB#)';
            // BT-21=AAB / BT-22. Same mandatory-disclosure caveat as above.
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