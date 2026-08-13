tableextension 70123 "Ext. Purchase Header E-Rep" extends "Purchase Header"
{
    fields
    {
        field(50000; "Invoice Type Code"; Code[10])
        {
            Caption = 'Invoice Type Code';
            DataClassification = CustomerContent;
        }
        field(50001; "Tax Due Date Type Code"; Code[10])
        {
            Caption = 'Tax Due Date Type Code';
            DataClassification = CustomerContent;
        }
        field(50002; "E-Rep Profile ID"; Code[20])
        {
            Caption = 'Business Process Type (ID)';
            DataClassification = CustomerContent;
        }
    }
}