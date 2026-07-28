page 70112 "EDoc Document Subform"
{
    PageType = ListPart;
    SourceTable = "EDoc Document Line";
    Caption = 'Lines';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }

                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                }

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                }

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }

                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                }

                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }

                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = All;
                }

                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = All;
                }

                field("VAT Category"; Rec."VAT Category")
                {
                    ApplicationArea = All;
                }
                field("Tax Exemption Code"; Rec."Tax Exemption Code")
                {
                    ApplicationArea = All;
                }
                field("Tax Exemption Reason"; Rec."Tax Exemption Reason")
                {
                    ApplicationArea = All;
                }

                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                }

                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}