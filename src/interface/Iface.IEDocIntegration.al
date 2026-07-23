interface "IEDoc Integration"
{
    /// <summary>
    /// Run on release/post of the source document to validate all data required to build the
    /// outbound payload is present. Should Error() if something mandatory is missing.
    /// </summary>
    /// <param name="SourceDocumentHeader">Source document header (e.g. Sales Invoice Header) as a RecordRef.</param>
    /// <param name="EDocService">The service (SOVOS connection) used to send the document.</param>
    /// <param name="ProcessingPhase">Which phase triggered the check (Create/Map/Send/Post).</param>
    procedure Check(var SourceDocumentHeader: RecordRef; EDocService: Record "EDoc Service"; ProcessingPhase: Enum "EDoc Processing Phase")

    /// <summary>
    /// Builds the outbound payload (UBL 2.1 XML for Flux 2, JSON for Flux 6/10.x) for a single document.
    /// </summary>
    /// <param name="EDocService">The service (SOVOS connection) used to send the document.</param>
    /// <param name="EDocEntry">The EDoc Entry record being prepared.</param>
    /// <param name="SourceDocumentHeader">Source document header as a RecordRef.</param>
    /// <param name="SourceDocumentLines">Source document lines as a RecordRef.</param>
    /// <param name="TempBlob">Receives the built payload.</param>
    procedure Create(EDocService: Record "EDoc Service"; var EDocEntry: Record "EDoc Entry"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")

    /// <summary>
    /// Builds a batch payload where SOVOS/the flow supports grouping several documents together.
    /// </summary>
    procedure CreateBatch(EDocService: Record "EDoc Service"; var EDocEntries: Record "EDoc Entry"; var SourceDocumentHeaders: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")

    /// <summary>
    /// Extracts just enough info (doc no., amounts, dates) from an inbound notification/blob to
    /// create the EDoc Entry shell before the full mapping is done.
    /// </summary>
    procedure GetBasicInfoFromReceivedDocument(var EDocEntry: Record "EDoc Entry"; var TempBlob: Codeunit "Temp Blob")

    /// <summary>
    /// Maps a fully received inbound document (e.g. an inbound invoice for Pluxee RE/Développement/
    /// Participations) onto BC document header/lines as a RecordRef.
    /// </summary>
    procedure GetCompleteInfoFromReceivedDocument(var EDocEntry: Record "EDoc Entry"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
}
