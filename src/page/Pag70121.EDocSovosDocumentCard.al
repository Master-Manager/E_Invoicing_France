page 70121 "EDoc Sovos Document Card"
{
    Caption = 'EDoc Sovos Document';
    PageType = Card;
    SourceTable = "EDoc Sovos Document";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field("EDoc Document Entry No."; Rec."EDoc Document Entry No.") { ApplicationArea = All; Editable = false; }
                field("Invoice No."; Rec."Invoice No.") { ApplicationArea = All; Editable = false; }
                field("Supplier Name"; Rec."Supplier Name") { ApplicationArea = All; Editable = false; }
                field("Customer Name"; Rec."Customer Name") { ApplicationArea = All; Editable = false; }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT") { ApplicationArea = All; Editable = false; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; Editable = false; }
            }

            group(Sovos)
            {
                Caption = 'Sovos';

                field("Document Id"; Rec."Document Id") { ApplicationArea = All; Editable = false; }
                field("Transaction Id"; Rec."Transaction Id") { ApplicationArea = All; Editable = false; }
                field("Country Code"; Rec."Country Code") { ApplicationArea = All; }
                field("Sent At"; Rec."Sent At") { ApplicationArea = All; Editable = false; }
                field("Sovos Status"; Rec."Sovos Status")
                {
                    Editable = false;
                    StyleExpr = StatusStyleTxt;
                }
                field("Last Notification Check At"; Rec."Last Notification Check At") { ApplicationArea = All; Editable = false; }
            }

            part(Notifications; "EDoc Sovos Notifications Sub.")
            {
                Caption = 'Notifications reçues';
                ApplicationArea = All;
                SubPageLink = "Sovos Document Entry No." = field("Entry No.");
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

            action(ViewSubmissionResponse)
            {
                ApplicationArea = All;
                Caption = 'Voir la réponse de soumission';
                Image = View;

                trigger OnAction()
                var
                    Viewer: Page "JSON Viewer";
                begin
                    Viewer.SetContent('Réponse de soumission Sovos', Rec.GetSubmissionResponse());
                    Viewer.Run();
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
