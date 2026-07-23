page 50101 "EDoc Service Card"
{
    Caption = 'E-Document Service';
    PageType = Card;
    SourceTable = "EDoc Service";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }

                field(Provider; Rec.Provider)
                {
                    ApplicationArea = All;
                }

                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                }
            }

            group(Connection)
            {
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                }

                field("OAuth URL"; Rec."OAuth URL")
                {
                    ApplicationArea = All;
                }

                field("Client ID"; Rec."Client ID")
                {
                    ApplicationArea = All;
                }

                field("Client Secret"; Rec."Client Secret")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }

                field(Timeout; Rec.Timeout)
                {
                    ApplicationArea = All;
                }
            }

            group(Company)
            {
                field("Company VAT No."; Rec."Company VAT No.")
                {
                    ApplicationArea = All;
                }

                field("Sender Identifier"; Rec."Sender Identifier")
                {
                    ApplicationArea = All;
                }
            }

            group(Authentication)
            {
                field("Access Token"; Rec."Access Token")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Token Type"; Rec."Token Type")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Token Expires In"; Rec."Token Expires In")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Token Expiration"; Rec."Token Expiration")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
            }
            group(Endpoints)
            {
                field("Invoice Endpoint"; Rec."Invoice Endpoint")
                {
                    ApplicationArea = All;
                }

                field("E-Reporting Endpoint"; Rec."E-Reporting Endpoint")
                {
                    ApplicationArea = All;
                }

                field("Status Endpoint"; Rec."Status Endpoint")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(RefreshToken)
            {
                ApplicationArea = All;
                Caption = 'Refresh Token';
                Image = Refresh;

                trigger OnAction()
                var
                    OAuthManager: Codeunit "OAuth Manager";
                begin
                    OAuthManager.GetAccessToken();
                end;
            }
        }
    }
}