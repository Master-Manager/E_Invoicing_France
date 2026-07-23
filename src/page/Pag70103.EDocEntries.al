page 70103 "EDoc Entries"
{
    PageType = List;
    //ApplicationArea = All;
    //UsageCategory = Lists;
    SourceTable = "EDoc Entry";
    Caption = 'E-Document Entries';
    CardPageId = "EDoc Entry Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }

                field("Flow Type"; Rec."Flow Type")
                {
                    ApplicationArea = All;
                }

                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }

                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("Sovos Document Id"; Rec."Sovos Document Id")
                {
                    ApplicationArea = All;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field("Sent At"; Rec."Sent At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}