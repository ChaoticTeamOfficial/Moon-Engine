package moon.backend.data;

typedef JudgementsComboFile = {
    var judgementAnims:PopAnimations;
    var comboAnims:PopAnimations;

    var comboRolls:Bool;
    var antialiasing:Bool;
    var judgementsSize:Float;
    var comboSize:Float;
}

typedef PopAnimations = {
    var appear:String;
    var disappear:String;
}

@:publicFields
@:forward
abstract JudgementsCombo(JudgementsComboFile) from JudgementsComboFile to JudgementsComboFile
{
    static function getData(skin:String):JudgementsCombo
    {
        if(Paths.exists('images/combo_judgements/$skin/config.json'))
            return Paths.JSON('images/combo_judgements/$skin/config');
        else
            trace('[JUDGEMENTS-COMBO] $skin was not found within the combo judgements directory.', "ERROR");

        return null;
    }
}