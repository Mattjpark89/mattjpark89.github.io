/*
 * Author: Z
 * 
 * Public Domain. You cannot copyright this, or any derivative work.
 * Free to use for commercial or noncommercial purposes. 
 * Absolutely no implied warranty, you are 100% responsibel and I am not
 * No restrictions for usage, use for whatever
 *
 * Please give credit, don't be a jerk.
 *
 */

//Powerful AS2.0 utilities to convert flash <-> text and so on.
class TexDa{
	
	//Variable names can only contain these characters (error checking)
	//Numerals must be consistent (single decimal, only digits, e+ e- notation accepted?)
	//All things must be properly terminated & closed
	private static var _asciiVNameTable:String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_";

	public static var _ascii64Table:String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-+";
	private static var _ascii64TableReverse = undefined;
	private static var _asciiTable:String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-+!@#$%^&*()_=~`<>?:{}|[]\;',./+-\"";

	
	//
	//LZSS is best for string data (IE LDF format data, as text.)
	//
	
	/*
	static public function lzssDecompressgetbit( D, n, SS )
	{
		//static int buf, mask = 0;
		var x:Number = 0;
		for (var i:Number = 0; i < n; i++) {
			if (SS.currreadmask == 0) {

				if( SS.currreadbyte < D.length ){
					SS.currreadbuf = D[ SS.currreadbyte ];
					SS.currreadbyte ++;
				}else{
					return -1;
				}

				SS.currreadmask = 128;
			}
			x <<= 1;
			if (SS.currreadbuf & SS.currreadmask){
				x++;
			}
			SS.currreadmask >>= 1;
		}
		return x;
	}
	*/

	//Given 0..255 values (bytes) compress them with LZSS algorithm, return the array of byte values once decompressed.
	static public function lzssDecompress( input:Array ) : Array
	{
		
		var EI:Number = 11;  // typically 10..13
		var EJ:Number = 4;  // typically 4..5 
		var P:Number = 1;  // If match length <= P then output one character
		var N:Number = (1 << EI);  // buffer size
		var F:Number = ((1 << EJ) + P);  // lookahead buffer size
		
		//DECODING variables:
		var SS:Object = new Object();
		SS.currreadbyte = 0;	//current bit we are reading form input...
		SS.currreadbuf = 0;	//current bit we are reading form input...
		SS.currreadmask = 0;	//current bit we are reading form input...
		
		var getbit = function( D, n, S ) : Number
		{
			var i:Number;
			var x:Number;
			//static int buf, mask = 0;

			x = 0;
			for (var i:Number = 0; i < n; i++) {
				if (S.currreadmask == 0) {

					if( S.currreadbyte < D.length ){
						S.currreadbuf = D[ S.currreadbyte ];
						S.currreadbyte ++;
					}else{
						return -1;
					}

					S.currreadmask = 128;
				}
				x <<= 1;
				if (S.currreadbuf & S.currreadmask)
					x++;
				S.currreadmask >>= 1;
			}
			return x;
		}

		var i:Number=0;
		var j:Number=0;
		var k:Number=0;
		var r:Number=0;
		var c:Number=0;

		var buffer:Array = new Array( 2 * N );
		
		for (var i:Number = 0; i < (N - F); i++){
			buffer[i] = 0x20;//' ';
		}

		r = N - F;
		
		var output:Array = new Array();

		c = getbit( input, 1, SS );
		while( c >= 0 ){
			if (c) {
				c = getbit( input, 8, SS );
				if( c < 0 )
					break;

				output.push( c );

				buffer[r++] = c;
				r &= (N - 1);
			} else {
				i = getbit( input, EI, SS);
				if( i < 0 )
					break;
				j = getbit( input, EJ, SS);
				if( j < 0 )
					break;
				for (k = 0; k <= j + 1; k++) {
					c = buffer[(i + k) & (N - 1)];

					output.push( c );

					buffer[r++] = c;
					r &= (N - 1);
				}
			}
			c = getbit( input, 1, SS );
		}

		return output;
	}

	//Given 0..255 values (bytes) compress them with LZSS algorithm, return the array of byte values once compressed.
	static public function lzssCompress( input:Array ) : Array
	{
		var EI:Number = 11;  // typically 10..13
		var EJ:Number = 4;  // typically 4..5 
		var P:Number = 1;  // If match length <= P then output one character
		var N:Number = (1 << EI);  // buffer size
		var F:Number = ((1 << EJ) + P);  // lookahead buffer size
		
		//Special encode helpers.
		var putbit1 = function( output:Array, S )
		{
			S.bit_buffer |= S.bit_mask;

			if ((S.bit_mask >>= 1) == 0) {

				output.push( S.bit_buffer );

				S.bit_buffer = 0;
				S.bit_mask = 128;
				S.codecount++;
			}
		}

		var putbit0 = function( output:Array, S )
		{
			if ((S.bit_mask >>= 1) == 0) {

				output.push( S.bit_buffer );

				S.bit_buffer = 0;
				S.bit_mask = 128;
				S.codecount++;
			}
		}

		var flush_bit_buffer = function( output:Array, S )
		{
			if (S.bit_mask != 128) {

				output.push( S.bit_buffer );

				S.codecount++;
			}
		}

		var output1 = function( output:Array, c, S )
		{
			var mask:Number=0;

			S.putbit1(output, S);

			mask = 256;

			while (mask >>= 1) {

				if (c & mask)
					S.putbit1(output, S);
				else
					S.putbit0(output, S);
			}
		}

		var output2 = function( output:Array, x, y, S)
		{
			var mask:Number=0;

			S.putbit0(output, S);

			mask = S.N;

			while (mask >>= 1) {
				if (x & mask)
					S.putbit1(output, S);
				else
					S.putbit0(output, S);
			}

			mask = (1 << S.EJ);

			while (mask >>= 1) {
				if (y & mask)
					S.putbit1(output, S);
				else
					S.putbit0(output, S);
			}
		}


		//int Encode( const Array<uchar> & input, Array<uchar> & output )

		var SS:Object = new Object();
		SS.bit_buffer = 0;//bit_buffer = 0;
		SS.bit_mask = 128;//bit_mask = 128;
		SS.codecount = 0;//codecount = 0;
		SS.N = N;
		SS.EJ = EJ;
		SS.putbit1 = putbit1;
		SS.putbit0 = putbit0;
		SS.flush_bit_buffer = flush_bit_buffer
		SS.output1 = output1;
		SS.output2 = output2;
		
		trace( SS );
		
		//ENCODING variables
		var textcount:Number = 0;

		var buffer:Array = new Array( N * 2 );// = new uchar[N * 2];
		
		var Doutput:Array = new Array();
		
		//DECODING variables:
		var currwritebyte:Number=0;	//current bit we are reading form input...
		var currwritebuf:Number=0;	//current bit we are reading form input...
		var currwritemask:Number=0;	//current bit we are reading form input...

		var i:Number=0; 
		var j:Number=0; 
		var f1:Number=0; 
		var x:Number=0; 
		var y:Number=0; 
		var r:Number=0; 
		var s:Number=0; 
		var bufferend:Number=0;
		var c:Number=0;

		for (i = 0; i < N - F; i++)
			buffer[i] = 0x20//' ';

		for (i = N - F; i < N * 2; i++) {

			if( currwritebyte >= input.length )
				break;
			c = input[currwritebyte]; currwritebyte++;

			buffer[i] = c;  textcount++;
		}

		bufferend = i;  r = N - F;  s = 0;
		while (r < bufferend) {
			f1 = (F <= bufferend - r) ? F : bufferend - r;
			x = 0;
			y = 1;
			c = buffer[r];
			for (i = r - 1; i >= s; i--)
				if (buffer[i] == c) {
					for (j = 1; j < f1; j++)
						if (buffer[i + j] != buffer[r + j])
							break;
					if (j > y) {
						x = i;
						y = j;
					}
				}
			if (y <= P)
				output1(Doutput,c,SS);
			else
				output2(Doutput,x & (N - 1), y - 2,SS);
			r += y;
			s += y;
			if (r >= N * 2 - F) {
				for (i = 0; i < N; i++)
					buffer[i] = buffer[i + N];
				bufferend -= N;
				r -= N;
				s -= N;
				while (bufferend < N * 2) {

					if( currwritebyte >= input.length )
						break;
					c = input[currwritebyte]; currwritebyte++;

					buffer[bufferend++] = c;
					textcount++;
				}
			}
		}

		flush_bit_buffer(Doutput,SS);
		
		return Doutput;	//codecount;
	}

	static public function lzssRegressionTest() : Boolean
	{

		var dIN:Array = new Array();
		var itest = 1000;
		for( var i = 0; i < itest; i++ ){
			var valyoo:Number = Math.floor(Math.random()*255);
			dIN.push( valyoo );
			if( (i+1) >= itest ){ break; }
			var duplis = Math.floor( Math.random() * 5 );
			for( var j = 0; j < duplis; j++ ){
				dIN.push( valyoo );
				i++;
				if( i >= itest ){ break; }
			}
		}
		
		var compdIN = lzssCompress( dIN );
		var decompdIN = lzssDecompress( compdIN );
		if( decompdIN.length == dIN.length ){
			var imax = dIN.length;
			for( var i = 0; i < imax; i++ ){
				if( dIN[i] != decompdIN[i] ){
					trace( "LZSS FAILED @ " + i + " " + dIN[i] + " " + decompdIN[i] );
					trace( "C: " + compdIN );
					trace( "D: " + decompdIN );
					trace( "S: " + dIN );
					return false;
					break;
				}
			}
			trace( "LZSS PASSED!" );
			trace( "C: " +compdIN.length );
			trace( "D: " +decompdIN.length+" %"+100*(compdIN.length/decompdIN.length) );
			trace( "S: " +dIN.length );
			return true;
			
		}else{
			trace( "LZSS FAILED " + decompdIN.length + " ==? " + dIN.length );
			trace( "C: " +compdIN );
			trace( "D: " +decompdIN );
			trace( "S: " +dIN );
		}
		return false;
	}

	
	//Requires AS2.0 + flash 8 minimum

	//Used for saving cookies and stuff

	//This is how we compress data:
	//#include "lzss.as"
	//function lzssDecompress( input:Array ) : Array
	//function lzssCompress( input:Array ) : Array
	
	static public function matchAny( v, a ) : Boolean
	{
		var imax = a.length;
		for( var i = 0; i < imax; i++ )
		{
			if( a[i] == v ){ return true; }
		}
		return false;
	}
	
	static public function stringSanitizeAS( V ) : String
	{
		return V;
		
		/*
		//AS doesn't accept control characters as strings, so wrap them in " " if detected.
		//If we find a " in the string, wrap IT in a \"
		var imax = V.length;
		var R = "";
		var addquotes = 1;
		var escapeme = new Array( "\"", "\\" );
		var badchars = new Array( " ", "\t", "\r", "\n", "{", "}", "!", "=", "+", "-", "*", "/", "\\", "<", ">", "&", "|", "%", "$", "#", "@", "^", "(", ")", "[", "]", ";", ":", "'", ",", ".", "?", "~", "`" );
		var nums = new Array( "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" );
		
		for( var i = 0; i < imax; i++ ){
			var c = V.charAt(i);
			if( matchAny( c, escapeme ) ){
				addquotes = 1;
				R += "\\";
				R += c;
			}
			
			/ *else if( c == "\\" ){
				addquotes = 1;
				R += "\\";
				R += c;
			}else if( ( !addquotes ) && ( matchAny( c, badchars ) ) ){
				addquotes = 1;
				R += c;
			}else if( ( i == 0 ) && ( matchAny( c, nums ) ) ){
				addquotes = 1;
				R += c;
			}
			* /
			
			else{
				R += c;
			}
		}
		if( addquotes > 0 ){
			return "\"" + R + "\"";
		}else{
			return R;
		}
		*/
	}

	//
	//This generates a CODE string that defines a object in action script! neat!
	//
	static public function objectToASRecursive( V ) : String
	{
		var T = typeof( V );
		
		var outstr = "";
		//if( outstr == undefined ){ outstr = ""; }	//"default arguments"
		
		if( T == "string" ){
							
			outstr += "\"" + V + "\"";
		}else if( T == "number" ){
		
			outstr += String(V);
		}else if( T == "boolean" ){
			
			outstr += String(V);
		}else if( T == "object" ){
			
			outstr += "new Object(";
			
			var anyv = 0;
			for( var NV in V ){
				anyv = 1;
				break;
			}
			
			if( anyv ){
				
				outstr += " {"
				
				var hitt = 0;
				for( var NV in V ){
					
					//DETECT problems with NV being a bad string!?
					outstr += " " +  stringSanitizeAS( String(NV) ) + ":" + objectToASRecursive( V[NV] );
					outstr += ",";
					hitt = 1;
				}
				if( hitt != 0 ){	//Remove Comma.
					outstr = outstr.substr( 0, outstr.length - 1 );
				}
				
				outstr += " } "
			}
		
			outstr += ")";
			
		}else{
			
			//Invalid data type! Comment it out? (movieclip, function)
			outstr = "undefined /*" + outstr + "*/";
		}	
		
		// d:Array( 10,16,"sumthin",24,68 ),	(Array)
		
		return outstr;
	}
	//
	//This generates a CODE string that defines a object in action script! neat!
	//
	static public function objectToAS( AO ) : String
	{
		//For ALL values in AO, convert to ASCII string.
		return objectToASRecursive( AO );
	}
	//
	//This converts a CODE string into an object. It must be exact.
	//
	static public function objectFromAS( AS:String ) : Object
	{
		//Read in the string, store in object and return it
		var retval = undefined;
		eval( "retval = \"" + AS + "\";" );
		return retval;
	}


	//"Line Delimited Format" IS critical for accurately saving/loading flash data EASILY.
	//Just make an object, fill it with whatever atomic data (int, string, float, array, object)
	//And it can export it as such. 
	//Do NOT fill with custom classes or specialized objects.
	//Generic data objects only (like C-structs) with generic data (like number, string, object, array)
	//This isn't a limitation, it's good design. So deal with it.
	//

	//
	//This converts a "Line Delimited Format" object string into a Flash Object.
	//
	static public function objectFromLDF( AS:String, endchar:String ) : Object
	{
		if( endchar == undefined ){ endchar = "`"; }
		//Tabs => depth. Depth change MUST be preceeded by object name.
		//Arrays can be defined, and use depth syntax as shown (element in an array have only array depth + 1, and no prefix colon
		//Object heirarchies can be defined, and use depth syntax (objects require a name:value syntax per line.)
		//Unforutnately, there is no "array" export option, since it will be an object with 0,1,.. indexes.
		//(objname
		//	xval:"String value"
		//	yval:NumericalValue
		//	(objname
		//		x:0
		//		y:101.54
		//	)
		//	name:"Bitchin"
		//	[arrayname
		//		"string value"
		//		number
		//		171.0
		//	]
		//	extra:17
		//}
		//Note "tabs" are NOT required, only the endline character '\n'.
		//In this way, you could even store this as a CSV for clarity, using ',' as a end line.
		//All values are delimited, strings are always valid inside of " ", objects begin on (, end at ).
		// ect...
		//
		//
		//Simple enough.
		
		//save_icon:1,[myarray,"Help",654,18,10,],(iterdown,tax:1,li0:"helper",),name:"Buffo",pos:17,
		
		var oary:Array = AS.split( endchar );	//FUCK, strings cannot CONTAIN endchar? Hm. can we escape them? Hm.
		var namestack:Array = new Array();
		var outobject = new Object();
		var currobject = outobject;
		var i_end:Number = oary.length;
		for (var i = 0; i<i_end; i++) {
			var S:String = oary[i];
			if( S.length > 0 ){
				switch( S.charAt(0) ){
					case '(':	//Begin object with name following '(' (push)
						//
						var objname = S.substr( 1 );
						
						//objname must obey syntax rules, otherwise data is corrupt:
						//	No preceeding numerals, no symbols from: ()*&^%$#@!"'/\:;<>,.{}[]|=+-\t\n\r
						//	Can ONLY contain: A-Z, a-z, 0-9 (after first character), _
						
						namestack.push( objname );
						//??? outobject[ array -> ][ objname ] = new Object();
						
						//Reselect object:
						//currobject = outobject;
						//for( var x = 0; x < namestack.length; x++ ){
						//	currobject = currobject[ namestack[x] ];
						//}
						
						currobject[objname] = new Object();
						currobject = currobject[objname];
						break;
					case ')':	//End previous object (pop)
						if( namestack.length > 0 ){
							namestack.pop();
							//Reselect object:
							currobject = outobject;
							for( var x = 0; x < namestack.length; x++ ){
								currobject = currobject[ namestack[x] ];
							}
						}else{
							trace("objectFromLDF Badly formatted Object: " );
						}
						//
						break;
					case '[':	//Begin array
						//
						var aryname = S.substr( 1 );
						namestack.push( aryname );
						//??? outobject[ array -> ][ objname ] = new Object();
						
						//Reselect object:
						//currobject = outobject;
						//for( var x = 0; x < namestack.length; x++ ){
						//	currobject = currobject[ namestack[x] ];
						//}
						
						currobject[aryname] = new Array();
						currobject = currobject[aryname];
						break;
					case ']':	//Pop array
						//
						if( namestack.length > 0 ){
							namestack.pop();
							//Reselect object:
							currobject = outobject;
							for( var x = 0; x < namestack.length; x++ ){
								currobject = currobject[ namestack[x] ];
							}
						}else{
							trace("objectFromLDF Badly formatted Array: " );
						}
						break;
					default:
						//
						var isobjdata = S.indexOf(":");
						var isstring_first = S.indexOf("\"");	//!! careful, strings can contain \" sequence
						var isstring_last = S.lastIndexOf("\"");	//But with this logic, that's ignored, and 100% OK 
						
						//trace("Elm:" + isobjdata + " " + isstring_first + " " + isstring_last + " " + S );
						/*
						var curp = 
						while( true ){
							S.length
							
						}
						var instring = 0;
						for( var s = 0; s < S.length; s++ ){
							if( S[s] == "\"" ){
								if( s > 0 ){
									if( AS[s-1] == "\\" ){
										//ESCAPED. ignore it.
									}else{ 
										instring = !instring; 
									}
								}else{ instring = !instring;  }
							}
						}
						
						
						S.indexOf("\\\"");	//Find \" sequences, and ignore them?
						//First " that is NOT preceeded by \ is the end of the string.
						*/
						
						
						//Reselect object:
						//currobject = outobject;
						//for( var x = 0; x < namestack.length; x++ ){
						//	currobject = currobject[ namestack[x] ];
						//}
						
						if( isobjdata >= 0 ){
							
							var objpname = S.substr( 0, isobjdata );
							//Has a colon
							if( isstring_first >= 0 ){
								if( isstring_first == isobjdata + 1 ){
									//Object data with string
									currobject[ objpname ] = S.substr(isstring_first+1,isstring_last - isstring_first -1);
								}else{
									//Invalid object string data
									trace("objectFromLDF Invalid object string data.");
								}
							}else{
								//Object Number						
								currobject[ objpname ] = Number( S.substr( isobjdata + 1 ) );
							}
						}else{
							if( isstring_first >= 0 ){
								//Has at least 1 quotation;
								if( (isstring_first == 0) && (isstring_last == (S.length-1)) ){
									//Array String data
									currobject.push( S.substr(isstring_first+1,isstring_last - isstring_first -1) );
								}else{
									//Invalid string data
									trace("objectFromLDF Invalid string data.");
								}
							}else{
								//Array number
								currobject.push( Number( S ) );
							}
						}
						
						break;
				}
			}
		}
		
		//Error checking.
		if( namestack.length > 0 ){
			
			//Object is malformed.
			trace("#ERROR Object data is malformed; missing closure statements!");
			return null;
		}
		
		return outobject;
	}

	//
	//This generates a CODE string that defines a object in action script! neat!
	//
	static public function objectToLDFRecursive( V, objname:String, endchar:String ) : String
	{
		var T = typeof( V );
		
		var outstr = "";
		
		if( T == "string" ){
			
			if( objname.length > 0 ){//Prefix it if needed
				outstr += objname;
				outstr += ":";
			}
			//Escape the string for fucked up characters (no need to, so long as it does NOT contain any end characters)
			var ES = V;
			var currlen = ES.length;
			for( var s = 0; s < currlen; s++ ){
				
				if( ES.charAt(s) == "\"" ){
					//We *can* escape these characters, but no need to, parser only cares about splits.
					//ES = ES.substr(0, s) + "\\" + ES.substr(s);
					//s++;
					//currlen++;
				}else if( ES.charAt(s) == endchar ){
					trace( "#ERROR input string contains endchar; this is NOT allowed. We removed it." );
					ES = ES.substr(0, s) + ES.substr(s+1);
					currlen--;
					s--;
				}
			}
			
			outstr += "\"" + ES + "\"";	//Surround string in unescaped quotes (hm, original string can CONTAIN quotes. We escaped them.)
		}else if( T == "number" ){
			
			if( objname.length > 0 ){//Prefix it if needed
				outstr += objname;
				outstr += ":";
			}
			outstr += String(V);	//Numerical -> string
		}else if( T == "boolean" ){
			
			if( objname.length > 0 ){//Prefix it if needed
				outstr += objname;
				outstr += ":";
			}
			outstr += String(V);	//Numerical -> string
		}else if( T == "object" ){
			
			//Array checking: (all elements in an aray have in-order numeric keys!)
			var icompare:Number = 0;
			while( V.hasOwnProperty( String(icompare) ) ){
				icompare++;
			}
			var is_array:Number = 1;
			var ncompare:Number = 0;
			for( var NV in V ){
				var nn:Number = Number(NV);
				if( (nn < icompare) && (nn >= 0) ){
				}else{
					is_array = 0;
					break;
				}
				ncompare++;
			}
			if( ncompare != icompare ){
				is_array = 0;
			}
			
			if( is_array ){
				
				outstr += "[";	//Has an object name?
				outstr += objname;//! Missing object name! shitty!
				outstr += endchar;
				//! careful. Keys have to be in order.
				var icompare:Number = 0;
				while( V.hasOwnProperty( String(icompare) ) ){
					outstr += objectToLDFRecursive( V[icompare], "", endchar );
					icompare++;
				}
				outstr += "]";
			}else{
			
				if( objname.length < 1 ){
					trace("Invalid object name! A name is required!");
				}
				
				outstr += "(";	//Has an object name?
				outstr += objname;//! Missing object name! shitty!
				outstr += endchar;
				for( var NV in V ){
					outstr += objectToLDFRecursive( V[NV], NV, endchar );
				}
				outstr += ")";
			}
			
		}else{
			
			//Invalid data type! Comment it out? (movieclip, function)
			trace("objectToLDFRecursive Invalid data type:" + objname + ":" + outstr );
			//outstr = "/*" + outstr + "*/";
		}
		

		outstr += endchar;
		
		return outstr;
	}

	//
	//This generates a "Line Delimited Format" object string.
	//
	static public function objectToLDF( AO:Object, endchar:String ) : String
	{
		//For ALL values in AO, convert to ASCII string. Always requires an object container.
		if( endchar == undefined ){ endchar = "`"; }
		var outstr = "";
		for( var NV in AO ){
			outstr += objectToLDFRecursive( AO[NV], NV, endchar );
		}
		return outstr;
	}


	//Convert a string to a byte array
	static public function  stringToArray( S:String ) : Array
	{
		var A:Array = new Array(S.length);
		for( var i = 0; i < S.length; i++ ){
			A[i] = 255 & S.charCodeAt(i);
		}
		return A;
	}

	//Convert a byte array to a string
	static public function stringFromArray( A:Array ) : String
	{
		var S:String = "";
		for( var i = 0; i < A.length; i++ ){
			S += String.fromCharCode( 255&A[i] );
		}
		return S;
	}

	//Given a input array of binary 8 bit values, convert it into a Ascii x64 code from the given code table
	static public function arrayToA64( A:Array, X:String ) : String
	{
		if( X == undefined ){ X = _ascii64Table; }
		var S:String = "";
		var bits = 0;
		var bitcount = 0;
		for( var i = 0; i < A.length; i++ ){
			bits |= (255&A[i])<<bitcount;	//ByteArray
			bitcount += 8;
			while( bitcount >= 6 ){
				S += X.charAt( bits & 63 );
				bitcount -= 6;
				bits >>= 6;
			}
		}
		
		//Since we already added in all the 6 bits we could... what is this remainder? ignore it?
		while( bitcount > 0 ){
			S += X.charAt( bits & 63 );
			bitcount -= 6;
			bits >>= 6;
		}
		
		//Tack on some zeroes to compensate for differences? Hm... ignore via trim8? HMRGH.
		return S;
	}

	//Given a string of x64 values, convert back into binary array (hm)
	static public function arrayFromA64( S:String, X:String ) : Array
	{
		if( X == undefined ){ X = _ascii64Table; }
		
		var DCT:Array = new Array(255);
		for( var i = 0; i < 255; i++ ){
			DCT[i] = 0;
		}
		for( var i = 0; i < 64; i++ ){
			DCT[X.charCodeAt(i)] = i;	//char code -> bit index in table
		}
		
		var A:Array = new Array();
		
		var bits = 0;
		var bitcount = 0;
		for( var i = 0; i < S.length; i++ ){
			//bits <<= 6;
			bits |= (DCT[ (255&S.charCodeAt(i)) ] & 63)<<bitcount;
			bitcount += 6;
			while( bitcount >= 8 ){
				A.push( bits & 255 );	//HMRGH.
				bitcount -= 8;
				bits>>=8;
			}
		}
		
		//Since we only use enough bits to represent ALL 8 bit sequences, this is correct:
		while( bitcount >= 8 ){
			A.push( bits & 255 );	//HMRGH.
			bitcount -= 8;
			bits>>=8;
		}
		
		return A;
	}

	//Given a 8-byte input array, convert into ciphered array
	static public function arrayCipher( A:Array, C:String ) : Array
	{	
		//return A;	//Testing only

		var R:Array = new Array();
		var s = 0;
		var Crotate = new String();
		if( C == undefined ){ C = "FSFK"; }
		Crotate = C;	//Hm. Scramble string?
		for( var i = 0; i < A.length; i++ ){
			R[i] = 255&(A[i] ^ (255&Crotate.charCodeAt(s)));
			s++;
			if( s >= Crotate.length ){
				s -= Crotate.length;
				for( var j = 0; j < Crotate.length; j++ ){
					Crotate[j] = (Crotate[j]^324905761);
				}
			}
		}
		return R;
	}

	//Given a 8-byte ciphered input array, convert to unciphered array
	static public function arrayDecipher( A:Array, C:String ) : Array
	{
		//return A;	//Testing only
		
		var R:Array = new Array();
		var s = 0;
		var Crotate = new String();
		if( C == undefined ){ C = "FSFK"; }
		Crotate = C;	//Hm. Scramble string?
		for( var i = 0; i < A.length; i++ ){
			R[i] = 255&(A[i] ^ (255&C.charCodeAt(s)));
			s++;
			if( s >= Crotate.length ){
				s -= Crotate.length;
				for( var j = 0; j < Crotate.length; j++ ){
					Crotate[j] = (Crotate[j]^324905761);
				}
			}
		}
		return R;
	}

	//Convert a input 8-byte array into a compressed format
	static public function arrayCompress( A:Array ) : Array
	{
		return lzssCompress( A );
		/*
		//LZSS ? RLE bits? Complete symbol table => bit compression (flat rate)
		//	-> most inputs will be 7 bit codes only... hm.
		//	Try algorithm, if it makes the array larger, forget it.
		
		var symbols = new Object();
		var symbols_max = 0;
		var i_end = A.length;
		for( var i = 0; i < i_end; i++ ){
			
			var key = String( Number(A[i]) );
			if( symbols.hasOwnProperty( key ) ){
				
			}else{
				symbols[ key ] = symbols_max;
				symbols_max += 1;
			}
		}
		
		if( symbols_max < 16 ){
			
			//use 4 bits per value.
		}else if( symbols_max < 32 ){
			
			//use 5 bits per value.
		}else if( symbols_max < 64 ){
			
			//use 6 bits per value.
		}else if( symbols_max < 128 ){
			
			//use 7 bits per value.
		}else{
			
			//No compression.
		}
		*/
		
		return A;
	}

	//Convert a input compressed 8-byte array into decompressed format
	static public function arrayDecompress( A:Array ) : Array
	{
		return lzssDecompress( A );
		
		//Hmrgh. In this case, no compression.
		/*
		if( A.length > 0 ){
			var ctype = A[0];
			
			//
		}
		*/
		
		return A;
	}

	//Generate a random array of 0-255 values
	static public function arrayRandom( N:Number ) : Array
	{
		var A:Array = new Array( Math.floor(N) );
		for( var i = 0; i < N; i++ ){
			A[i] = Math.floor(Math.random()*255) & 255;
		}
		return A;
	}

	//Generate a random string of ASCII printable characters
	static public function stringRandom( N:Number ) : String
	{
		var S:String = new String();
		for( var i = 0; i < N; i++ ){
			var cx = Math.floor( Math.random()*_asciiTable.length );
			S += _asciiTable.charAt( cx );
		}
		return S;
	}

	//obj compare works on a variety of types. This is the internal recursive function
	static public function _objCmpRecur( A, B ) : Number
	{
		var TA = typeof( A );
		var TB = typeof( B );
		if( stringCmp( TA, TB ) == 0 ){
			if( TA == 'object' ){
				for( var a in A ){
					if( B.hasOwnProperty( a ) ){
						var retv = _objCmpRecur( A[a], B[a] );
						if( retv != 0 ){
							return retv;
						}
					}else{
						trace( "_objCmpRecur: Different properties! " + a +" "  );
						return -3;
					}
				}
				return 0;	//Identical
			}else if( TA == 'string' ){
				var retv = stringCmp( A, B );
				if( retv != 0 ){
					//trace( "_objCmpRecur: Different string values!"+retv );
					return retv;
				}
				return 0;	//Identical
			}else{
				if( A != B ){
					if( TA == "number" ){
						var diff = Math.abs(A - B);	//Epsilon delta; delta should change based on power of numbers.
						//IE, error = 1 * 10 ^ (9 - pow2( max(A,B) )) ?
						if( diff < 0.000001 ){	//Practical delta
							//trace( "_objCmpRecur: Different numerical pure values; trimmed by epsilon 0.000001: " + A + " " + B + " "+ diff );
							return 0;
						}else{
							//trace( "_objCmpRecur: Different numerical pure values! " + A + " " + B + " "+ diff );
						}
					}else{
						//trace( "_objCmpRecur: Different pure values! " + A + " " + B );
					}
					return -1;
				}
				return 0;	//Identical
			}
		}else{
			//trace( "_objCmpRecur: Different types!" );
			return -2;	
		}
	}

	//Compare objects, returns 0 if exactly equal
	static public function objCmp( A, B ) : Number
	{
		return _objCmpRecur( A, B );
	}

	//Compare arrays, returns 0 if exactly equal
	static public function arrayCmp( A:Array, B:Array ) : Number
	{
		if( A.length == B.length ){
			for( var i = 0; i < A.length; i++ ){
				if( A[i] != B[i] ){
					return (A[i] - B[i]);
				}
			}
			return 0;
		}else{
			return (A.length - B.length);
		}
	}

	//Compare strings, returns 0 if exactly equal
	static public function stringCmp( A:String, B:String ) : Number
	{
		if( A.length == B.length ){
			for( var i = 0; i < A.length; i++ ){
				if( A.charAt(i) != B.charAt(i) ){
					return (A.charCodeAt(i) - B.charCodeAt(i));
				}
			}
			return 0;
		}else{
			return (A.length - B.length);
		}
	}

	//
	static public function stringComputeChecksum( S:String, ignorelast:Number ) : String
	{
		if( S.length > 7 ){
			var i:Number = 0;
			var i_end:Number = S.length - ignorelast;
			var hash:Number = 5381;	//djb2 hash
			//var hash:Number = 0;	//sdbm hash
			while( i < i_end ){
				var v:Number = 255 & S.charCodeAt(i);
				hash = v + ( (hash<<5) + hash );	//djb2 hash
				//hash = v + (hash<<6) + (hash<<16) - hash;	//sdbm hash			
				i++;
			}
			var hex = hash.toString(16);
			if( hex.charAt(0) == '-' ){	//FUCK YOU, flash
				hex = hex.substring( 1 );
			}
			while( hex.length < 8 ){
				hex = "0" + hex;
			}
			return hex;
		}
		return "";
	}

	//Returns 0 if perfect, and checksum matches exactly.
	static public function stringCheckChecksum( S:String ) : Number
	{
		var xo = stringComputeChecksum( S, 8 );
		
		var savedhex = S.substring( S.length - 8, S.length );
		
		if( xo == savedhex ){
			
			return 0;
		}else{
			
			return -1;
		}
	}

	static public function stringTrimChecksum( S:String ) : String
	{
		return S.substring( 0, S.length - 8 );
	}


	//String compression/obsfuscation via user selected cipher string (internal algorithm mess)
	static public function stringCompressA64( S:String, C:String ) : String
	{
		if( C == undefined ){ C = "SA)($*#)*gjk"; }
		
		//1. Convert input string into binary 8-bit data array
		var sa = stringToArray( S );
		//2. Compress/Cipher binary data with rotating addition Xor cipher (all 8 bits are used, input string ciphes it out.)
		var ca = arrayCompress( sa );
		var qa;
		if( C.length > 0 ){
			qa = arrayCipher( ca, C );
		}else{
			qa = ca;
		}
		//3. Convert binary array into ASCII x64 code (via fixed internal table)
		var S = arrayToA64( qa, _ascii64Table );
		//Return result.
		return S;
	}

	static public function stringDecompressA64( S:String, C:String ) : String
	{
		if( C == undefined ){ C = "SA)($*#)*gjk"; }
		
		//1. Convert x64 string into binary 8-bit data array
		var deca = arrayFromA64( S, _ascii64Table );
		//2. Convert data array back into uncompressed/unciphered form
		var qa;
		if( C.length > 0 ){
			qa = arrayDecipher( deca, C );
		}else{
			qa = deca;	
		}
		var ra = arrayDecompress( qa );
		//3. Convert binary data into input string (symbol table decompression in bits)
		var S = stringFromArray( ra );
		//Return result.
		return S;
	}

	//Usage (for save files):
		
	//compthis = objectToLDF( mysaveobj, "`" );
	//savethis = stringCompressA64( compthis, cipherkey );	//Required to prevent cookie save errors (A64 guarantees printable text only output.)
	//cookieSave( savethis, cookienamedata );

	//...

	//decompthis = cookieLoad( cookienamedata );
	//loadthis = stringDecompressA64( decompthis, cipherkey );	//Required to prevent cookie save errors (A64 guarantees printable text only output.)
	//mysaveobj = objectFromLDF( loadthis, "`" );


	//Convert a object (with only simply properties!) into a compressed, encrypted string for saving. You must pass a cipher key to encrypt.
	static public function objectToLDFCompA64( inobj:Object, cipherkey:String, usedelimiter:String ) : String
	{
		if( usedelimiter == undefined ){ usedelimiter = "`"; }
		if( cipherkey == undefined ){ cipherkey = ""; }
		var compstr = TexDa.objectToLDF( inobj, usedelimiter );	//Note '`' is delimiter
		
		//Compute checksum bits against string (hm, insert 4 characters AT END? or interspersed + end?)
		compstr += stringComputeChecksum( compstr, 0 );
		
		var SS = stringCompressA64( compstr, cipherkey );
		
		return SS;
		//return objectToLDF( inobj, usedelimiter );
	}

	//Convert a encrypted string into a LDF object, and return the result object. Can cause severe errors if you mess with it.  You must pass a cipher key to encrypt.
	static public function objectFromLDFCompA64( instr:String, cipherkey:String, usedelimiter:String ) : Object
	{
		
		if( usedelimiter == undefined ){ usedelimiter = "`"; }
		if( cipherkey == undefined ){ cipherkey = ""; }
		var loadthis = stringDecompressA64( instr, cipherkey );
		
		//Check checksum bits against string (hm, remove 4 characters AT END? or interspersed + end?)
		if( stringCheckChecksum( loadthis ) == 0 ){
			var SO = objectFromLDF( stringTrimChecksum( loadthis ), usedelimiter );
			return SO;
		}else{
			var SO = new Object();
			SO._error = "INVALID CHECKSUM! DATA WAS TAMPERED WITH! ";
			return SO;
		}
		//return objectFromLDF( instr, usedelimiter );
	}

	//
	//
	//Usage (for object -> text):
	//
	//savethis = objectToLDFCompA64( inputobj );
	//
	//outobj = objectFromLDFCompA64( inputstring );

	static public function regressionTestLDF()
	{
		
		//REGRESSION TEST proof positive:
		
		trace( "Testing stringToArray / stringFromArray:" );
		var ins = stringRandom( 5 + Math.random()*100 );
		var ta = stringToArray( ins );
		var ts = stringFromArray( ta );
		if( (stringCmp(ins,ts)==0) ){
			trace("\tPassed!");
		}else{
			trace("\tFAILED: " );
			trace( "Array: " + ta );
			trace( ins );
			trace( ts );
		}
		trace( "" );

		trace( "Testing arrayCipher / arrayDecipher:" );
		var ina = arrayRandom( 5 + Math.random()*100 );
		var ca = arrayCipher( ina );
		var ra = arrayDecipher( ca );
		if( (arrayCmp(ina,ra)==0) ){
			trace("\tPassed!");
		}else{
			trace("\tFAILED: " );
			trace( "Ciphered: " + ca );
			trace( ina );
			trace( ra );
		}
		trace( "" );

		trace( "Testing arrayCompress / arrayDecompress:" );
		var incc = arrayRandom( 5 + Math.random()*100 );
		var ca = arrayCompress( incc );
		var rina = arrayDecompress( ca );
		if( (arrayCmp(incc,rina)==0) ){
			trace("\tPassed!");
		}else{
			trace("\tFAILED: " );
			trace( "Compa: " + ca );
			trace( incc );
			trace( rina );
		}
		trace( "" );
		
		trace( "Testing arrayToA64 / arrayFromA64:" );
		var in6a = arrayRandom( 5 + Math.random()*100 );
		var c6a = arrayToA64( in6a, _ascii64Table );
		var r6a = arrayFromA64( c6a, _ascii64Table );
		var x6a = arrayToA64( r6a, _ascii64Table );
		if( ( stringCmp( c6a, x6a ) == 0) && (arrayCmp(in6a,r6a)==0) ){
			trace("\tPassed!");
		}else{
			trace("\tFAILED: " );
			trace( "Source:" + in6a );
			trace( "x64a: " + c6a );
			trace( "x64b: " + x6a );
			trace( "Ai: " + in6a );
			trace( "Ao: " + r6a );
		}
		trace( "" );
		
		trace( "Testing stringCompressA64 / stringDecompressA64:" );
		var inputxmlstr = stringRandom( 1000 );//Math.random()*1000 ); 
		var comax = stringCompressA64( inputxmlstr, "BitchPlease!" );
		var zexact = stringDecompressA64( comax, "BitchPlease!" );
		if( (stringCmp(inputxmlstr,zexact)==0) ){
			trace("\tPassed! " + comax.length + " / " + inputxmlstr.length );		
		}else{
			trace("\tFAILED: " );
			trace( "A64: " + comax );
			trace( "Input: " + inputxmlstr );
			trace( "Result: " + zexact );
			trace( comax.length + " / " + inputxmlstr.length );	
		}
		trace( "" );
		
		
		trace( "Testing LDF conversion formats; Note NONE of the input has a ` character, since that is used as a delimeter");
		var inputo:Object = new Object();
		inputo.isnum = 100;
		inputo.isstr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=\\|/~{}|[]\::<>?,./;'\"";
		inputo.isnumn = -42368;
		inputo.isfloat = 4306.34352;
		inputo.isfloatn = -1204.4612346;
		inputo.isstr2 = "<xml>Fuckit!</xml>"
		inputo.prase = " I'll have some \"tea\" with %[n] fucking crumpets. Ya'll Better \"move along\" now.";
		inputo.array1 = new Array( 10,3246,37,237,327,3275 );
		inputo.array2 = new Array( 10.68,3246.64,37.266,237.26,327.526,3275.3466 );
		inputo.array3 = new Array( 10.68,"Mixitup",37.266,237.26,"Ass",3275.3466 );
		inputo.subob = new Object();
			inputo.subob.isnum = 1031;
			inputo.subob.isstr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=\\|/~{}|[]\::<>?,./;'\"";
			inputo.subob.isnumn = -423468;
			inputo.subob.isfloat = 43406.343542;
			inputo.subob.isfloatn = -12044.4612346;
			inputo.subob.isstr2 = "<xml>Fuckit!</xml>"
			inputo.subob.array1 = new Array( 10,32446,37,237,4327,32475 );
			inputo.subob.array2 = new Array( 10.68,3246.64,337.2666,237.26,32437.526,32765.3466 );
			inputo.subob.array3 = new Array( 10.68,"Mixadatup",37.266,2637.26,"Assihk",36275.3466 );
			inputo.subob.subob = new Object();
				inputo.subob.subob.probs = "Yeah no."
		inputo.subob2.subob = new Object();
			inputo.subob2.probs = "Subbish."
		inputo.subob3.subob = new Object();
			inputo.subob3.probs = "Subbish2."
			
			
		//Regression test checksum?
		//stringComputeChecksum( compstr, 0 );
		//if( stringCheckChecksum( loadthis ) == 0 ){
		//	objectFromLDF( stringTrimChecksum( loadthis ), usedelimiter );
		//}
			
		//Example: Object assignemtn means no deep copy. Be careful.
		if( false ){
			var inputo2 = new Object();
			for( var v in inputo ){
				inputo2[v] = inputo[v];	
			}
			var cmpcheck = objCmp( inputo, inputo2 );
			inputo2.prase += " ";
			inputo2.extra = 90;
			var cmpcheck2 = objCmp( inputo, inputo2 );
			trace( "[" + inputo2.prase +"]" );
			trace( "[" +inputo.prase +"]" );
			trace( "[" + inputo2.extra +"]" );
			trace( "[" +inputo.extra +"]" );
			trace( "OD: " + cmpcheck + " " + cmpcheck2 );
		}
		trace( "" );
			
		var rho = objectToLDF( inputo, "`" );
		var rhs = objectFromLDF( rho, "`" );
		var rho2 = objectToLDF( rhs, "`" );
		var rhs2 = objectFromLDF( rho2, "`" );
		var retobp1 = objCmp( rhs, inputo );	//Should fail! we removed a character
		var retobp2 = objCmp( rhs, rhs2 );
		var retobp3 = objCmp( inputo, rhs2 );
		var retsp = stringCmp(rho,rho2);
		trace( "FC: " + retobp1 + " " + retobp2 +" "+retobp3 +" "+retsp);
		if( ( retobp1 == 0 ) && ( retobp2 == 0 ) && ( retobp3 == 0 ) ){
			if( retsp != 0 ){
				trace("\tPassed, data objects are identical, but strings are not (reordered or trimmed):" );
				trace( rho );
				trace("");
				trace( rho2 );
			}else{
				trace("\tPassed! " );		
			}
		}else{
			trace("\tFAILED: " );
			trace( rho );
			trace("");
			trace( rho2 );
		}
		trace( "" );
		
		trace( "Testing LDF + A64 conversion formats: ");
		
		var retss = objectToLDFCompA64( inputo );	//No cipher key == use internal one
		var retoss = objectFromLDFCompA64( retss );
		var rets2 = objectToLDFCompA64( retoss );
		var reto2 = objectFromLDFCompA64( rets2 );
		
		var retcobp1 = objCmp( inputo, retoss );
		var retcobp2 = objCmp( retoss, reto2 );
		var retcobp3 = objCmp( inputo, reto2 );
		
		if( ( retcobp1 == 0 ) && ( retcobp2 == 0 ) && ( retcobp3 == 0 ) ){
			if( (stringCmp(retss,rets2)==0) ){
				trace("\tPassed! " );		
			}else{
				trace("\tPassed, data objects are identical, but strings are not (reordered or trimmed):" );
				trace( retss );
				trace("");
				trace( rets2 );
			}
		}else{
			trace("\tFAILED: " );
			trace(retcobp1 );
			trace(retcobp2 );
			trace(retcobp3 );
			trace( "S1: " + retss );
			trace( "S2: " + rets2 );
			trace( "O1: " + retoss );
			trace( "O2: " + reto2 );
		}
		trace( "" );
		
	}

	//lollerskates. Really simple, invertible most likely. Cept' we delete data so.
	public static function hashSSM( S:String, MRounds:Number ) : String
	{
		var nSr = (S.length/4) + MRounds;
		
		var SResult = "X";
		
		var SHash = "0123";
		
		var SCurr = SHash + S;
			
		while( nSr > 0 ){
			
			nSr -= 1;
			
			var c0:Number = 229;//0xE5;	//These are the original codes to use.
			var c1:Number = 75;//0x4B;
			var c2:Number = 123;//0x7D;
			
			var ic:Number = 0;
			var sl:Number = SCurr.length;
			while( sl != 0 ){
				sl -= 1;
				c0 += ( SCurr.charCodeAt( sl ) )&255;
				if( sl != 0 ){
					sl -= 1;
					c1 += ( SCurr.charCodeAt( sl ) )&255;
					if( sl != 0 ){
						sl -= 1;
						c2 += ( SCurr.charCodeAt( sl ) )&255;
					}	
				}
			}
			
			//3 bytes => x64?
			var v0:Number = (c0 & 63);
			var v1:Number = ((c0>>6) & 3) | (c1&15);
			var v2:Number = ((c1>>4)&15) | (c2&3);
			var v3:Number = (c2>>2)&63;
			
			SHash =  String.fromCharCode(48 + v0) + String.fromCharCode(49 + v1) + String.fromCharCode(50 + v2) + String.fromCharCode(51 + v3);
		
			SCurr += SHash;
			
			SResult += SHash;
			
			if( SResult.length > 32 ){
				
				SResult = SResult.slice( 32 - SResult.length );
			}
			
			SCurr = SCurr.slice( 4 );
		}
		
		return SResult;
	}

	public static function randomString( slen:Number ) : String
	{
		var SR:String = "";
		for( var i = 0; i < slen; i++ ){
			SR += String.fromCharCode( 32 + Math.floor(Math.random()*(127-32)) );
		}
		return SR;
	}
	
};