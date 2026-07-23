page 70106 "EDoc Logs"
{
    PageType = List;
    SourceTable = "EDoc Log";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'E-Document Logs';
    CardPageId = "EDoc Log Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                }

                field("EDoc Entry No."; Rec."EDoc Entry No.")
                {
                    ApplicationArea = All;
                }

                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                }

                field("Source Codeunit"; Rec."Source Codeunit")
                {
                    ApplicationArea = All;
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                }

                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}