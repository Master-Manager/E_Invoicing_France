pageextension 70126 "Ext. Posted Purch. Inv. E-Rep" extends "Posted Purchase Invoice"
{
    layout
    {
        addlast(General)
        {
            field("Invoice Type Code"; Rec."Invoice Type Code")
            {
                ApplicationArea = All;
                Editable = false; // Souvent en lecture seule sur de l'enregistré
                ToolTip = 'Spécifie le code de type de facture (TT-21).';
            }
            field("Tax Due Date Type Code"; Rec."Tax Due Date Type Code")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Spécifie le code de date d''exigibilité de la TVA (TT-24).';
            }
            field("E-Rep Profile ID"; Rec."E-Rep Profile ID")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Spécifie le type de processus métier / cadre de facturation (TT-28).';
            }
        }
    }
}