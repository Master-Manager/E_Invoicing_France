tableextension 70121 "Vendor EDoc Ext RFE" extends Vendor
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
        field(70103; "Vendor Nature"; Code[50])
        {
            Caption = 'Vendor Client';
            DataClassification = CustomerContent;
        }
        field(70104; "Assujetti TVA"; boolean)
        {
            Caption = 'Assujetti TVA';
            DataClassification = CustomerContent;
        }
    }
}