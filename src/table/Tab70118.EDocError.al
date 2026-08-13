table 70118 "EDoc Error"
{
    Caption = 'EDoc Error';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }

        field(10; "EDoc Entry No."; Integer)
        {
            Caption = 'E-Document';
            TableRelation = "EDoc Document"."Entry No.";
        }

        field(20; "Notification Entry No."; Integer)
        {
            Caption = 'Notification';
            TableRelation = "EDoc Sovos Notification"."Entry No.";
        }

        field(30; "Error Code"; Text[50])
        {
            Caption = 'Error Code';
        }

        field(40; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
        }

        field(50; "General Message"; Text[250])
        {
            Caption = 'General Message';
        }

        field(60; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(ByEDoc; "EDoc Entry No.", "Entry No.")
        {
        }

        key(ByNotification; "Notification Entry No.")
        {
        }
    }
}