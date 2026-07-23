page 50104 "EDoc Entry Card"
{
    PageType = Card;
    SourceTable = "EDoc Entry";
    ApplicationArea = All;
    Caption = 'E-Document Entry';

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

                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                }

                field("Sovos Document Id"; Rec."Sovos Document Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Sent At"; Rec."Sent At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Last Modified At"; Rec."Last Modified At")
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
            group(LOGS)
            {
                Caption = 'Logs';
                Image = XMLFile;
                action(ViewLogs)
                {
                    ApplicationArea = All;
                    Caption = 'Logs';
                    Image = Log;

                    trigger OnAction()
                    var
                        EDocLogs: Page "EDoc Logs";
                        LogRec: Record "EDoc Log";
                    begin
                        LogRec.SetRange("EDoc Entry No.", Rec."Entry No.");

                        EDocLogs.SetTableView(LogRec);
                        EDocLogs.RunModal();
                    end;
                }
            }
        }
    }
}