page 70102 "EDoc Services"
{
    Caption = 'E-Document Services';
    PageType = List;
    SourceTable = "EDoc Service";
    CardPageId = "EDoc Service Card";

    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = False;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field(Provider; Rec.Provider)
                {
                    ApplicationArea = All;
                }

                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}