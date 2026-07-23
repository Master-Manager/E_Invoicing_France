page 70108 "EDoc VAT Category Map"
{
    Caption = 'EDoc VAT Category Mapping';
    PageType = List;
    SourceTable = "EDoc VAT Category Map";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group") { ApplicationArea = All; }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { ApplicationArea = All; }
                field("VAT %"; Rec."VAT %") { ApplicationArea = All; }
                field("UBL Tax Category"; Rec."UBL Tax Category") { ApplicationArea = All; }
            }
        }
    }
}