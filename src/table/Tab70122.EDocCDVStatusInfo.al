// Paramètres d'un statut CDV à transmettre (flux 6). Volontairement en table
// "paramètres" plutôt que de figer une table de correspondance de statuts complète,
// puisque l'onglet "Status MDT105" du mapping (table complète des codes) est arrivé vide.
table 70122 "EDoc CDV Status Info"
{
    Caption = 'EDoc CDV Status Info';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Referenced Document Id"; Text[100])
        {
            Caption = 'Identifiant du document/flux référencé';
            // ram:ReferenceReferencedDocument/IssuerAssignedID
        }
        field(10; "CDV Document Name"; Text[100])
        {
            Caption = 'Nom du document CDV';
            // ram:ExchangedDocument/Name, ex. "CDV-212_Encaissee"
        }
        field(20; "Status Code (UNTDID 1373)"; Integer)
        {
            Caption = 'StatusCode (UNTDID 1373)';
            // ram:ReferenceReferencedDocument/StatusCode - référentiel générique,
            // DISTINCT de "Process Condition Code" (référentiel PPF). Ex. confirmé : 47.
        }
        field(30; "Document Type Code"; Code[10])
        {
            Caption = 'TypeCode du document référencé';
            // ex. 380 = facture commerciale, cf. mapping flux 10.1
        }
        field(40; "Process Condition Code"; Enum "EDoc CDV Process Condition")
        {
            Caption = 'ProcessConditionCode (PPF)';
        }
        field(41; "Process Condition Label"; Text[50])
        {
            Caption = 'ProcessCondition (libellé)';
            // ex. "Encaissee" (sans accent dans l'exemple XML fourni)
        }
        field(50; "Receipt DateTime"; DateTime)
        {
            Caption = 'Date de réception de l''objet référencé';
        }
        field(60; "Is Error Status"; Boolean)
        {
            Caption = 'Statut d''erreur (TypeCode=305)';
            // Sinon TypeCode=23 (information) - cf. mapping
        }
    }

    keys
    {
        key(PK; "Referenced Document Id")
        {
            Clustered = true;
        }
    }
}
