page 70120 "EDoc Sovos Documents"
{
    Caption = 'EDoc Sovos Documents';
    PageType = List;
    SourceTable = "EDoc Sovos Document";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    CardPageId = "EDoc Sovos Document Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Invoice No."; Rec."Invoice No.") { ApplicationArea = All; }
                field("Document Id"; Rec."Document Id") { ApplicationArea = All; }
                field("Customer Name"; Rec."Customer Name") { ApplicationArea = All; }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT") { ApplicationArea = All; }
                field("Sent At"; Rec."Sent At") { ApplicationArea = All; }
                field("Sovos Status"; Rec."Sovos Status")
                {
                    StyleExpr = StatusStyleTxt;
                }
                field("Last Notification Check At"; Rec."Last Notification Check At") { ApplicationArea = All; }
                field("Notification Count"; Rec."Notification Count") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetNotifications)
            {
                ApplicationArea = All;
                Caption = 'Récupérer les notifications';
                Image = Refresh;
                ToolTip = 'Appelle GET /v1/documents/{countryCode}/{documentId}/notifications pour ce document.';

                trigger OnAction()
                var
                    SovosDocMgt: Codeunit "EDoc Sovos Document Mgt.";
                begin
                    SovosDocMgt.PullNotifications(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Rec.UpdateSovosStatus();
        SetStyleExpression();
    end;

    var
        StatusStyleTxt: Text;

    local procedure SetStyleExpression()
    begin
        case Rec."Sovos Status" of
            Rec."Sovos Status"::Accepted:
                StatusStyleTxt := 'Favorable';
            Rec."Sovos Status"::Rejected:
                StatusStyleTxt := 'Unfavorable';
            else
                StatusStyleTxt := 'StrongAccent';
        end;
    end;
}
