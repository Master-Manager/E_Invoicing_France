codeunit 70131 "Transfer E-Rep Fields Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchInvHeaderInsert', '', false, false)]
    local procedure OnBeforePurchInvHeaderInsert(
            var PurchInvHeader: Record "Purch. Inv. Header";
            var PurchHeader: Record "Purchase Header";
            CommitIsSupressed: Boolean)
    begin
        PurchInvHeader."Invoice Type Code" := PurchHeader."Invoice Type Code";
        PurchInvHeader."Tax Due Date Type Code" := PurchHeader."Tax Due Date Type Code";
        PurchInvHeader."E-Rep Profile ID" := PurchHeader."E-Rep Profile ID";
    end;
}