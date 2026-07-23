page 70107 "EDoc Log Card"
{
    PageType = Card;
    SourceTable = "EDoc Log";
    Caption = 'E-Document Log';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                }

                field("Source Codeunit"; Rec."Source Codeunit")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(JSON)
            {
                Caption = 'HTTP';

                action(ViewRequest)
                {
                    ApplicationArea = All;
                    Caption = 'View Request';

                    trigger OnAction()
                    begin
                        ShowBlobRequest();
                    end;
                }

                action(ViewResponse)
                {
                    ApplicationArea = All;
                    Caption = 'View Response';

                    trigger OnAction()
                    begin
                        ShowBlobResponse();
                    end;
                }
            }
        }
    }

    local procedure ShowBlobRequest()
    var
        Viewer: Page "JSON Viewer";
        InStr: InStream;
        Txt: Text;
    begin
        Rec.CalcFields("Request JSON");

        if not Rec."Request JSON".HasValue() then
            Error('No request stored.');

        Rec."Request JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Txt);

        Viewer.SetContent('HTTP Request', Txt);
        Viewer.RunModal();
    end;

    local procedure ShowBlobResponse()
    var
        Viewer: Page "JSON Viewer";
        InStr: InStream;
        Txt: Text;
    begin
        Rec.CalcFields("Response JSON");

        if not Rec."Response JSON".HasValue() then
            Error('No response stored.');

        Rec."Response JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Txt);

        Viewer.SetContent('HTTP Response', Txt);
        Viewer.RunModal();
    end;



}