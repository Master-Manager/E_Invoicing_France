table 50100 "EDoc Setup"
{
    Caption = 'E-Document Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }

        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }

        field(20; "Default Service Code"; Code[20])
        {
            Caption = 'Default Service';

            TableRelation = "EDoc Service".Code;
        }

        field(30; "Auto Send"; Boolean)
        {
            Caption = 'Automatically Send';
            InitValue = true;
        }

        field(40; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            InitValue = 3;
        }

        field(50; "Log Requests"; Boolean)
        {
            Caption = 'Log Requests';
            InitValue = true;
        }

        field(60; "Log Responses"; Boolean)
        {
            Caption = 'Log Responses';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}