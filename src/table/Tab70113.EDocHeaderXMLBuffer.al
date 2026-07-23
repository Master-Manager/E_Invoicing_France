table 70113 "EDoc Header XML Buffer"
{
    Caption = 'EDoc Header XML Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Buffer Entry No."; Integer)
        {
            TableRelation = "EDoc Document"."Entry No.";
        }
        field(2; "Sequence No."; Integer)
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
        field(20; "Line Buffer Count"; Integer)
        {
            Caption = 'Lignes liées';
            FieldClass = FlowField;
            CalcFormula = count("EDoc Line XML Buffer" where("Buffer Entry No." = field("Buffer Entry No.")));
            Editable = false;
        }

    }

    keys
    {
        key(PK; "Buffer Entry No.", "Sequence No.")
        {
            Clustered = true;
        }
    }
}

