codeunit 70117 "EDoc Sovos EReporting Builder"
{
    Access = Internal;

    procedure BuildEReportingXml(
        EDoc: Record "EDoc Document"): Text
    var
        Flow101: Codeunit "EDoc ER Flow 10.1 Builder";
        Flow102: Codeunit "EDoc ER Flow 10.2 Builder";
    begin

        case EDoc."Flow Type" of

            "EDoc Flow Type"::International:
                exit(
                    Flow101.BuildXml(
                        EDoc));

            "EDoc Flow Type"::Collection:
                exit(
                    Flow102.BuildXml(
                        EDoc));

        end;

    end;
}