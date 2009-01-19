aircraft.livery.init("Aircraft/DerKleineUhu/Models/Liveries");
var gummiseil_dialog = gui.Dialog.new("/sim/gui/dialogs/DerKleineUhu/gummiseil/dialog",
                        "Aircraft/DerKleineUhu/Dialogs/Gummiseil.xml");

var Gummiseil = {
  new : func( base ) {
    var obj = {};
    obj.parents = [Gummiseil];

    obj.rootN = props.globals.getNode( base, 1 );
    obj.fixedLengthN = obj.rootN.initNode( "fixed-length-m", 30 );
    obj.minLengthN = obj.rootN.initNode( "gummi-min-length-m", 10 );
    obj.springConstantN = obj.rootN.initNode( "spring-constant-Npm", 1 );

    obj.lengthN = obj.rootN.initNode( "length-m", obj.fixedLengthN.getValue() + obj.minLengthN.getValue() );
    obj.forceN  = obj.rootN.initNode( "force-N", 0 );
    return obj;
  },

  run : func {
    var stretch = me.lengthN.getValue() - me.fixedLengthN.getValue() - me.minLengthN.getValue();
    if( stretch <= 0 ) {
      me.forceN.setDoubleValue( 0 );
    } else {
      me.forceN.setDoubleValue( stretch * me.springConstantN.getValue() );
    }
    settimer( func { me.run() }, 0 );
  },
};

Gummiseil.new( "/sim/model/DerKleineUhu/gummiseil" ).run();
