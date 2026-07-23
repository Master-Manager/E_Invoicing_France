page 70105 "JSON Viewer"
{
    PageType = Card;
    SourceTable = "JSON Viewer";
    Caption = 'JSON Viewer';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(ContentTxt; ContentTxt)
            {
                ApplicationArea = All;
                MultiLine = true;
                Editable = false;
                ShowCaption = false;
            }
        }
    }

    var
        ContentTxt: Text;
        PageTitle: Text;

    procedure SetContent(Title: Text; JsonText: Text)
    begin
        PageTitle := Title;
        ContentTxt := JsonText;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Caption(PageTitle);
    end;
}