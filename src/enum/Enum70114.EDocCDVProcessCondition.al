// Codes "ProcessConditionCode" du cycle de vie PPF (référentiel français, distinct de
// StatusCode qui est UNTDID 1373). SEULE la valeur 212/Encaissée est confirmée par
// l'exemple XML fourni. Les autres (Déposée/Rejetée/Refusée) sont des valeurs plausibles
// par analogie avec le SDD Basware (§5, 13 motifs de refus), mais leurs codes numériques
// réels ne sont PAS confirmés - l'onglet "Status MDT105" du mapping est arrivé vide.
// À CORRIGER dès que la table complète des statuts est disponible.
enum 70114 "EDoc CDV Process Condition"
{
    Extensible = true;

    value(212; Encaissee)
    {
        Caption = 'Encaissée';
        // CONFIRMÉ par l'exemple XML (UC28-SCI-S7A) : ProcessConditionCode=212
    }
    value(1; Deposee)
    {
        Caption = 'Déposée';
        // Code numérique NON CONFIRMÉ - placeholder
    }
    value(2; Rejetee)
    {
        Caption = 'Rejetée';
        // Code numérique NON CONFIRMÉ - placeholder
    }
    value(3; Refusee)
    {
        Caption = 'Refusée';
        // Code numérique NON CONFIRMÉ - placeholder
    }
}
