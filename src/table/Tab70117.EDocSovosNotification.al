table 70117 "EDoc Sovos Notification"
{
    Caption = 'EDoc Sovos Notification';
    DataClassification = CustomerContent;
    LookupPageId = "EDoc Sovos Notifications";
    DrillDownPageId = "EDoc Sovos Notifications";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }

        field(10; "Sovos Document Entry No."; Integer)
        {
            Caption = 'EDoc Sovos Document';
            TableRelation = "EDoc Sovos Document"."Entry No.";
        }

        field(20; "Notification Id"; Text[100])
        {
            Caption = 'Notification Id';
        }

        field(21; "Correlation Id"; Text[100])
        {
            Caption = 'Correlation Id';
        }

        field(22; "Created Date"; DateTime)
        {
            Caption = 'Créée le (Sovos)';
        }

        //------------------------------------
        // metadata block from the notification object
        //------------------------------------

        field(30; "Product Id"; Text[50])
        {
        }

        field(31; "ERP Document Id"; Text[100])
        {
            Caption = 'ERP Document Id (notre Invoice No.)';
        }

        field(32; "ERP System Id"; Text[50])
        {
        }

        field(33; "Process Type"; Text[10])
        {
        }

        field(34; "Tax Id"; Text[30])
        {
        }

        field(35; "SCI Cloud Status Code"; Text[10])
        {
        }

        field(36; "SCI Response Code"; Text[10])
        {
            Caption = 'SCI Response Code (AP/RE/...)';
        }

        field(37; "SCI Status Action"; Text[10])
        {
        }

        //------------------------------------
        // Content
        //------------------------------------

        field(40; "Content (Base64)"; Blob)
        {
            Caption = 'Contenu brut (Base64, réponse applicative UBL)';
            SubType = Memo;
        }

        field(50; "Retrieved At"; DateTime)
        {
        }

        field(60; "Raw Notification JSON"; Blob)
        {
            Caption = 'JSON brut de cette notification';
            SubType = Memo;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(BySovosDocument; "Sovos Document Entry No.", "Created Date")
        {
        }
        key(ByNotificationId; "Notification Id")
        {
        }
    }

    procedure SetContentBase64(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Content (Base64)");
        "Content (Base64)".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure SetRawJson(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Raw Notification JSON");
        "Raw Notification JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetRawJson(): Text
    var
        InStr: InStream;
        Content: Text;
        LineTxt: Text;
    begin
        CalcFields("Raw Notification JSON");
        if not "Raw Notification JSON".HasValue() then
            exit('');
        "Raw Notification JSON".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(LineTxt);
            Content += LineTxt;
        end;
        exit(Content);
    end;
}
