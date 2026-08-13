page 70129 "EDoc CDV Outbound Queue List"
{
    PageType = List;
    SourceTable = "EDoc CDV Outbound Queue";
    Caption = 'EDoc CDV Outbound Queue';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    //CardPageId = "EDoc CDV Outbound Queue"; // Optional if you want a card view later

    layout
    {
        area(Content)
        {
            repeater(QueueRepeater)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the unique entry number for the queue item[cite: 2].';
                }
                field("Invoice No."; Rec."Invoice No.")
                {
                    ToolTip = 'Specifies the invoice number related to this Flow 6 CDV message[cite: 2].';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ToolTip = 'Specifies when the message was enqueued[cite: 2].';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the transmission status (Pending, Sent, Error)[cite: 2].';
                }
                field(Attempts; Rec.Attempts)
                {
                    ToolTip = 'Specifies the number of transmission attempts made[cite: 2].';
                }
                field("Last Attempt DateTime"; Rec."Last Attempt DateTime")
                {
                    ToolTip = 'Specifies the date and time of the last send attempt[cite: 2].';
                }
                field("Last HTTP Status Code"; Rec."Last HTTP Status Code")
                {
                    ToolTip = 'Specifies the last HTTP status code returned by the server[cite: 2].';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ToolTip = 'Specifies the error message if the transmission failed[cite: 2].';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewXmlContent)
            {
                ApplicationArea = All;
                Caption = 'View XML Content';
                Image = XMLFile;
                ToolTip = 'Displays the generated UN/CEFACT XML payload for the selected queue entry.';

                trigger OnAction()
                begin
                    Message(Rec.GetXml());
                end;
            }
        }
    }
}