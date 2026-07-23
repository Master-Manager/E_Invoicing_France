tableextension 70120 "Customer EDoc Ext RFE" extends Customer
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

        field(70102; "EDoc Endpoint ID"; Code[50])
        {
            Caption = 'EDoc Endpoint ID';
            DataClassification = CustomerContent;
        }
    }
}