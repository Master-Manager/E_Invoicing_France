page 50100 "EDoc Setup"
{
    Caption = 'E-Document Setup';
    PageType = Card;
    SourceTable = "EDoc Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }

                field("Default Service Code"; Rec."Default Service Code")
                {
                    ApplicationArea = All;
                }

                field("Auto Send"; Rec."Auto Send")
                {
                    ApplicationArea = All;
                }

                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                }
            }

            group(Logging)
            {
                field("Log Requests"; Rec."Log Requests")
                {
                    ApplicationArea = All;
                }

                field("Log Responses"; Rec."Log Responses")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "EDoc Setup Mgt.";
    begin
        SetupMgt.GetSetup(Rec);
    end;
}