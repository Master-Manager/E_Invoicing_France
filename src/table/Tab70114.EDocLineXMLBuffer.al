table 70114 "EDoc Line XML Buffer"
{
    Caption = 'EDoc Line XML Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Buffer Entry No."; Integer)
        {
            TableRelation = "EDoc Document"."Entry No.";
        }
        field(2; "Source Line No."; Integer)
        {
            Caption = 'Ligne (EDoc Document Line)';
        }
        field(3; "Sequence No."; Integer)
        {
        }
        field(10; "Field Name"; Text[100])
        {
            Caption = 'Champ BC';
        }
        field(11; "Field Value"; Text[250])
        {
            Caption = 'Valeur';
        }
        field(12; "XML Tag"; Text[2048])
        {
            Caption = 'Balise XML';
        }
    }

    keys
    {
        key(PK; "Buffer Entry No.", "Source Line No.", "Sequence No.")
        {
            Clustered = true;
        }
    }
}

