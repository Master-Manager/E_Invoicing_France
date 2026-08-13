pageextension 70124 "Accounting Mngr RC Ext Sovos" extends "Accounting Manager Role Center"
{
    layout
    {
    }

    actions
    {
        addFirst(embedding)
        {
            group(SOVOS)
            {
                Caption = 'French E-Invoicing';
                Image = Document;
                action(Edocuments)
                {
                    ApplicationArea = All;
                    Caption = 'E-Documents';
                    Image = Document;
                    RunObject = Page "EDoc Documents";
                }
                action("E-Invoicing Documents")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoicing Documents';
                    Image = Document;
                    RunObject = Page "EDoc EInvoicing Documents";
                }
                action("Sovos Documents")
                {
                    ApplicationArea = All;
                    Caption = 'Sovos Documents';
                    Image = Document;
                    RunObject = Page "EDoc Sovos Documents";
                }
            }
        }
    }

}