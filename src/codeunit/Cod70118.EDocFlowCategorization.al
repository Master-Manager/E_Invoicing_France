codeunit 70118 "EDoc Flow Categorization"
{
    Access = Internal;

    procedure CategorizeSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"): Enum "EDoc Flow Type"
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        IsDomesticFR: Boolean;
    begin
        if not Customer.Get(SalesInvHeader."Bill-to Customer No.") then
            exit("EDoc Flow Type"::International); // Par prudence

        // Sécurité Pays : Si le code pays du client est vide ou égal à celui de l'entreprise (FR), c'est du domestique
        CompanyInfo.Get();
        IsDomesticFR := (Customer."Country/Region Code" = 'FR') or (Customer."Country/Region Code" = '') or (Customer."Country/Region Code" = CompanyInfo."Country/Region Code");

        if not IsCustomerB2B(Customer) then
            exit("EDoc Flow Type"::"B2C Reporting");

        // Si c'est un client B2B et qu'il est Français -> Flux E-Invoicing National
        if IsDomesticFR then
            exit("EDoc Flow Type"::"Flux 2 - Invoicing"); // Correction : Utilisation directe de votre vraie valeur d'enum

        // Si c'est un client B2B et qu'il n'est pas Français (ex: DE) -> Flux E-Reporting International
        exit("EDoc Flow Type"::International);
    end;

    procedure ShouldReportCollection(OriginalFlowType: Enum "EDoc Flow Type"; IsCashBasisVatEntity: Boolean): Boolean
    begin
        if not IsCashBasisVatEntity then
            exit(false);

        // L'E-reporting de paiement s'applique à l'international et au B2C
        exit(OriginalFlowType in ["EDoc Flow Type"::International, "EDoc Flow Type"::"B2C Reporting"]);
    end;

    local procedure IsCustomerB2B(Customer: Record Customer): Boolean
    begin
        // Un client est B2B s'il a un numéro de TVA OU un numéro de SIRET
        exit((Customer."VAT Registration No." <> '') or (Customer."EDoc SIRET" <> ''));
    end;
}
