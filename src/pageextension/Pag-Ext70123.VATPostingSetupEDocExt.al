pageextension 70123 "VAT Posting Setup EDoc Ext" extends "VAT Posting Setup"
{
    layout
    {
        addafter("VAT Prod. Posting Group")
        {
            field("Sovos VAT Category"; Rec."Sovos VAT Category")
            {
                ApplicationArea = All;
                ToolTip = 'UBL/EN16931 VAT Category (S, Z, E, AE, G, K, O...).';
            }

            field("Sovos Exemption Code"; Rec."Sovos Exemption Code")
            {
                ApplicationArea = All;
                ToolTip = 'UBL Tax Exemption Reason Code.';
            }

            field("Sovos Exemption Reason"; Rec."Sovos Exemption Reason")
            {
                ApplicationArea = All;
                ToolTip = 'UBL Tax Exemption Reason.';
            }
        }
    }
}