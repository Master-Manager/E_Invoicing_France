page 70111 "EDoc Document Card"
{
    PageType = Card;
    SourceTable = "EDoc Document";
    ApplicationArea = All;
    Caption = 'E-Document';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Document Record ID"; Rec."Document Record ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }

                field("Invoice No."; Rec."Invoice No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Source Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Bill-to/Pay-to Name"; Rec."Bill-to/Pay-to Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                }

                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }

                field("Issue Date"; Rec."Issue Date")
                {
                    ApplicationArea = All;
                }

                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Tax Currency Code"; Rec."Tax Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Index In Batch"; Rec."Index In Batch")
                {
                    ApplicationArea = All;
                }

                field("Incoming E-Document No."; Rec."Incoming E-Document No.")
                {
                    ApplicationArea = All;
                }
                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = All;
                }
            }

            group(Supplier)
            {
                field("Supplier Name"; Rec."Supplier Name")
                {
                    ApplicationArea = All;
                }

                field("Supplier VAT No."; Rec."Supplier VAT No.")
                {
                    ApplicationArea = All;
                }

                field("Supplier SIREN"; Rec."Supplier SIREN")
                {
                    ApplicationArea = All;
                }

                field("Supplier SIRET"; Rec."Supplier SIRET")
                {
                    ApplicationArea = All;
                }
                field("Supplier Endpoint"; Rec."Supplier Endpoint")
                {
                    ApplicationArea = All;
                }
            }

            group(Customer)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }

                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }

                field("Customer VAT No."; Rec."Customer VAT No.")
                {
                    ApplicationArea = All;
                }

                field("Customer SIREN"; Rec."Customer SIREN")
                {
                    ApplicationArea = All;
                }

                field("Customer SIRET"; Rec."Customer SIRET")
                {
                    ApplicationArea = All;
                }
                field("Customer Endpoint"; Rec."Customer Endpoint")
                {
                    ApplicationArea = All;
                }
            }

            group(Amounts)
            {
                field("Amount Excl. VAT"; Rec."Amount Excl. VAT")
                {
                    ApplicationArea = All;
                }

                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = All;
                }

                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                {
                    ApplicationArea = All;
                }

                field("Payable Amount"; Rec."Payable Amount")
                {
                    ApplicationArea = All;
                }
            }
            group(References)
            {
                field("Buyer Reference"; Rec."Buyer Reference")
                {
                    ApplicationArea = All;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = All;
                }
                field("Actual Delivery Date"; Rec."Actual Delivery Date")
                {
                    ApplicationArea = All;
                }
            }
            group(Payment)
            {
                field("Payment Means Code"; Rec."Payment Means Code")
                {
                    ApplicationArea = All;
                }

                field("Payment Terms Note"; Rec."Payment Terms Note")
                {
                    ApplicationArea = All;
                }

            }

            part(Lines; "EDoc Document Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Sovos)
            {
                Caption = 'Sovos';

                action(ImportPostedInvoice)
                {
                    Caption = 'Import Posted Invoice';
                    Image = GetSourceDoc;

                    trigger OnAction()
                    var
                        ImportMgt: Codeunit "EDoc Import Mgt.";
                    begin
                        ImportMgt.CreateFromPostedInvoice(Rec);
                        CurrPage.Update(true);
                    end;
                }
                action(ImportPostedInvoiceE_Reporting)
                {
                    Caption = 'Import Posted Invoice E_Reporting';
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

                action(CheckStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Refresh Status';
                    Image = Refresh;

                    trigger OnAction()
                    var
                        Sovos: Codeunit "Sovos Client";
                        Response: Text;
                    begin

                        if Rec."Sovos Document Id" = '' then
                            Error('No Sovos Document Id.');

                        Response :=
                            Sovos.GetStatus(
                                '/v1/documents/' +
                                Rec."Sovos Document Id");

                        Message(Response);

                    end;
                }

                action(ViewSovosSubmissions)
                {
                    ApplicationArea = All;
                    Caption = 'View Sovos Submissions';
                    Image = Entries;

                    trigger OnAction()
                    var
                        SovosDoc: Record "EDoc Sovos Document";
                        SovosDocsPage: Page "EDoc Sovos Documents";
                    begin
                        SovosDoc.SetRange("EDoc Document Entry No.", Rec."Entry No.");
                        SovosDocsPage.SetTableView(SovosDoc);
                        SovosDocsPage.Run();
                    end;
                }
            }
        }
    }

}