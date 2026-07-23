codeunit 70110 "EDoc Status Impl." implements "IEDoc Status"
{
    procedure GetEDocStatus(EDocEntry: Record "EDoc Entry"): Enum "EDoc Entry Status"
    begin
        exit(EDocEntry.Status);
    end;
}
