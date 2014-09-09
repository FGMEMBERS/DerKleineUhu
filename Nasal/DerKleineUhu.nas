aircraft.livery.init("Aircraft/DerKleineUhu/Models/Liveries");
var gummiseil_dialog = gui.Dialog.new("/sim/gui/dialogs/DerKleineUhu/gummiseil/dialog",
                        "Aircraft/DerKleineUhu/Dialogs/Gummiseil.xml");

var Gummiseil = {
  new : func( base ) {
    var obj = {};
    obj.parents = [Gummiseil];

    obj.rootN = props.globals.getNode( base, 1 );
    obj.fixedLengthN = obj.rootN.initNode( "fixed-length-m", 10 );
    obj.minLengthN = obj.rootN.initNode( "gummi-min-length-m", 10 );
    obj.maxLengthN = obj.rootN.initNode( "gummi-max-length-m", 45 );
    obj.springConstantN = obj.rootN.initNode( "spring-constant-Npm", 1 );

    obj.lengthN = obj.rootN.initNode( "length-m", obj.fixedLengthN.getValue() + obj.minLengthN.getValue() );
    obj.forceN  = props.globals.initNode( "/fdm/jsbsim/launcher-force-lbs", 0 );
    obj.xN = props.globals.initNode( "/fdm/jsbsim/external_reactions/launcher/x", 0 );
    obj.yN = props.globals.initNode( "/fdm/jsbsim/external_reactions/launcher/y", 0 );
    obj.zN = props.globals.initNode( "/fdm/jsbsim/external_reactions/launcher/z", 0 );

    obj.releaseN = obj.rootN.initNode( "release", 0, "BOOL" );
    obj.hookedN  = obj.rootN.initNode( "hooked", 0, "BOOL" );

    obj.altitudeN = props.globals.getNode( "/position/altitude-ft" );
    obj.latitudeN = props.globals.getNode( "/position/latitude-deg" );
    obj.longitudeN = props.globals.getNode( "/position/longitude-deg" );
    obj.headingDegN = props.globals.getNode( "/orientation/heading-deg" );

    obj.fixedEnd = geo.Coord.new();
    return obj;
  },

  run : func {

    var force = 0;
    var length = me.fixedLengthN.getValue() + me.minLengthN.getValue();
    var x = 0;
    var y = 0;
    var z = 0;

    if( me.hookedN.getValue() ) {
      var myPosition = geo.Coord.new();
      myPosition.set_latlon( me.latitudeN.getValue(),
                             me.longitudeN.getValue(),
                             me.altitudeN.getValue() *globals.FT2M );
      length = myPosition.distance_to( me.fixedEnd );
      force = (length - me.fixedLengthN.getValue() - me.minLengthN.getValue()) * me.springConstantN.getValue();
      if( length - me.fixedLengthN.getValue() - me.minLengthN.getValue() > me.maxLengthN.getValue() ) {
        print( "Gummiseil is broken" );
        me.hookedN.setValue( 0 );
      }

      
      if( length > 0.1 ) {
        # calculate x, y and z distance
        var length_2 = length*length;
        z = myPosition.alt()-me.fixedEnd.alt();
        x = length > z ? math.sqrt( length_2 - z*z ) : 0;
        if( x < 5 ) {
          me.hookedN.setValue( 0 );
          print( "Gummiseil released" );
          globals.interpolate( "/controls/flight/rudder", 1.0, 2 );
        } else {
        }
      }
      if( force < 0 )
        force = 0;

    } else {

    }
    me.forceN.setDoubleValue( force );
    me.lengthN.setDoubleValue( length );
    me.xN.setDoubleValue( x / 150 );
    me.yN.setDoubleValue( y / 150 );
    me.zN.setDoubleValue( z / 150 );

    settimer( func { me.run() }, 0 );
  },

  # place the far end of our gummiseil at dist_m in heading direction
  place : func( dist_m ) {
    if( me.hookedN.getValue() == 0 ) {
      var myPosition = geo.Coord.new();
      myPosition.set_latlon( me.latitudeN.getValue(),
                             me.longitudeN.getValue(),
                             me.altitudeN.getValue() *globals.FT2M );
      me.fixedEnd = myPosition;
      me.fixedEnd.apply_course_distance( me.headingDegN.getValue(), dist_m );
      geo.put_model( "Aircraft/DerKleineUhu/Models/Flag.ac", me.fixedEnd );
      setprop( "/controls/flight/rudder", 0 );
      setprop( "/controls/flight/rudder-trim", 0 );
      me.hookedN.setBoolValue( 1 );
    }
  },
};

var gummiseil = nil;

var placeGummiseil = func {
  if( gummiseil != nil ) 
    gummiseil.place( 60 );
}

var release = func {
}

setlistener("sim/signals/fdm-initialized", func {
  gummiseil = Gummiseil.new( "/sim/model/DerKleineUhu/gummiseil" );
  gummiseil.run();
});

