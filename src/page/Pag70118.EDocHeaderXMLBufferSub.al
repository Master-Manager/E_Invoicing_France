page 70118 "EDoc Header XML Buffer Sub."
{
    Caption = 'Champs d''en-tête';
    PageType = ListPart;
    SourceTable = "EDoc Header XML Buffer";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Sequence No."; Rec."Sequence No.") { ApplicationArea = All; }
                field("Field Name"; Rec."Field Name") { ApplicationArea = All; }
                field("Field Value"; Rec."Field Value") { ApplicationArea = All; }
                field("XML Tag"; Rec."XML Tag") { ApplicationArea = All; }
            }
        }
    }
}
