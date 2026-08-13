pageextension 70127 "EDoc CDV Manual Send" extends "Customer Ledger Entries"
{
    actions
    {
        addlast(Processing)
        {
            action("SendFlow6Cdv")
            {
                ApplicationArea = All;
                Caption = 'Send Paid Invoice XML';
                ToolTip = 'Manually generate and send the CDV Flux 6 "Collected" message for this customer entry.';
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    EventHandler: Codeunit "EDoc CDV Flow 6 Event Handler";
                    ConfirmMsg: Text;
                begin
                    if Rec."Document Type" <> Rec."Document Type"::Invoice then
                        Error('This action is only available for entries of type Invoice.');

                    if Rec.Open then
                        Error('This invoice has not yet been fully paid (remaining amount: %1). The CDV "Collected" message cannot be sent.', Rec."Remaining Amount");

                    EventHandler.SendFlow6EncaisseeNotification(Rec);
                    Message('The CDV Flux 6 XML for invoice %1 has been added to the sending queue.', Rec."Document No.");
                end;

            }
            action("ViewCDVXml")
            {
                ApplicationArea = All;
                Caption = 'View XML CDV';
                ToolTip = 'Display the XML content of the generated CDV Flux 6 message for this invoice.';
                Image = XMLFile;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    QueueEntry: Record "EDoc CDV Outbound Queue";
                begin
                    if Rec."Document Type" <> Rec."Document Type"::Invoice then
                        Error('This action is only available for entries of type Invoice.');

                    QueueEntry.SetRange("Invoice No.", Rec."Document No.");
                    if not QueueEntry.FindLast() then
                        Error('No CDV message was found in the queue for invoice %1. Please send it first.', Rec."Document No.");

                    // Displays the XML lines directly in a popup message box
                    Message(QueueEntry.GetXml());
                end;
            }
        }
    }
}
