package com.kaltura.kdpfl.plugin.component
{
	//import com.kaltura.kdpfl.component.IComponent;
	
	import com.kaltura.kdpfl.view.containers.KHBox;
	import com.kaltura.types.KalturaCaptionType;
	
	import fl.controls.ScrollPolicy;
	
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
		 

 
	public class ClosedCaptions extends KHBox //implements IComponent
	{
		public static const ERROR_PARSING_SRT : String = "errorParsingSRT";
		
		public static const ERROR_PARSING_TT : String = "errorParsingTT";
		
		public static const HEIGHT_MARGIN : Number = 10;
		
		public static const WIDTH_MARGIN : Number = 10;
		
		public var isInFullScreen : Boolean = false;
		
		public var defaultBGColor : Number = 0x000000;
		
		public var defaultFontColor : Number = 0xFFFFFF;
		
		public var defaultFontSize : int =12;
		
		public var defaultFontFamily : String = "Arial";
		
		public var defaultGlowFilter : BitmapFilter;
		
		private var xmlns : Namespace;
		private var xmlns_tts :Namespace;
		
		private var _label:TextField;
		private var _captionsURLLoader:URLLoader;
		//map between captions URL and the parsed lines array of the file
		private var _currentCCFile:Array;
		//array of arrays of captions lines.
		private var _availableCCArray : Object;
		private var _isActive:Boolean = true;
		private var _widthBeforeResize : Number;
		private var _heightBeforeResize : Number;
		private var _fontBeforeResize : int;
		
		private var _fullScreenRatio : Number;
		
		
		public function ClosedCaptions()
		{
			_currentCCFile = new Array ();
			_availableCCArray = new Object();
			_isActive = true;

			_label = new TextField ();
			_label.type = TextFieldType.DYNAMIC;
			_label.multiline = true;
			_label.height = 0;
			_label.text = "";
			_label.selectable = false;
			_label.mouseWheelEnabled=false;
			addChild (_label);
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			setText ("");
		}

		override public function initialize():void
		{
			
		}
		
			
		
		public function setDimensions(w:Number, h:Number):void
		{
			
			 if ( w && h )
			 {
				this.width = w;
				this.height = h;
				var heightRatio : Number = 1;
				
				
				_label.height = h;
				//setText (null);
			 }
		}

		
		public function get fullScreenRatio():Number
		{
			return _fullScreenRatio;
		}
		
		public function set fullScreenRatio(value:Number):void
		{
			_fullScreenRatio = value;
		}

		
		public function closedCaptionsClicked():void
		{
			_isActive = !_isActive;
			_label.visible = _isActive;
		}
		
		public function loadCaptions (fileUrl:String, fileType:String):void
		{
			if (!_availableCCArray[fileUrl])
			{
				var myURLReq:URLRequest = new URLRequest(fileUrl);
	
				_captionsURLLoader = new URLLoader();
				_captionsURLLoader.dataFormat = URLLoaderDataFormat.TEXT;
				_captionsURLLoader.addEventListener(Event.COMPLETE, (fileType == "tt" || fileType == KalturaCaptionType.DFXP)? parseTimedText : parseSRT);
	
				_captionsURLLoader.addEventListener(ErrorEvent.ERROR, onError)
				_captionsURLLoader.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
				_captionsURLLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
				_captionsURLLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
	
	
				try
				{
					_captionsURLLoader.load (myURLReq);
				}
				catch (e:Error)
				{
					trace (e);
				}
			}
			else
			{
				_currentCCFile = _availableCCArray[fileUrl]
			}
			
			function parseSRT (e:Event):void
			{
				try{
					if (_captionsURLLoader.data)
					{
						var lines:Array = _captionsURLLoader.data.split ("\n");
						var currLine:CCLine = null;
						_currentCCFile = new Array ();
						var ccLineInd:int = 0;
						var tempCCLines : Array = new Array();
						for (var i:int = 0; i < lines.length; i++)
						{
							var str:String = lines [i].replace (/^\s+|\s+$/g, "");
							if (str == "")
							{
								if (currLine != null)
								{
									tempCCLines.push (currLine);
									currLine = null;
								}
								
								ccLineInd = 0;
								continue;
							}
							
							if (ccLineInd == 0)
							{
								currLine = new CCLine ();
							}
							else if (ccLineInd == 1)
							{
								var times:Array = str.split (" --> ");
								currLine.start = parseStrSRTTime (times [0]);
								currLine.end = parseStrSRTTime (times [1]);
							}
							else
							{
								if (currLine.text != "")
								{
									currLine.text += "<br>";
								}
								
								currLine.text += str;

								if (!defaultGlowFilter && !currLine.backgroundColor)
								{
									currLine.backgroundColor = defaultBGColor;
								}
								else if ( defaultGlowFilter )
								{
									currLine.showBGColor = false;
								}
								
							}
							
							ccLineInd++;
						}
						
						_currentCCFile = _currentCCFile.concat( tempCCLines );
						_availableCCArray[fileUrl] = new Array ().concat( tempCCLines );
					}
				}catch (e : Error) {
					this.dispatchEvent( new ErrorEvent(ERROR_PARSING_SRT) );
				}
			}
			
			function parseTimedText (e:Event):void
			{
				try{
					
					if (!_captionsURLLoader.data)
						return;
					var tt:XML = new XML (_captionsURLLoader.data);
					xmlns = tt.namespace();
					xmlns_tts = tt.namespace("tts");
					
					var body:XML = tt.xmlns::body[0];
					
					var head : XML = tt.xmlns::head[0];
					var styling : XML = head.xmlns::styling[0];
					var styles : XMLList = styling.xmlns::style;
					
					var stylingObject : Object = new Object();
					for each(var style : XML in styles)
					{
						stylingObject[style.@id[0].toString()] = {tf: xmlToTextFormat(style), backgroundColor:xmlToBGColor(style) , showBGColor: shouldShowBGColor(style)};	
					}
					
					var div:XML = body.xmlns::div[0];
					
					var p:XMLList = div.xmlns::p;
					var numOfLines:int = p.length ();
					_currentCCFile = new Array ();
					var tempCCLines : Array = new Array();
					for (var i:int = 0; i < numOfLines; i++)
					{
						var resultElem:XML = p [i];
						var currLine:CCLine = new CCLine ();
						 
						currLine.start = parseStrTTTime (resultElem.attribute ("begin") [0].toString ());
						if (resultElem.attribute ("end").length())
						{
							currLine.end = parseStrTTTime (resultElem.attribute ("end") [0].toString ());
						}
						else if (resultElem.attribute ("dur").length())
						{
							currLine.end = currLine.start + parseStrTTTime (resultElem.attribute ("dur") [0].toString ());
						}
						currLine.text = resultElem.text().toXMLString();
						if (resultElem.attribute("style").length() )
						{
							currLine.textFormat = stylingObject[resultElem.attribute ("style") [0].toString ()]["tf"];
							currLine.backgroundColor = stylingObject[resultElem.attribute ("style") [0].toString ()]["backgroundColor"];
							currLine.showBGColor = stylingObject[resultElem.attribute ("style") [0].toString ()]["showBGColor"];
						}
						else
						{
							currLine.textFormat = new TextFormat (defaultFontFamily, defaultFontSize, defaultFontColor, null, null, null, null, null, "center");
							currLine.showBGColor = false;
						}
						
						
						tempCCLines.push (currLine);
					}
					
					_availableCCArray[fileUrl] = new Array().concat(tempCCLines);
					_currentCCFile = _currentCCFile.concat( tempCCLines );
					
					
				} catch ( err:Error ) {
					
					this.dispatchEvent( new ErrorEvent (ERROR_PARSING_TT) );
				}
			}
		
		}
		
		private function xmlToTextFormat (style : XML) : TextFormat
		{
			var tf : TextFormat = new TextFormat();
			
			tf.align = style.@xmlns_tts::textAlign.length() ? style.@xmlns_tts::textAlign[0].toString() : "center";
			tf.bold = (style.@xmlns_tts::fontStyle.length() && style.@xmlns_tts::fontStyle[0].toString() == "bold") ? true : false;
			var colorString : String;
			if (style.@xmlns_tts::color.length())
			{
				colorString = style.@xmlns_tts::color[0].toString().replace("#", "0x");
			}
			else
			{
				colorString = "0xFFFFFF";
			}
			tf.color = Number(colorString);
			tf.font = style.@xmlns_tts::fontFamily.length() ? style.@xmlns_tts::fontFamily[0].toString() : defaultFontFamily;
			tf.size = style.@xmlns_tts::fontSize.length() ? style.@xmlns_tts::fontSize[0].toString() : defaultFontSize;
			
			return tf;	
		
		}
		
		private function xmlToBGColor(style : XML) : Number
		{
			var bgColor : Number = style.@xmlns_tts::backgroundColor.length() ? Number(style.@xmlns_tts::backgroundColor[0].toString().replace("#", "0x")) : 0x000000;
			return bgColor;
			
		}
		
		private function shouldShowBGColor (style : XML) : Boolean
		{
			var shouldShowBGColor : Boolean = style.@xmlns_tts::backgroundColor.length() ? true : false;
			return shouldShowBGColor;
		}

		private function onError(event:Event):void
		{
			this.dispatchEvent( event.clone() );
		}

		public function updatePlayhead (pos:Number):void
		{
			if (_currentCCFile && _currentCCFile.length)
			{
				var lastLine : CCLine = _currentCCFile[_currentCCFile.length -1];
			}
			if (lastLine && pos && pos > lastLine.start && pos > lastLine.end)
			{
				setText("");
				return;
			}
			for (var i:int = 0; i < _currentCCFile.length; i++)
			{
				var line:CCLine = _currentCCFile [i];

				if (pos <= line.end)
				{
					if (pos >= line.start)
					{
						setText (line.text, line.textFormat, line.backgroundColor, line.showBGColor);
					}
					else
					{
						setText ("");
					}
					
					break;
				}
			}
		}

		private function parseStrTTTime (timeStr:String):Number
		{
			var time : Number = 0;
			if (timeStr.indexOf("s") != -1)
			{
				time = Number(timeStr.replace("s", ""));
			}
			else
			{
				var timeArr : Array = timeStr.split(":");
				timeArr.reverse();
				for (var i:int = 0; i < timeArr.length; i++)
				{
					time += Number(timeArr[i]) * Math.pow(60,i);
				}
			}
			return time;
		}
		
		private function parseStrSRTTime (timeStr:String):Number
		{
			var hour:Number = parseInt (timeStr.substr(0, 2), 10);
			var minute:Number = parseInt (timeStr.substr(3, 2), 10);
			var second:Number = parseInt (timeStr.substr(6, 2), 10);
			var milli:Number = parseInt (timeStr.substr(9, 3), 10);
			
			return hour * 3600 + minute * 60 + second + milli / 1000;
		}
		
		public function setBitmapFilter(glowColor : Number, glowBlur : int):void {
			var color:Number = glowColor;
			var alpha:Number = 0.8;
			var blurX:Number = glowBlur;
			var blurY:Number = glowBlur;
			var strength:Number = 2;
			var inner:Boolean = false;
			var knockout:Boolean = false;
			var quality:Number = BitmapFilterQuality.LOW;
			
			defaultGlowFilter =  new GlowFilter(color,
				alpha,
				blurX,
				blurY,
				strength,
				quality,
				inner,
				knockout);
		}

		
		
		public function setText (text:String, textFormat : TextFormat = null, bgColor:Number=0 , showBGColor : Boolean = true):void
		{
			var tf : TextFormat;
			if (textFormat)
			{
				tf = new TextFormat(textFormat.font, textFormat.size, textFormat.color, textFormat.bold, textFormat.italic, textFormat.underline, textFormat.url, textFormat.target, textFormat.align, textFormat.leftMargin, textFormat.rightMargin, textFormat.indent, textFormat.leading);
			}
			else
			{
				tf = new TextFormat(defaultFontFamily, defaultFontSize, defaultFontColor, null, null, null, null, null, "center");
			}
			if (_label.htmlText == text)
			{
				return;
			}

			if (text != null)
			{
				_label.htmlText = text;
			}
			
			if (isInFullScreen)
			{
				tf.size = Number(tf.size)*fullScreenRatio;
			}

			_label.setTextFormat( tf );
			
			if (text != "")
			{
				if (defaultGlowFilter && !showBGColor)
				{
					_label.filters = [defaultGlowFilter];
					_label.background = false;
				}
				else
				{
					_label.filters = [];
					_label.background = true;
					_label.backgroundColor = bgColor;
				}
			}
			else
			{
				_label.background = false;
			}

			_label.width = _label.textWidth + WIDTH_MARGIN;
			_label.height = _label.textHeight + HEIGHT_MARGIN;
			_label.x = (this.width - _label.width)/2;

//			_label.autoSize = TextFieldAutoSize.CENTER;
			_label.y = 0;
		}

		public function get currentCCFile():Array
		{
			return _currentCCFile;
		}

		public function set currentCCFile(value:Array):void
		{
			_currentCCFile = value;
		}
		
		public function resetAll () : void
		{
			_availableCCArray = new Array();
			_currentCCFile = new Array ();
			setText("");
		}

		
	

	}
}