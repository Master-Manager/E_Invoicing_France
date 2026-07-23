interface "IEDoc Status"
{
    /// <summary>
    /// Returns the current status of the E-Document entry. Default implementation simply
    /// reads Rec.Status; a flow-specific implementation (e.g. Flux 6) can later override this
    /// to derive status from something more elaborate than the stored field.
    /// </summary>
    procedure GetEDocStatus(EDocEntry: Record "EDoc Entry"): Enum "EDoc Entry Status";
}
