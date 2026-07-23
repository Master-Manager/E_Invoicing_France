codeunit 70111 "EDoc Sovos Integration"
{
    Access = Internal;

    var
        EntryMgt: Codeunit "EDoc Entry Mgt.";
        Logger: Codeunit "EDoc Logger";
        InvoiceBuilder: Codeunit "EDoc Sovos Invoice Builder";
        SovosClient: Codeunit "Sovos Client";

    procedure SendPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header")
    var
        Entry: Record "EDoc Entry";
        EntryNo: Integer;
        XmlText: Text;
        ResponseText: Text;
        SovosDocumentId: Text;
    begin
        //------------------------------------------
        // Create E-Document Entry
        //------------------------------------------
        EntryNo :=
            EntryMgt.CreateEntry(
                Enum::"EDoc Document Type"::Invoice,
                SalesInvHeader."No.");

        Entry.Get(EntryNo);

        Logger.LogInformation(
            EntryNo,
            StrSubstNo('Starting export of invoice %1.', SalesInvHeader."No."),
            'EDoc Sovos Integration');

        //------------------------------------------
        // Build XML
        //------------------------------------------
        // XmlText :=
        //     InvoiceBuilder.BuildInvoiceXml(SalesInvHeader);

        EntryMgt.SetRequestJson(
            Entry,
            XmlText);

        Logger.LogInformation(
            EntryNo,
            'Invoice XML successfully generated.',
            'EDoc Sovos Invoice Builder');

        //------------------------------------------
        // Send to Sovos
        //------------------------------------------
        ResponseText :=
            SovosClient.SendInvoice(
                XmlText,
                SovosDocumentId);

        //------------------------------------------
        // Store response
        //------------------------------------------
        EntryMgt.SetResponseJson(
            Entry,
            ResponseText);

        if SovosDocumentId <> '' then
            EntryMgt.SetSovosDocumentId(
                Entry,
                SovosDocumentId);

        EntryMgt.SetStatus(
            Entry,
            Enum::"EDoc Entry Status"::Sent);

        Logger.LogInformation(
            EntryNo,
            'Invoice successfully sent to Sovos.',
            'Sovos Client');

        Message(
            'Invoice %1 has been successfully sent to Sovos.',
            SalesInvHeader."No.");
    end;


    procedure SendTestXml(XmlText: Text)
    var
        Entry: Record "EDoc Entry";
        EntryNo: Integer;

        EntryMgt: Codeunit "EDoc Entry Mgt.";
        Client: Codeunit "Sovos Client";

        ResponseText: Text;
        DocumentId: Text;
    begin
        EntryNo :=
            EntryMgt.CreateEntry(
                Enum::"EDoc Document Type"::Invoice,
                'TEST XML');

        Entry.Get(EntryNo);

        EntryMgt.SetRequestJson(
            Entry,
            XmlText);

        ResponseText :=
            Client.SendInvoice(
                XmlText,
                DocumentId);

        EntryMgt.SetResponseJson(
            Entry,
            ResponseText);

        EntryMgt.SetSovosDocumentId(
            Entry,
            DocumentId);

        EntryMgt.SetStatus(
            Entry,
            Enum::"EDoc Entry Status"::Sent);

        Message(ResponseText);
    end;
}