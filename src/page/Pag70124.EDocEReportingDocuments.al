// Page de suivi des entrées d'e-reporting (flux 10.1/10.2). Proposée par analogie avec ce
// qui existe probablement déjà côté invoice (vos fichiers "page" ne nous sont pas encore
// parvenus - upload vide) : à fusionner/aligner avec vos conventions une fois reçus.
page 70124 "EDoc EReporting Documents"
{
    ApplicationArea = All;
    Caption = 'E-Reporting Documents';
    PageType = List;
    SourceTable = "EDoc Document";
    SourceTableView = where("Flow Type" = filter(International | Collection | "B2C Reporting"));
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "EDoc Document Card";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                /*field("Flow Type"; Rec."Flow Type")
                {
                    ApplicationArea = All;
                }
                */
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Customer Country"; Rec."Customer Country")
                {
                    ApplicationArea = All;
                }

                field("Amount Excl. VAT"; Rec."Amount Excl. VAT")
                {
                    ApplicationArea = All;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = All;
                }
                field("VAT Rate"; Rec."VAT Rate")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyleExpr;
                }
                field("Sovos Document Id"; Rec."Sovos Document Id")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateXml)
            {
                Caption = 'Generate XML';
                ToolTip = 'Génère le flux XML E-Reporting pour cette entrée sans l''envoyer à Sovos.';
                Image = CreateXMLFile;
                ApplicationArea = All;

                trigger OnAction()
                var
                    SovosBuilder: Codeunit "EDoc Sovos EReporting Builder";
                    XmlContent: Text;
                begin
                    // On vérifie qu'une ligne est bien sélectionnée
                    Rec.TestField("Document No.");

                    // Génération du XML brut
                    XmlContent := SovosBuilder.BuildEReportingXml(Rec);

                    Message('Le flux XML a été généré avec succès en mémoire pour le document %1.', Rec."Document No.");
                end;
            }

            action(ViewXml)
            {
                Caption = 'View/Download XML';
                ToolTip = 'Télécharge le fichier XML généré localement pour inspection technique.';
                Image = XMLFile;
                ApplicationArea = All;

                trigger OnAction()
                var
                    SovosBuilder: Codeunit "EDoc Sovos EReporting Builder";
                    XmlContent: Text;
                    TempBlob: Codeunit "Temp Blob";
                    OutStream: OutStream;
                    InStream: InStream;
                    FileName: Text;
                    SbdBuilder: Codeunit "SBD Builder";
                    SbdXml: Text;
                    Viewer: Page "JSON Viewer";
                begin
                    Rec.TestField("Document No.");

                    // 1. Génération du texte XML
                    XmlContent := SovosBuilder.BuildEReportingXml(Rec);

                    SbdXml := SbdBuilder.BuildEReportingSBD(XmlContent, Rec);

                    if XmlContent = '' then
                        Error('Le générateur a renvoyé un flux vide.');

                    Viewer.SetContent('Generated XML', SbdXml);

                    Viewer.Run();
                    // // 2. Écriture du texte dans un flux temporaire encodé en UTF-8
                    // TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
                    // OutStream.WriteText(XmlContent);
                    // TempBlob.CreateInStream(InStream);

                    // // 3. Déclenchement du téléchargement sur le poste utilisateur
                    // FileName := StrSubstNo('EReporting_%1.xml', Rec."Document No.");
                    // DownloadFromStream(InStream, 'Visualiser le XML E-Reporting', '', 'Fichiers XML (*.xml)|*.xml', FileName);
                end;
            }
            action("Send Now")
            {
                ApplicationArea = All;
                Caption = 'Send to SOVOS';
                Image = SendTo;
                ToolTip = 'Envoie immédiatement cette entrée à Sovos, sans attendre le batch.';

                trigger OnAction()
                var
                    Integration: Codeunit "EDoc Sovos EReporting Integr.";
                begin
                    Integration.SendEReportingEntry(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("Send All Pending")
            {
                ApplicationArea = All;
                Caption = 'Send to SOVOS all Pending';
                Image = SendToMultiple;
                ToolTip = 'Déclenche le batch complet pour toutes les entrées au statut Pending.';

                trigger OnAction()
                var
                    Integration: Codeunit "EDoc Sovos EReporting Integr.";
                begin
                    Integration.SendPendingEntries();
                    CurrPage.Update(false);
                end;
            }
            action(CatchUpInvoices)
            {
                Caption = 'Import Posted Invoices';
                Image = GetSourceDoc;
                ApplicationArea = All;

                trigger OnAction()
                var
                    CatchUpMgt: Codeunit "EDoc EReporting Catch-Up";
                    FilterPageMgt: FilterPageBuilder;
                    StartDate: Date;
                    EndDate: Date;
                    Campaign: Record Campaign;
                begin
                    // 1. Initialiser le menu en utilisant la table Campaign pour avoir les 2 champs distincts
                    FilterPageMgt.AddRecord('Enter Period', Campaign);

                    // 2. Ajouter manuellement les deux champs séparés de date
                    FilterPageMgt.AddField('Enter Period', Campaign."Starting Date");
                    FilterPageMgt.AddField('Enter Period', Campaign."Ending Date");

                    // 3. Pré-remplir les deux cases distinctes avec les 30 derniers jours par défaut
                    FilterPageMgt.SetView('Enter Period', StrSubstNo('WHERE("Starting Date" = FILTER(%1), "Ending Date" = FILTER(%2))', CalcDate('<-30D>', WorkDate()), WorkDate()));

                    // 4. Ouvrir le menu de saisie manuelle (RunModal)
                    if FilterPageMgt.RunModal() then begin

                        // 5. Récupérer la vue textuelle générée par l'IHM
                        Campaign.SetView(FilterPageMgt.GetView('Enter Period'));

                        // FIX: Lire la valeur textuelle du filtre à la place du champ en mémoire
                        if Campaign.GetFilter("Starting Date") <> '' then
                            StartDate := Campaign.GetRangeMin("Starting Date");

                        if Campaign.GetFilter("Ending Date") <> '' then
                            EndDate := Campaign.GetRangeMax("Ending Date");

                        // 6. Sécurité : Vérifier que les deux dates sont bien saisies
                        if (StartDate <> 0D) and (EndDate <> 0D) then begin
                            if StartDate > EndDate then
                                Error('The Starting Date cannot be after the Ending Date.');

                            // 7. Lancer le traitement d'importation historique
                            CatchUpMgt.CatchUpPostedInvoices(StartDate, EndDate);


                            if Rec.FindFirst() then;
                        end else
                            Error('You must enter both a Starting Date and an Ending Date.');
                    end;
                end;
            }


        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Sent:
                StatusStyleExpr := 'Favorable';
            Rec.Status::Error:
                StatusStyleExpr := 'Unfavorable';
            else
                StatusStyleExpr := 'Ambiguous';
        end;
    end;

    var
        StatusStyleExpr: Text;
}
