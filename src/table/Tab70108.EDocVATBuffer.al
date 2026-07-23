table 70108 "EDoc VAT Buffer"
{
    TableType = Temporary;

    fields
    {
        field(1; "VAT Category"; Code[10]) { }
        field(2; "VAT %"; Decimal) { }
        field(3; "Taxable Amount"; Decimal) { }
        field(4; "Tax Amount"; Decimal) { }
        field(5; "Tax Exemption Code"; Code[30]) { }
        field(6; "Tax Exemption Reason"; Text[250]) { }
    }

    keys
    {
        key(PK; "VAT Category", "VAT %")
        {
            Clustered = true;
        }
    }
}