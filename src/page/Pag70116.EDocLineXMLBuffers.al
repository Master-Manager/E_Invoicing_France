page 70116 "EDoc Line XML Buffers"
{
    Caption = 'EDoc Line XML Buffers';
    PageType = List;
    SourceTable = "EDoc Line XML Buffer";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Buffer Entry No."; Rec."Buffer Entry No.") { ApplicationArea = All; }
                field("Source Line No."; Rec."Source Line No.") { ApplicationArea = All; }
                field("Sequence No."; Rec."Sequence No.") { ApplicationArea = All; }
                field("Field Name"; Rec."Field Name") { ApplicationArea = All; }
                field("Field Value"; Rec."Field Value") { ApplicationArea = All; }
                field("XML Tag"; Rec."XML Tag") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowHeader)
            {
                ApplicationArea = All;
                Caption = 'Voir l''en-tête';
                Image = ShowList;
                ToolTip = 'Ouvre la fiche d''identification EDoc XML Buffer pour ce même document (Buffer Entry No.).';

                trigger OnAction()
                var
                    EDoc: Record "EDoc Document";
                    BufferCard: Page "EDoc XML Buffer Card";
                begin
                    if not EDoc.Get(Rec."Buffer Entry No.") then
                        exit;
                    BufferCard.SetRecord(EDoc);
                    BufferCard.RunModal();
                end;
            }
        }
    }
}
