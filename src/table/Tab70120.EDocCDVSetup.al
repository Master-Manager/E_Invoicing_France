table 70120 "EDoc CDV Setup"
{
    Caption = 'EDoc CDV Setup (Flow 6)';
    DataClassification = CustomerContent;

    // TODO: if a setup table already exists for your Flux 2 (SOVOS) integration, DELETE this
    // table and point codeunit "EDoc CDV Flow6 Sender" at that existing setup instead -
    // you almost certainly don't want two separate places storing the same PPF credentials.

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "PPF Endpoint URL"; Text[250])
        {
            Caption = 'PPF Endpoint URL';
            // ex: https://sandbox.sovos.example/api/cdv/flow6  (TODO: confirm real endpoint)
        }
        field(20; "Authentication Type"; Option)
        {
            Caption = 'Authentication Type';
            OptionMembers = None,"API Key","OAuth2 Client Credentials";
            OptionCaption = 'None,API Key,OAuth2 Client Credentials';
        }
        field(30; "API Key Set"; Boolean)
        {
            Caption = 'API Key Set';
            Editable = false;
            // Actual secret lives in Isolated Storage, never in a plain table field - this
            // flag just tells the UI whether one has been entered, without exposing it.
        }
        field(40; "Max Send Attempts"; Integer)
        {
            Caption = 'Max Send Attempts';
            InitValue = 5;
        }
        field(50; "Request Timeout (sec.)"; Integer)
        {
            Caption = 'Request Timeout (sec.)';
            InitValue = 30;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        ApiKeyIsolatedStorageKeyTok: Label 'EDocCDVApiKey', Locked = true;

    procedure GetSetup(): Record "EDoc CDV Setup"
    var
        Setup: Record "EDoc CDV Setup";
    begin
        if not Setup.Get('') then begin
            Setup.Init();
            Setup."Max Send Attempts" := 5;
            Setup."Request Timeout (sec.)" := 30;
            Setup.Insert();
        end;
        exit(Setup);
    end;

    procedure SetApiKey(NewApiKey: Text)
    var
        Setup: Record "EDoc CDV Setup";
    begin
        Setup := GetSetup();
        IsolatedStorage.Set(ApiKeyIsolatedStorageKeyTok, NewApiKey, DataScope::Company);
        Setup."API Key Set" := true;
        Setup.Modify();
    end;

    procedure GetApiKey(): Text
    var
        ApiKey: Text;
    begin
        if IsolatedStorage.Get(ApiKeyIsolatedStorageKeyTok, DataScope::Company, ApiKey) then
            exit(ApiKey);
        exit('');
    end;
}
