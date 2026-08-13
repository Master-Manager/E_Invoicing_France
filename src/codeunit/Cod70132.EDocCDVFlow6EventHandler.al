codeunit 70132 "EDoc CDV Flow 6 Event Handler"
{
    // Detects when a customer invoice is fully closed by a payment application, then builds
    // and sends the Flux 6 "Encaissée" (212) CDV message for the related EDoc Document.
    //
    // IMPORTANT: The event below is a PLACEHOLDER. Business Central does not have one single
    // universally-agreed "invoice closed by payment" event across versions/modules - the right
    // hook depends on how your AR posting flow is built (standard Gen. Jnl. application,
    // Payment Reconciliation Journal, a bank feed matching add-on, etc.).
    //
    // TODO before this compiles/works: find your actual hook using the Event Recorder
    // (Business Central > search "Event Recorder" > Start > apply a payment manually in a
    // test company > Stop > look for events fired around Cust. Ledger Entry / application).
    // Strong candidates to check first:
    //   - Codeunit 12 "Gen. Jnl.-Post Line", OnAfterPostGenJnlLine
    //   - Codeunit 226/227 (customer application posting), OnAfterPostApplyCustomerEntry
    //   - Table 21 "Cust. Ledger Entry", OnAfterModifyEvent (check Open: true -> false)
    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCustLedgerEntry(var Rec: Record "Cust. Ledger Entry"; var xRec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    var
        EventHandler: Codeunit "EDoc CDV Flow 6 Event Handler";
    begin
        // Ensure this only runs on server-side operations during actual postings/applications
        if Rec.IsTemporary then
            exit;

        // Check if the entry just transitioned from Open (true) to Closed/Paid (false)
        if xRec.Open and (not Rec.Open) then begin
            // Restrict to Sales Invoices only
            if Rec."Document Type" = Rec."Document Type"::Invoice then begin
                // Automatically trigger the Flow 6 Encaissee notification
                EventHandler.SendFlow6EncaisseeNotification(Rec);
            end;
        end;
    end;

    [TryFunction]
    local procedure TrySendFlow6EncaisseeNotification(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        SendFlow6EncaisseeNotification(CustLedgerEntry);
    end;

    local procedure LogAutomaticSendFailure(CustLedgerEntry: Record "Cust. Ledger Entry"; ErrorText: Text)
    begin
        // TODO: write this to a proper, queryable log (e.g. a dedicated error log table, or
        // Session.LogMessage for telemetry) rather than nothing at all. As-is, a failure here
        // (most commonly: no matching EDoc Document for the invoice) is silently swallowed to
        // protect the payment posting transaction, and would only be caught by the fact that a
        // Pending/Sent row never appears in the Outbound Queue for that invoice. That gap is
        // acceptable to ship with, but should not stay unaddressed long-term.
    end;

    /// <summary>
    /// Builds and enqueues the Flow 6 "Encaissée" CDV message for the invoice behind the given
    /// Cust. Ledger Entry. Called automatically (via the Try wrapper above) on invoice closure,
    /// and directly from the "Envoyer CDV (Flux 6)" manual page action, where raising an error
    /// is fine and desirable - the user should see immediately if something's wrong.
    /// </summary>
    procedure SendFlow6EncaisseeNotification(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        EDoc: Record "EDoc Document";
        OutboundQueue: Record "EDoc CDV Outbound Queue";
        Flow6Builder: Codeunit "EDoc ER Flow 6 Builder";
        QueueProcessor: Codeunit "EDoc CDV Queue Processor";
        StatusInfo: Record "EDoc CDV Status Info" temporary;
        VATBuffer: Record "EDoc VAT Buffer" temporary;
        XmlContent: Text;
    begin
        // 1. Find the corresponding EDoc Document for this invoice
        EDoc.SetRange("Invoice No.", CustLedgerEntry."Document No.");
        if not EDoc.FindFirst() then
            exit; // Exit if no electronic document record exists

        // 2. Prevent duplicate queue entries if already sent or pending
        OutboundQueue.SetRange("Invoice No.", EDoc."Invoice No.");
        OutboundQueue.SetFilter(Status, '%1|%2', OutboundQueue.Status::Pending, OutboundQueue.Status::Sent);

        if not OutboundQueue.IsEmpty() then
            exit;

        // 3. Build Status Info (212 - Encaissée) and VAT Buffer (Rule P1.18)
        Flow6Builder.GetStatusInfo(EDoc, StatusInfo);
        Flow6Builder.BuildVATBufferFromEDoc(EDoc, VATBuffer);

        // 4. Generate the XML content
        XmlContent := Flow6Builder.BuildFlow6Xml(EDoc, StatusInfo, VATBuffer);

        // 5. Insert into the Outbound Queue
        OutboundQueue.Init();
        OutboundQueue."Invoice No." := EDoc."Invoice No.";
        OutboundQueue."Created DateTime" := CurrentDateTime;
        OutboundQueue.Status := OutboundQueue.Status::Pending;
        OutboundQueue.Attempts := 0;
        OutboundQueue.SetXml(XmlContent);
        OutboundQueue.Insert(true);

        // 6. Automatically trigger processing right away (or leave for a Job Queue)
        QueueProcessor.ProcessPendingQueue();
    end;

    local procedure SendXmlToPPF(Xml: Text; EDoc: Record "EDoc Document")
    var
        Flow6Sender: Codeunit "EDoc CDV Flow6 Sender";
    begin
        // Fast, transaction-safe insert only - the actual HTTP call happens asynchronously
        // from a Job Queue Entry running codeunit "EDoc CDV Flow6 Sender".ProcessQueue().
        // See that codeunit's header comment for why this isn't a direct HttpClient call here.
        Flow6Sender.Enqueue(EDoc."Invoice No.", Xml);
    end;
}
