page 70114 "EDoc Line XML Buffer"
{
    Caption = 'EDoc Line XML Buffer';
    PageType = ListPart;
    SourceTable = "EDoc Line XML Buffer";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Source Line No."; Rec."Source Line No.") { ApplicationArea = All; }
                field("Sequence No."; Rec."Sequence No.") { ApplicationArea = All; }
                field("Field Name"; Rec."Field Name") { ApplicationArea = All; }
                field("Field Value"; Rec."Field Value") { ApplicationArea = All; }
                field("XML Tag"; Rec."XML Tag") { ApplicationArea = All; }
            }
        }
    }
}
