table 50104 "EDoc Log"
{
    Caption = 'E-Document Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }

        field(10; "EDoc Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
        }

        field(20; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }

        field(30; Level; Enum "EDoc Log Level")
        {
            Caption = 'Level';
        }

        field(40; Message; Text[2048])
        {
            Caption = 'Message';
        }

        field(50; "Source Codeunit"; Text[100])
        {
            Caption = 'Source Codeunit';
        }
        field(60; Category; Enum "EDoc Log Category")
        {
            Caption = 'Category';
        }

        field(70; "Request JSON"; Blob)
        {
            Caption = 'Request';
            SubType = Memo;
        }

        field(80; "Response JSON"; Blob)
        {
            Caption = 'Response';
            SubType = Memo;
        }

        field(90; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
        }

    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(EDocEntry; "EDoc Entry No.")
        {
        }
    }
}