codeunit 50100 "EDoc Setup Mgt."
{
    procedure GetSetup(var Setup: Record "EDoc Setup")
    begin
        if not Setup.Get('SETUP') then begin
            Setup.Init();
            Setup."Primary Key" := 'SETUP';
            Setup.Insert(true);

            CreateDefaultService();

            Setup."Default Service Code" := 'SOVOS_TEST';
            Setup.Modify(true);
        end;
    end;

    procedure GetDefaultService(var Service: Record "EDoc Service")
    var
        Setup: Record "EDoc Setup";
    begin
        GetSetup(Setup);

        Setup.TestField("Default Service Code");

        Service.Get(Setup."Default Service Code");
    end;

    procedure CreateDefaultService()
    var
        Service: Record "EDoc Service";
    begin
        if Service.FindFirst() then
            exit;

        Service.Init();
        Service.Code := 'SOVOS_TEST';
        Service.Description := 'Sovos Test';
        Service.Provider := Service.Provider::Sovos;
        Service.Environment := Service.Environment::Test;
        Service.Enabled := true;
        Service."Base URL" := 'https://api-test.sovos.com';
        Service."OAuth URL" := 'https://api-test.sovos.com/oauth/token';
        Service."Invoice Endpoint" := '/compliance-network/v1/france/invoices';
        Service."E-Reporting Endpoint" := '/compliance-network/v1/france/e-reports';
        Service."Status Endpoint" := '/compliance-network/v1/france/messages';
        Service.Insert(true);
    end;
}