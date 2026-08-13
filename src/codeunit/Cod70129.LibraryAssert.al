// Codeunit d'assertion maison, substitut léger à "Library Assert" (Microsoft) au cas où
// cette dépendance système ne serait pas disponible/installable sur l'environnement.
// Mêmes signatures que celles utilisées dans "EDoc ER Flow 6 Builder Test", pour ne
// nécessiter qu'un changement du TYPE de la variable "Assert" dans le fichier de test
// (Codeunit "Library Assert" -> Codeunit "RFE Test Assert"), pas de sa logique.
//
// Principe : en AL, un Error() levé DANS une procédure [Test] est automatiquement
// intercepté par le framework de test et transforme le résultat en "Failure" avec le
// message d'erreur affiché en colonne "Error Message" - donc pas besoin de mécanisme
// spécial, juste appeler Error() quand l'assertion échoue.
codeunit 70129 "Library Assert"
{
    procedure IsTrue(Condition: Boolean; FailureMessage: Text)
    begin
        if not Condition then
            Error(FailureMessage);
    end;

    procedure IsFalse(Condition: Boolean; FailureMessage: Text)
    begin
        if Condition then
            Error(FailureMessage);
    end;

    procedure AreEqual(Expected: Variant; Actual: Variant; FailureMessage: Text)
    var
        ExpectedText: Text;
        ActualText: Text;
    begin
        ExpectedText := Format(Expected);
        ActualText := Format(Actual);
        if ExpectedText <> ActualText then
            Error('%1 (attendu: ''%2'', obtenu: ''%3'')', FailureMessage, ExpectedText, ActualText);
    end;

    procedure AreNotEqual(NotExpected: Variant; Actual: Variant; FailureMessage: Text)
    begin
        if Format(NotExpected) = Format(Actual) then
            Error('%1 (valeur non attendue mais obtenue quand même: ''%2'')', FailureMessage, Format(Actual));
    end;

    procedure Fail(FailureMessage: Text)
    begin
        Error(FailureMessage);
    end;

    /// <summary>
    /// À appeler juste après un bloc "asserterror" : vérifie que le dernier message
    /// d'erreur capturé contient bien le texte attendu (recherche partielle, pas une
    /// égalité stricte - comme le fait Library Assert.ExpectedError).
    /// </summary>
    procedure ExpectedError(ExpectedSubstring: Text)
    var
        LastError: Text;
    begin
        LastError := GetLastErrorText();
        if not LastError.Contains(ExpectedSubstring) then
            Error('Message d''erreur inattendu.\Attendu (contient): ''%1''\Obtenu: ''%2''', ExpectedSubstring, LastError);
    end;
}
