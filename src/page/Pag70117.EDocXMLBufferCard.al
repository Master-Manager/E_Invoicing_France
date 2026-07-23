page 70117 "EDoc XML Buffer Card"
{
    Caption = 'EDoc XML Buffer';
    PageType = Card;
    SourceTable = "EDoc Document";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Identification)
            {
                Caption = 'Identification';

                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Invoice No."; Rec."Invoice No.") { ApplicationArea = All; }
                field("Issue Date"; Rec."Issue Date") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Supplier Name"; Rec."Supplier Name") { ApplicationArea = All; }
                field("Customer Name"; Rec."Customer Name") { ApplicationArea = All; }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT") { ApplicationArea = All; }
            }

            part(HeaderFieldsSubform; "EDoc Header XML Buffer Sub.")
            {
                Caption = 'Champs d''en-tête';
                ApplicationArea = All;
                SubPageLink = "Buffer Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowLineBuffer)
            {
                ApplicationArea = All;
                Caption = 'Voir les lignes XML (Line Buffer)';
                Image = ShowList;
                ToolTip = 'Affiche les champs de lignes de facture ("EDoc Line XML Buffer") pour ce document.';

                trigger OnAction()
                var
                    LineBuffer: Record "EDoc Line XML Buffer";
                    LineBuffersPage: Page "EDoc Line XML Buffers";
                begin
                    LineBuffer.SetRange("Buffer Entry No.", Rec."Entry No.");
                    LineBuffersPage.SetTableView(LineBuffer);
                    LineBuffersPage.RunModal();
                end;
            }
        }
    }
}
