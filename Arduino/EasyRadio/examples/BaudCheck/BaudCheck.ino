/*

  Author:  David Schmider, Rick Winscot
  Date:    November 12, 2012

  Notes:   Sketch used to get the baud rate of an easyRadio connected
           to your Arduino.
*/

#include <SoftwareSerial.h>

// RX / TX pins you have your easyRadio connected to.
SoftwareSerial easyRadio(2, 3);

// Any number of baud rates to check for.
long baudRate[] = {2400, 4800, 9600, 19200, 38400, 312500, 76800, 115200};

// Carries the result of a valid baud check.
String result;

// Did the baud check succeed or fail?
boolean error = true;


// Application initialization.
void setup()  
{
  // Regular serial used for debug.
  Serial.begin( 19200 );

  // Wait for serial port to open --> un-comment if using Leonardo.
  // while (!Serial) {
  // ;
  //}
  
  Serial.println( "" );
  Serial.println( "Running easyRadio baud check." );
  delay( 1000 );
  
  int numRates = sizeof(baudRate) / sizeof(long);
  
  for ( int i = 0; i < numRates; i++ ) {
    if ( baudCheck( baudRate[i] ) == 1 ) {
      Serial.println( "good to go!" );
      Serial.print( "EasyRadio up and running at " );
      Serial.print( baudRate[i] );
      Serial.println( " baud" );
      
      error = false;
      break;  
    }
    else {
      Serial.println( "nope." );  
    }
      
    delay( 1000 );
  }
  
  if ( error ) {
    Serial.println( "Could not initialize an easyRadio." ); 
  }
}


// Main program loop...
void loop()
{
  while ( !error ){
    // The rest of your application bits go here. 
    Serial.print( "Hello " );
    Serial.print( "World " );
    Serial.println( "..." );
  
    delay( 2000 );      
  }
}


// Checks for an easyRadio at the specified baud rate.
int baudCheck( long baud ) 
{
  Serial.print( "Checking " );
  Serial.print( baud );
  Serial.print( " baud... " );
  
  // Init if possible... and wait a bit.
  easyRadio.begin( baud );
  delay( 500 );
  
  // Query for baud rate - will return nothing if it fails.
  easyRadio.write( "ER_CMD#U?" );
  delay( 10 );
  
  // If the query is successful, we'll get back a result.
  if ( easyRadio.available() == 9 ) {   
    result = "         ";
    
    // Pump the serial contents into the result.
    for ( int i = 0; i < 9; i++ ) {
      char c = easyRadio.read();
      result.setCharAt( i, c ); 
    }
  }
  
  // Debug...
  // Serial.println( result ); 
   
  if ( result.startsWith( "ER_CMD#U" ) ) {
    // Debug...
    // Serial.print( "command returned: " );
    // Serial.println( result.charAt(8) );
     
     return 1;
   }

  return 0;
}
