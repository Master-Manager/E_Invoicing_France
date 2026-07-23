table 70103 "JSON Viewer"
{
    Caption = 'JSON Viewer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
        }

        field(2; Content; Blob)
        {
            SubType = Memo;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}