table 70105 "EDoc VAT Category Map"
{
    Caption = 'EDoc VAT Category Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Bus. Posting Group"; Code[20])
        {
            TableRelation = "VAT Business Posting Group";
        }
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            TableRelation = "VAT Product Posting Group";
        }
        field(10; "UBL Tax Category"; Code[2])
        {
            Caption = 'Code catégorie TVA UBL (S/E/AE/K/G/O/Z)';
        }
        field(20; "VAT %"; Decimal)
        {
            Caption = 'Taux TVA (référence)';
        }
    }

    keys
    {
        key(PK; "VAT Bus. Posting Group", "VAT Prod. Posting Group")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Resolves the UBL tax category for a posting group combination. Falls back to a
    /// rate-based default (S for >0%, E for 0%) ONLY if no explicit mapping row exists -
    /// this default is a reasonable starting point, not a substitute for confirming the
    /// correct category (S/E/AE/K/G/O/Z) per transaction type with your fiscal/SOVOS advisor.
    /// </summary>
    procedure ResolveCategory(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATRate: Decimal): Code[2]
    var
        Map: Record "EDoc VAT Category Map";
    begin
        if Map.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit(Map."UBL Tax Category");

        if VATRate = 0 then
            exit('E');
        exit('S');
    end;
}