pageextension 70121 "Vendor Card EDoc Ext RFE" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            group("E-Document")
            {
                field("EDoc SIREN"; Rec."EDoc SIREN")
                {
                    ApplicationArea = All;
                }

                field("EDoc SIRET"; Rec."EDoc SIRET")
                {
                    ApplicationArea = All;
                }

                field("EDoc Endpoint ID"; Rec."EDoc Endpoint ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}