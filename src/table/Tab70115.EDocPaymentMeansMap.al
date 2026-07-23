table 70115 "EDoc Payment Means Map"
{
    Caption = 'EDoc Payment Means Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Payment Method Code"; Code[10])
        {
            TableRelation = "Payment Method";
        }
        field(10; "UNTDID Payment Means Code"; Code[3])
        {
            Caption = 'Code UNTDID 4461 (BT-81)';
        }
        field(20; Description; Text[100])
        {
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Payment Method".Description where(Code = field("Payment Method Code")));
        }
    }

    keys
    {
        key(PK; "Payment Method Code")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Resolves the UNTDID 4461 code for a BC Payment Method Code. Falls back to "30"
    /// (Credit transfer) - the most common B2B default - only if no explicit mapping exists.
    /// </summary>
    procedure ResolveCode(PaymentMethodCode: Code[10]): Code[3]
    var
        Map: Record "EDoc Payment Means Map";
    begin
        if PaymentMethodCode = '' then
            exit('30');
        if Map.Get(PaymentMethodCode) then
            exit(Map."UNTDID Payment Means Code");
        exit('30');
    end;
}