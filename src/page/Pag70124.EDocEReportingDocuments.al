page 70124 "EDoc EReporting Documents"
{
    ApplicationArea = All;
    Caption = 'E-Reporting Documents';
    PageType = List;
    SourceTable = "EDoc Document";
    SourceTableView = where("Document Type" = filter("E-Reporting"));
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
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document Direction"; Rec."Document Direction")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field("Customer Country"; Rec."Customer Country")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
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
            action(GenerateXml_ER)
            {
                ApplicationArea = All;
                Caption = 'View XML';
                Image = View;

                trigger OnAction()
                var
                    Viewer: Page "JSON Viewer";
                    XmlContent: Text;
                begin
                    XmlContent := GetGeneratedXmlContent();
                    Viewer.SetContent('Generated XML', XmlContent);
                    Viewer.Run();
                end;
            }

            /*action(ViewXml)
            {
                Caption = 'View/Download Flow 10.1 XML';
                ToolTip = 'Télécharge le XML flux 10.1 généré pour le document sélectionné.';
                Image = XMLFile;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    EDocService: Record "EDoc Service";
                    SetupMgt: Codeunit "EDoc Setup Mgt.";
                    EReportingBuilder: Codeunit "EDoc Sovos EReporting Builder";
                    PurchaseBuilder: Codeunit "EDoc ER Flow 10.1 Pur Builder";
                    SbdBuilder: Codeunit "EDoc ER SBD Builder";
                    BodyXml: Text;
                    SbdXml: Text;
                    ServiceCode: Code[20];
                    TempBlob: Codeunit "Temp Blob";
                    OutStream: OutStream;
                    InStream: InStream;
                    FileName: Text;
                begin
                    // Resolve active/default E-Document service code
                    SetupMgt.GetDefaultService(EDocService);
                    ServiceCode := EDocService.Code;

                    // Génération unitaire en fonction du sens (Inbound = Vente/Outbound selon ta logique, ou direct via Rec)
                    if Rec."Document Direction" = Rec."Document Direction"::Inbound then
                        BodyXml := PurchaseBuilder.BuildPurchaseFlow101Xml(Rec, ServiceCode)
                    else
                        BodyXml := EReportingBuilder.BuildFlow101Xml(Rec, ServiceCode);

                    if BodyXml = '' then
                        Error('Impossible de générer le XML pour le document %1.', Rec."Document No.");

                    // Wrap payload in SBD Header basé sur la date du document unique
                    SbdXml := SbdBuilder.BuildEReportingSBD(BodyXml, Rec."Posting Date", Rec."Posting Date", ServiceCode);

                    // Export using matching UTF-8 encoding streams
                    TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.WriteText(SbdXml);
                    TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

                    FileName := StrSubstNo('EReporting_10.1_%1.xml', Rec."Document No.");
                    DownloadFromStream(InStream, 'Visualiser le XML E-Reporting 10.1', '', 'Fichiers XML (*.xml)|*.xml', FileName);
                end;
            }*/

            action("Send Flow 10.1")
            {
                ApplicationArea = All;
                Caption = 'Send to Sovos';
                Image = SendTo;

                trigger OnAction()
                var
                    Sovos: Codeunit "Sovos Client";
                    SovosDocMgt: Codeunit "EDoc Sovos Document Mgt.";
                    Payload: Text;
                    DocumentId: Text;
                    Response: Text;
                begin
                    // Rec.ValidateFlowTypeRules();
                    Payload := GetGeneratedXmlContent();

                    Response :=
                        Sovos.SendInvoice(
                            Payload,
                            DocumentId);

                    if DocumentId <> '' then begin
                        Rec."Sovos Document Id" := DocumentId;
                        SovosDocMgt.CreateFromSubmission(Rec, Response, DocumentId);
                    end;

                    Rec.Status := Rec.Status::Sent;
                    Rec.Modify(true);

                    Message(Response);
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

    local procedure PromptForPeriod(var StartDate: Date; var EndDate: Date): Boolean
    var
        FilterPageMgt: FilterPageBuilder;
        Campaign: Record Campaign;
    begin
        FilterPageMgt.AddRecord('Enter Period', Campaign);
        FilterPageMgt.AddField('Enter Period', Campaign."Starting Date");
        FilterPageMgt.AddField('Enter Period', Campaign."Ending Date");
        FilterPageMgt.SetView('Enter Period', StrSubstNo('WHERE("Starting Date" = FILTER(%1), "Ending Date" = FILTER(%2))', CalcDate('<-30D>', WorkDate()), WorkDate()));

        if not FilterPageMgt.RunModal() then
            exit(false);

        Campaign.SetView(FilterPageMgt.GetView('Enter Period'));

        if Campaign.GetFilter("Starting Date") <> '' then
            StartDate := Campaign.GetRangeMin("Starting Date");

        if Campaign.GetFilter("Ending Date") <> '' then
            EndDate := Campaign.GetRangeMax("Ending Date");

        if (StartDate = 0D) or (EndDate = 0D) then
            Error('You must enter both a Starting Date and an Ending Date.');

        if StartDate > EndDate then
            Error('The Starting Date cannot be after the Ending Date.');

        exit(true);
    end;

    procedure GetGeneratedXmlContent(): Text
    var
        EDocService: Record "EDoc Service";
        SetupMgt: Codeunit "EDoc Setup Mgt.";
        Builder: Codeunit "EDoc Sovos Invoice Builder";
        SBDBuilder: Codeunit "SBD Builder";
        SalesBuilder: Codeunit "EDoc Sovos EReporting Builder";
        PurchaseBuilder: Codeunit "EDoc ER Flow 10.1 Pur Builder";
        ServiceCode: Code[20];
        Xml: Text;
    begin
        SetupMgt.GetDefaultService(EDocService);
        ServiceCode := EDocService.Code;

        if Rec."Document Type" = Rec."Document Type"::"E-Reporting" then begin
            if Rec."Document Direction" = Rec."Document Direction"::Inbound then
                exit(PurchaseBuilder.BuildPurchaseFlow101Xml(Rec, ServiceCode))
            else
                exit(SalesBuilder.BuildFlow101Xml(Rec, ServiceCode));
        end else begin
            Xml := Builder.BuildInvoiceXml(Rec);
            exit(SBDBuilder.BuildSBD(Xml, Rec));
        end;
    end;

    var
        StatusStyleExpr: Text;
}
