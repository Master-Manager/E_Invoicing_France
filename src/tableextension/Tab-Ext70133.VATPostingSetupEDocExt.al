tableextension 70133 "VAT Posting Setup EDoc Ext" extends "VAT Posting Setup"
{
    fields
    {
        field(70100; "Sovos VAT Category"; Code[10])
        {
            Caption = 'Sovos VAT Category';
            DataClassification = CustomerContent;
        }

        field(70101; "Sovos Exemption Code"; Code[20])
        {
            Caption = 'Sovos Exemption Code';
            DataClassification = CustomerContent;
        }

        field(70102; "Sovos Exemption Reason"; Text[250])
        {
            Caption = 'Sovos Exemption Reason';
            DataClassification = CustomerContent;
        }
    }
}