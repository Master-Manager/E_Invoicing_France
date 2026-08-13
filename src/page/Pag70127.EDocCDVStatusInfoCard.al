page 70127 "EDoc CDV Status Info Card"
{
    PageType = Card;
    SourceTable = "EDoc CDV Status Info";
    SourceTableTemporary = true;
    Caption = 'Paramètres statut CDV (Flux 6)';
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(Document)
            {
                Caption = 'Document référencé';

                field("Referenced Document Id"; Rec."Referenced Document Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identifiant du document ou flux référencé par le message CDV (ex. n° de facture).';
                }
                field("Document Type Code"; Rec."Document Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'TypeCode du document référencé (ex. 380 = facture commerciale).';
                }
                field("Receipt DateTime"; Rec."Receipt DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date et heure de réception de l''objet référencé.';
                }
            }
            group(Status)
            {
                Caption = 'Statut à transmettre';

                field("Process Condition Code"; Rec."Process Condition Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Code statut traitement PPF (ProcessConditionCode), ex. Encaissée.';

                    trigger OnValidate()
                    begin
                        SetStatusDefaults();
                    end;
                }
                field("Process Condition Label"; Rec."Process Condition Label")
                {
                    ApplicationArea = All;
                    ToolTip = 'Libellé du statut PPF tel qu''il apparaîtra dans le XML (ex. "Encaissee").';
                }
                field("Status Code (UNTDID 1373)"; Rec."Status Code (UNTDID 1373)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Code statut générique UNTDID 1373 - référentiel distinct du ProcessConditionCode PPF.';
                }
                field("Is Error Status"; Rec."Is Error Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Coché si ce statut correspond à une erreur (TypeCode=305), sinon information (TypeCode=23).';
                }
            }
            group(CdvMessage)
            {
                Caption = 'Message CDV';

                field("CDV Document Name"; Rec."CDV Document Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nom du document CDV généré (ram:ExchangedDocument/Name), ex. "CDV-212_Encaissee".';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then begin
            Rec.Init();
            Rec.Insert();
        end;
        Rec.FindFirst();
    end;

    /// <summary>
    /// Pré-remplit le libellé et le code UNTDID 1373 à partir du ProcessConditionCode choisi.
    /// TODO: seul le membre "Encaissee" de l'enum "EDoc CDV Process Condition" est confirmé à ce
    /// stade (cf. codeunit 70124). Étendre ce case dès que les autres membres (Déposée/Refusée/
    /// Rejetée - codes 200/210/213 sur l'onglet "Statuts") sont confirmés dans l'enum.
    /// </summary>
    local procedure SetStatusDefaults()
    begin
        case Rec."Process Condition Code" of
            Rec."Process Condition Code"::Encaissee:
                begin
                    Rec."Process Condition Label" := 'Encaissee';
                    Rec."Status Code (UNTDID 1373)" := 212;
                    Rec."Is Error Status" := false;
                end;
        // TODO: else case(s) for Déposée (200), Refusée (210), Rejetée (213), etc.
        end;
    end;
}
