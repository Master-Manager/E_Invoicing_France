table 70116 "EDoc Sovos Document"
{
    Caption = 'EDoc Sovos Document';
    DataClassification = CustomerContent;
    LookupPageId = "EDoc Sovos Documents";
    DrillDownPageId = "EDoc Sovos Documents";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }

        field(10; "EDoc Document Entry No."; Integer)
        {
            Caption = 'E-Document';
            TableRelation = "EDoc Document"."Entry No.";
        }

        //------------------------------------
        // Sovos identifiers
        //------------------------------------

        field(20; "Document Id"; Text[100])
        {
            Caption = 'Sovos Document Id';
        }

        field(21; "Transaction Id"; Text[100])
        {
            Caption = 'Sovos Transaction Id';
        }

        field(22; "Country Code"; Code[2])
        {
            Caption = 'Country Code';
            InitValue = 'FR';
            // Used to build /v1/documents/{countryCode}/{documentId}/notifications.
        }

        //------------------------------------
        // Quick-reference info copied from the source EDoc Document at submission
        // time, so this list doesn't need a join back to inspect at a glance.
        //------------------------------------

        field(30; "Invoice No."; Code[35])
        {
        }

        field(31; "Supplier Name"; Text[100])
        {
        }

        field(32; "Customer Name"; Text[100])
        {
        }

        field(33; "Amount Incl. VAT"; Decimal)
        {
            AutoFormatType = 1;
        }

        field(34; "Currency Code"; Code[10])
        {
        }

        //------------------------------------
        // Tracking
        //------------------------------------

        field(40; "Sent At"; DateTime)
        {
        }

        field(41; "Last Notification Check At"; DateTime)
        {
        }
        field(42; "Sovos Status"; Enum "EDoc Sovos Doc Status")
        {
            Caption = 'Sovos Status';

        }
        field(50; "Submission Response"; Blob)
        {
            Caption = 'Réponse de soumission (JSON brut)';
            SubType = Memo;
        }

        field(60; "Notification Count"; Integer)
        {
            Caption = 'Notifications reçues';
            FieldClass = FlowField;
            CalcFormula = count("EDoc Sovos Notification" where("Sovos Document Entry No." = field("Entry No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ByDocumentId; "Document Id")
        {
        }
        key(BySource; "EDoc Document Entry No.")
        {
        }
    }

    procedure SetSubmissionResponse(ResponseText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Submission Response");
        "Submission Response".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseText);
    end;

    procedure GetSubmissionResponse(): Text
    var
        InStr: InStream;
        Content: Text;
        LineTxt: Text;
    begin
        CalcFields("Submission Response");
        if not "Submission Response".HasValue() then
            exit('');
        "Submission Response".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(LineTxt);
            Content += LineTxt;
        end;
        exit(Content);
    end;

    procedure UpdateSovosStatus()
    var
        Notification: Record "EDoc Sovos Notification";
    begin
        Notification.SetRange("Sovos Document Entry No.", "Entry No.");

        Notification.SetCurrentKey("Sovos Document Entry No.", "Created Date");
        Notification.Ascending(false);

        if not Notification.FindFirst() then begin
            "Sovos Status" := "Sovos Status"::Submitted;
            exit;
        end;

        case Notification."SCI Response Code" of
            'RE':
                "Sovos Status" := "Sovos Status"::Rejected;

            'AP':
                "Sovos Status" := "Sovos Status"::Accepted;

            'AB':
                "Sovos Status" := "Sovos Status"::Accepted;

            else
                "Sovos Status" := "Sovos Status"::Submitted;
        end;
    end;
}
