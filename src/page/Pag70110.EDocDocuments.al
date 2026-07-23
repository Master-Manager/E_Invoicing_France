page 70110 "EDoc Documents"
{
    PageType = List;
    SourceTable = "EDoc Document";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "EDoc Document Card";
    Caption = 'E-Documents';

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

                field("Invoice No."; Rec."Invoice No.")
                {
                    ApplicationArea = All;
                }

                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }

                field("Issue Date"; Rec."Issue Date")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
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
            }
        }
    }
}