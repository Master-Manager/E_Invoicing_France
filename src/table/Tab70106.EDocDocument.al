table 70106 "EDoc Document"
{
    Caption = 'E-Document';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        field(10; "Document Type"; Enum "EDoc Document Type")
        {
            Caption = 'Document Type';
        }
        field(11; "Flow Type"; Enum "EDoc Flow Type")
        {
            Caption = 'Flow Type'; // Mapping fonctionnel demandé pour le Type de Flux/Document
        }
        field(20; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }

        field(30; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }

        field(40; Status; Enum "EDoc Entry Status")
        {
            Caption = 'Status';
        }

        field(50; "Service Code"; Code[20])
        {
            TableRelation = "EDoc Service";
        }

        //------------------------------------
        // Invoice Information
        //------------------------------------

        field(100; "Invoice No."; Code[35])
        {
        }

        field(110; "Issue Date"; Date)
        {
        }

        field(120; "Due Date"; Date)
        {
        }

        field(130; "Currency Code"; Code[10])
        {
        }

        field(140; "Tax Currency Code"; Code[10])
        {
        }

        //------------------------------------
        // References (BT-10, BT-13, BT-72)
        //------------------------------------
        field(145; "Collection Date"; Date)
        {
            Caption = 'Collection Date';
        }
        field(150; "Buyer Reference"; Text[35])
        {
            Caption = 'Référence acheteur (BT-10)';
        }

        field(160; "Order No."; Code[20])
        {
            Caption = 'N° de commande (BT-13)';
        }

        field(170; "Actual Delivery Date"; Date)
        {
            Caption = 'Date de livraison effective (BT-72)';
        }

        //------------------------------------
        // Payment (BT-20, BT-81)
        //------------------------------------

        field(180; "Payment Means Code"; Code[10])
        {
            Caption = 'Code moyen de paiement UNTDID 4461 (BT-81)';
        }

        field(190; "Payment Terms Note"; Text[250])
        {
            Caption = 'Conditions de paiement (BT-20)';
        }

        //------------------------------------
        // Supplier
        //------------------------------------

        field(200; "Supplier Name"; Text[100])
        {
        }
        field(205; "Counterparty Type"; Enum "EDoc Source Type")
        {
            Caption = 'Counterparty Type';
        }
        field(210; "Supplier SIREN"; Code[20])
        {
        }

        field(220; "Supplier SIRET"; Code[20])
        {
        }

        field(230; "Supplier VAT No."; Code[30])
        {
        }

        field(240; "Supplier Address"; Text[100])
        {
        }

        field(250; "Supplier City"; Text[50])
        {
        }

        field(260; "Supplier Post Code"; Code[20])
        {
        }

        field(270; "Supplier Country"; Code[10])
        {
        }

        field(280; "Supplier Endpoint"; Code[50])
        {
        }

        //------------------------------------
        // Customer
        //------------------------------------

        field(300; "Customer No."; Code[20])
        {
        }

        field(310; "Customer Name"; Text[100])
        {
        }

        field(320; "Customer SIREN"; Code[20])
        {
        }

        field(330; "Customer SIRET"; Code[20])
        {
        }

        field(335; "VAT Rate"; Decimal)
        {
            Caption = 'VAT Rate (%)';
            DecimalPlaces = 0 : 5;
        }
        field(340; "Customer VAT No."; Code[30])
        {
        }
        field(345; "VAT Category"; Code[10])
        {
            Caption = 'VAT Category';
        }

        field(350; "Customer Address"; Text[100])
        {
        }

        field(360; "Customer City"; Text[50])
        {
        }

        field(370; "Customer Post Code"; Code[20])
        {
        }

        field(380; "Customer Country"; Code[10])
        {
        }

        field(390; "Customer Endpoint"; Code[50])
        {
        }

        //------------------------------------
        // Monetary Totals
        //------------------------------------

        field(500; "Amount Excl. VAT"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        field(510; "VAT Amount"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        field(520; "Amount Incl. VAT"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }

        field(530; "Payable Amount"; Decimal)
        {
            DecimalPlaces = 2 : 2;
        }
        field(540; "Allowance Amount"; Decimal)
        {
            Caption = 'Allowance Amount';
            DecimalPlaces = 2 : 2;
        }

        field(541; "Allowance Reason"; Text[250])
        {
            Caption = 'Allowance Reason';
        }

        field(542; "Allowance VAT Category"; Code[10])
        {
            Caption = 'Allowance VAT Category';
        }

        field(543; "Allowance VAT %"; Decimal)
        {
            Caption = 'Allowance VAT %';
            DecimalPlaces = 0 : 5;
        }
        //------------------------------------
        // UBL Metadata
        //------------------------------------

        field(600; "UBL Version"; Code[20])
        {
            InitValue = '2.1';
        }

        field(610; "Customization ID"; Text[250])
        {
            InitValue = 'urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr';
        }

        field(620; "Profile ID"; Code[20])
        {
            InitValue = 'S2';
        }

        field(630; "Invoice Type Code"; Code[10])
        {
            InitValue = '380';
        }

        //------------------------------------
        // Sovos
        //------------------------------------

        field(700; "Sovos Document Id"; Text[100])
        {
        }

        field(710; "Created At"; DateTime)
        {
        }

        field(720; "Sent At"; DateTime)
        {
        }

        field(730; "Last Modified At"; DateTime)
        {
        }

        field(740; "Error Message"; Text[2048])
        {
        }
        //------------------------------------
        // Document Information
        //------------------------------------

        field(800; "Document Record ID"; RecordId)
        {
            Caption = 'Document Record ID';
        }

        field(810; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
        }

        field(820; "Bill-to/Pay-to Name"; Text[100])
        {
            Caption = 'Bill-to/Pay-to Name';
        }

        field(840; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }

        field(850; "Index In Batch"; Integer)
        {
            Caption = 'Index In Batch';
        }

        field(860; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }

        field(870; "Incoming E-Document No."; Text[50])
        {
            Caption = 'Incoming E-Document No.';
        }

        field(880; "Header Buffer Field Count"; Integer)
        {
            Caption = 'Champs (Header XML Buffer)';
            FieldClass = FlowField;
            CalcFormula = count("EDoc Header XML Buffer" where("Buffer Entry No." = field("Entry No.")));
            Editable = false;
        }

        field(890; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption"
        where(
            "Object Type" = const(Table),
            "Object ID" = field("Table ID")));
            Editable = false;
        }
        //------------------------------------
        // E-Reporting
        //------------------------------------

        field(900; "Reporting Flow"; Option)
        {
            Caption = 'Reporting Flow';
            OptionMembers = "","10.1","10.2","10.3","10.4";
        }

        field(901; "Reporting Role"; Option)
        {
            Caption = 'Reporting Role';
            OptionMembers = "","Seller","Buyer";
        }

        field(902; "Transaction Category"; Code[10])
        {
            Caption = 'Transaction Category';
            // TLB1 TPS1 TNT1 TMA1
        }

        field(903; "Tax Due Date Type Code"; Code[10])
        {
            Caption = 'Tax Due Date Type';
        }

        field(904; "Transaction Currency"; Code[10])
        {
            Caption = 'Transaction Currency';
        }

        field(905; "Reporting Date"; Date)
        {
            Caption = 'Reporting Date';
        }

        field(906; "Transaction Count"; Integer)
        {
            Caption = 'Transaction Count';
        }

        field(907; "Correction"; Boolean)
        {
            Caption = 'Correction';
        }

        field(908; "Report ID"; Code[35])
        {
        }

        field(909; "Flow Direction"; Option)
        {
            OptionMembers = "","Outbound","Inbound";
        }

        field(910; "Report Type Code"; Code[10])
        {
            Caption = 'IN / RE';
        }

        field(911; "Payment Method Code"; Code[20])
        {
        }

        field(912; "Payment Date"; Date)
        {
        }

        field(913; "Payment Reference"; Code[50])
        {
        }
        field(914; "Collected Amount"; Decimal)
        {
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(Document; "Invoice No.")
        {
        }

        key(Source; "Table ID", "Document No.")
        {
        }
    }
}
