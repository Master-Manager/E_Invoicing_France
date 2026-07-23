table 70102 "EDoc Entry"
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

        field(11; "Flow Type"; Enum "EDoc Flow Type")
        {
            Caption = 'Flux SOVOS';
        }

        field(12; Direction; Enum "EDoc Direction")
        {
        }

        field(13; "Document Record ID"; RecordId)
        {
            Caption = 'Document Record ID';
            DataClassification = SystemMetadata;
        }

        field(14; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(15; "Source Type"; Enum "EDoc Source Type")
        {
        }

        field(16; "Source No."; Code[20])
        {
            Caption = 'Source No. (Customer/Vendor)';
        }

        field(20; "Document No."; Code[20])
        {
        }

        field(21; "Document Date"; Date)
        {
        }

        field(22; "Due Date"; Date)
        {
        }

        field(23; "Amount Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
        }

        field(24; "Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
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
        field(121; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
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

        key(K3; Direction, "Flow Type")
        {
        }
    }

    /// <summary>
    /// Populates "Document Record ID" and "Table ID" from a source document RecordRef,
    /// mirroring how the real E-Document table links back to its BC source document.
    /// </summary>
    procedure SetSourceDocument(var SourceDocumentHeader: RecordRef)
    begin
        "Document Record ID" := SourceDocumentHeader.RecordId;
        "Table ID" := SourceDocumentHeader.Number;
    end;
}