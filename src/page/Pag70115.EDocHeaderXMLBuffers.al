page 70115 "EDoc Header XML Buffers"
{
    Caption = 'EDoc XML Buffers';
    PageType = List;
    SourceTable = "EDoc Document";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    CardPageId = "EDoc XML Buffer Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Invoice No."; Rec."Invoice No.") { ApplicationArea = All; }
                field("Issue Date"; Rec."Issue Date") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Supplier Name"; Rec."Supplier Name") { ApplicationArea = All; }
                field("Customer Name"; Rec."Customer Name") { ApplicationArea = All; }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT") { ApplicationArea = All; }
                field("Header Buffer Field Count"; Rec."Header Buffer Field Count") { ApplicationArea = All; }

            }
        }
    }
}
