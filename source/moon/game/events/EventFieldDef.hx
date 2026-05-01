package moon.game.events;

/**
 * Defines a single interactive field for an event inside the Library panel.
 */
typedef EventFieldDef =
{
    /** The key used in the event's values object, must match what execute() reads. **/
    var name:String;

    /** Display label shown next to the input widget. **/
    var label:String;

    /** The input widget type to render. **/
    var type:EventFieldType;

    /** Default value pre-filled when the form opens. **/
    var ?defaultValue:Dynamic;

    /** Option strings for DROPDOWN fields. **/
    var ?options:Array<String>;

    /** Minimum value for NUMBER fields. **/
    var ?min:Float;

    /** Maximum value for NUMBER fields. **/
    var ?max:Float;

    /** Step increment for NUMBER fields. **/
    var ?step:Float;
}

/**
 * The type of input widget used to represent a field.
 */
enum abstract EventFieldType(String) from String to String
{
    /** Single-line text input. **/
    var TEXT = 'text';

    /** Numeric stepper (left/right arrows). **/
    var NUMBER = 'number';

    /** Dropdown selector; requires `options`. **/
    var DROPDOWN = 'dropdown';

    /** Boolean toggle checkbox. **/
    var CHECKBOX = 'checkbox';
}