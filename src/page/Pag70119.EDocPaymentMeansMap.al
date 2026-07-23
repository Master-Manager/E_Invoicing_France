page 70119 "EDoc Payment Means Map"
{
    Caption = 'EDoc Payment Means Mapping';
    PageType = List;
    SourceTable = "EDoc Payment Means Map";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Payment Method Code"; Rec."Payment Method Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("UNTDID Payment Means Code"; Rec."UNTDID Payment Means Code") { ApplicationArea = All; }
            }
        }
    }
}
