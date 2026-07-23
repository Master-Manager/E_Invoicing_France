page 70122 "EDoc Sovos Notifications"
{
    Caption = 'EDoc Sovos Notifications';
    PageType = List;
    SourceTable = "EDoc Sovos Notification";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Sovos Document Entry No."; Rec."Sovos Document Entry No.") { ApplicationArea = All; }
                field("Created Date"; Rec."Created Date") { ApplicationArea = All; }
                field("SCI Response Code"; Rec."SCI Response Code") { ApplicationArea = All; }
                field("SCI Status Action"; Rec."SCI Status Action") { ApplicationArea = All; }
                field("SCI Cloud Status Code"; Rec."SCI Cloud Status Code") { ApplicationArea = All; }
                field("ERP Document Id"; Rec."ERP Document Id") { ApplicationArea = All; }
                field("Notification Id"; Rec."Notification Id") { ApplicationArea = All; }
                field("Retrieved At"; Rec."Retrieved At") { ApplicationArea = All; }
            }
        }
    }
}
