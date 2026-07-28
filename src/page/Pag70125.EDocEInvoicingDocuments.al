// Page de suivi des entrées d'e-reporting (flux 10.1/10.2). Proposée par analogie avec ce
// qui existe probablement déjà côté invoice (vos fichiers "page" ne nous sont pas encore
// parvenus - upload vide) : à fusionner/aligner avec vos conventions une fois reçus.
page 70125 "EDoc EInvoicing Documents"
{
    ApplicationArea = All;
    Caption = 'E-Invoicing Documents';
    PageType = List;
    SourceTable = "EDoc Document";
    SourceTableView = where("Flow Type" = filter("Flux 2 - Invoicing"));
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
            action(ImportPostedInvoice)
            {
                Caption = 'Import Posted Invoice';
                Image = GetSourceDoc;

                trigger OnAction()
                var
                    ImportMgt: Codeunit "EDoc Import Mgt.";
                    NewEDoc: Record "EDoc Document";
                begin
                    ImportMgt.CreateFromPostedInvoice(NewEDoc);

                    if NewEDoc."Entry No." <> 0 then begin
                        Rec := NewEDoc;
                        if Rec.Find() then
                            CurrPage.Update(false);
                    end;
                end;
            }
            action(GenerateXML)
            {
                ApplicationArea = All;
                Caption = 'Generate XML';
                Image = XMLFile;

                trigger OnAction()
                var
                    Builder: Codeunit "EDoc Sovos Invoice Builder";
                    SBDBuilder: Codeunit "SBD Builder";
                    SBD: Text;
                    Xml: Text;
                begin
                    Xml := Builder.BuildInvoiceXml(Rec);

                    SBD := SBDBuilder.BuildSBD(Xml, Rec);

                    Message(
                        'XML generated successfully.\Length: %1 characters.',
                        StrLen(SBD));
                end;
            }

            action(ViewXML)
            {
                ApplicationArea = All;
                Caption = 'View XML';
                Image = View;

                trigger OnAction()
                var
                    Builder: Codeunit "EDoc Sovos Invoice Builder";
                    SBDBuilder: Codeunit "SBD Builder";
                    Viewer: Page "JSON Viewer";
                    Xml: Text;
                begin
                    Xml := Builder.BuildInvoiceXml(Rec);
                    Viewer.SetContent(
                        'Generated XML',
                        SBDBuilder.BuildSBD(Xml, Rec));

                    Viewer.Run();
                end;
            }
            action(SendToSovos)
            {
                ApplicationArea = All;
                Caption = 'Send to Sovos';
                Image = SendTo;

                trigger OnAction()
                var
                    Builder: Codeunit "EDoc Sovos Invoice Builder";
                    SBDBuilder: Codeunit "SBD Builder";
                    Sovos: Codeunit "Sovos Client";
                    SovosDocMgt: Codeunit "EDoc Sovos Document Mgt.";

                    Xml: Text;
                    SBD: Text;
                    DocumentId: Text;
                    Response: Text;
                begin

                    Xml := Builder.BuildInvoiceXml(Rec);

                    SBD := SBDBuilder.BuildSBD(Xml, Rec);

                    Response :=
                        Sovos.SendInvoice(
                            SBD,
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

    var
        StatusStyleExpr: Text;
}
