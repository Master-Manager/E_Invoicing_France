page 70109 "Sovos Test Upload"
{
    PageType = Card;
    Caption = 'Sovos Test Upload';
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(FileName; FileName)
                {
                    Caption = 'Selected XML';
                    Editable = false;
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectFile)
            {
                Caption = 'Select XML';
                Image = Import;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LoadXml();
                end;
            }

            action(Send)
            {
                Caption = 'Send to Sovos';
                Image = SendElectronicDocument;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Integration: Codeunit "EDoc Sovos Integration";
                begin
                    if XmlText = '' then
                        Error('Please select an XML file first.');

                    Integration.SendTestXml(XmlText);

                    Message('Upload completed.');
                end;
            }
        }
    }

    var
        FileName: Text;
        XmlText: Text;
        sbdXml: Text;

    local procedure LoadXml()
    var
        InStr: InStream;
        FileFilter: Text;
        XmlDoc: XmlDocument;
        sbdBuilder: Codeunit "SBD Builder";
    begin
        FileFilter := 'XML (*.xml)|*.xml';

        if not UploadIntoStream(
                'Select XML Invoice',
                '',
                FileFilter,
                FileName,
                InStr)
        then
            exit;

        if not XmlDocument.ReadFrom(InStr, XmlDoc) then
            Error('The selected file contains an invalid XML structure.');

        XmlDoc.WriteTo(XmlText);

        // SbdXml :=
        // SBDBuilder.BuildSBD(
        //     XmlText,
        //     '340393065',
        //     '978307924',
        //     '70547558');

    end;
}
