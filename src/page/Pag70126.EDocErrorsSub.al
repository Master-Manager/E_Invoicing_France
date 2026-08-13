page 70126 "EDoc Errors Sub."
{
    Caption = 'Errors';
    PageType = ListPart;
    SourceTable = "EDoc Error";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Errors)
            {
                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("General Message"; Rec."General Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
}