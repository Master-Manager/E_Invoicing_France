table 70119 "EDoc CDV Outbound Queue"
{
    Caption = 'EDoc CDV Outbound Queue (Flow 6)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Invoice No."; Code[35])
        {
            Caption = 'Invoice No.';
        }
        field(20; "Created DateTime"; DateTime)
        {
            Caption = 'Created';
        }
        field(30; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Pending,Sent,Error;
            OptionCaption = 'Pending,Sent,Error';
        }
        field(40; "Attempts"; Integer)
        {
            Caption = 'Attempts';
        }
        field(50; "Last Attempt DateTime"; DateTime)
        {
            Caption = 'Last Attempt';
        }
        field(60; "Last HTTP Status Code"; Integer)
        {
            Caption = 'Last HTTP Status Code';
        }
        field(70; "Last Error"; Text[250])
        {
            Caption = 'Last Error';
        }
        field(80; "Xml Content"; Blob)
        {
            Caption = 'Xml Content';
        }
        field(90; "Last Response"; Blob)
        {
            Caption = 'Last Response';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ByStatus; Status, "Created DateTime")
        {
        }
    }

    procedure SetXml(XmlText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Xml Content");
        "Xml Content".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(XmlText);
    end;

    procedure GetXml(): Text
    var
        InStr: InStream;
        XmlBuilder: TextBuilder;
        Line: Text;
    begin
        CalcFields("Xml Content");
        "Xml Content".CreateInStream(InStr, TextEncoding::UTF8);
        while InStr.ReadText(Line) > 0 do
            XmlBuilder.AppendLine(Line);
        exit(XmlBuilder.ToText());
    end;

    procedure SetResponse(ResponseText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Last Response");
        "Last Response".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseText);
    end;
}
