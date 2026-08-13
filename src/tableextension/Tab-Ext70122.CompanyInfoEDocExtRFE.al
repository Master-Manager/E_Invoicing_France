tableextension 70122 "Company Info EDoc Ext RFE" extends "Company Information"
{
    fields
    {
        field(70100; "EDoc SIREN"; Code[9])
        {
            Caption = 'SIREN';
            DataClassification = CustomerContent;
        }

        field(70101; "EDoc SIRET"; Code[14])
        {
            Caption = 'SIRET';
            DataClassification = CustomerContent;
        }

        field(70102; "EDoc Endpoint ID"; Code[100])
        {
            Caption = 'EDoc Endpoint ID';
            DataClassification = CustomerContent;
        }
    }
}