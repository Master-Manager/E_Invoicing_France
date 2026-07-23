page 70123 "EDoc Sovos Notifications Sub."
{
    Caption = 'Notifications';
    PageType = ListPart;
    SourceTable = "EDoc Sovos Notification";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
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

    actions
    {
        area(Processing)
        {
            action(ViewContent)
            {
                ApplicationArea = All;
                Caption = 'Voir le contenu (décodé)';
                Image = View;
                ToolTip = 'Décode le contenu Base64 (réponse applicative UBL) et l''affiche.';

                trigger OnAction()
                var
                    Base64Convert: Codeunit "Base64 Convert";
                    Viewer: Page "JSON Viewer";
                    Base64Value: Text;
                    InStr: InStream;
                    Content: Text;
                    LineTxt: Text;
                begin
                    Rec.CalcFields("Content (Base64)");
                    if not Rec."Content (Base64)".HasValue() then begin
                        Message('Aucun contenu pour cette notification.');
                        exit;
                    end;

                    Rec."Content (Base64)".CreateInStream(InStr, TextEncoding::UTF8);
                    while not InStr.EOS() do begin
                        InStr.ReadText(LineTxt);
                        Base64Value += LineTxt;
                    end;

                    if Base64Value = '' then begin
                        Message('Aucun contenu pour cette notification.');
                        exit;
                    end;

                    Content := Base64Convert.FromBase64(Base64Value);
                    Viewer.SetContent('Contenu de la notification', Content);
                    Viewer.Run();
                end;
            }

            action(ViewRawJson)
            {
                ApplicationArea = All;
                Caption = 'Voir le JSON brut';
                Image = ViewDetails;

                trigger OnAction()
                var
                    Viewer: Page "JSON Viewer";
                begin
                    Viewer.SetContent('Notification (JSON brut)', Rec.GetRawJson());
                    Viewer.Run();
                end;
            }
        }
    }
}
