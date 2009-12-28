package com.arpitonline.superLoader
{
	import flash.errors.EOFError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	/**
	 * Dispatched when the type of the image is identified.
	 */ 
	[Event(name="imageTypeIdentified", type="com.arpitonline.superLoader.SuperLoaderEvent")]
	
	/**
	 * Dispatched when the size of the image is identified.
	 */ 
	[Event(name="imageSizeIdentified", type="com.arpitonline.superLoader.SuperLoaderEvent")]
	
	/**
	 * Dispatched when load is complete.
	 */ 
	[Event(name="loadComplete", type="com.arpitonline.superLoader.SuperLoaderEvent")]
	
	public class SuperLoader extends EventDispatcher{
		
		private var _stream:URLStream;
		private var _request:URLRequest;
		private var _imageWidth:Number;
		private var _imageHeight:Number;
		private var data:ByteArray;
		
		
		/**
	 	* Constructor
	 	*/ 
		public function SuperLoader(){
			_stream = new URLStream();
			_stream.addEventListener(ProgressEvent.PROGRESS, onStreamProgress);
			_stream.addEventListener(Event.COMPLETE, onLoadComplete);
			_stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		}
		
		public function load(fileURL:String):void{
			var request:URLRequest = new URLRequest(fileURL);
			data  = new ByteArray();
			loadRequest(request);
		}
		
		
		public function loadRequest(urlRequest:URLRequest):void{
			_imageWidth = _imageHeight = NaN;
			_request = urlRequest;
			_stream.load(_request);
			
		}
		
		protected var parseFunction:Function;
		
		protected function onStreamProgress(event:ProgressEvent):void{
			_stream.readBytes(data, data.length);
			
			if(!_imageType){
				checkImageType();
				parseFunction();
			}
			else{
				if(parseFunction != null){
					this.addEventListener(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED, function(event:Event):void{
						parseFunction = null;
						removeEventListener(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED, arguments.callee);
					});
					parseFunction();
			 	}
			}
		}
		
		private var _imageType:String;
		
		private function checkImageType():void{
			var byte:uint;
			try{
				byte = data.readUnsignedByte();
			}catch(error:EOFError){
				// this error may happen if the image is being loaded from 
				// an untrusted domain or not enough bytes have loaded in
				return;
			}
			switch(byte){
				case 255:	_imageType = ImageType.JPEG;
							parseFunction = parseAsJPEG;
							break;
				case 137: 	_imageType = ImageType.PNG;
							parseFunction = parseAsPNG;
							break;
				case 71:	_imageType = ImageType.GIF;
							parseFunction = parseAsGIF;
							break;
				default:	_imageType = ImageType.UNKNOWN
							break;
			}
			
			var evt:SuperLoaderEvent = new SuperLoaderEvent(SuperLoaderEvent.IMAGE_TYPE_IDENTIFIED);
			evt.url = _request.url;
			evt.imageType = _imageType;
			dispatchEvent(evt);
			
			return;
		}
		
		
			
		protected function parseAsJPEG():void{
			var format:Number;
			var marker:Number;
			var start:Number;
			
			try{
				data.endian = Endian.BIG_ENDIAN;
				data.position = 3;
				format = data.readUnsignedByte();					
		
				while( marker != 0xC0 && marker != 0xC1 && marker != 0xC2 && marker != 0xC3 ){
					start = data.readUnsignedShort() - 1;
					data.position = data.position + start;
					marker = data.readUnsignedByte();							
				}											
				
				data.position = data.position + 3;
				_imageHeight = data.readUnsignedShort();
				_imageWidth = data.readUnsignedShort();
				
				var evt:SuperLoaderEvent = new SuperLoaderEvent(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED);
				evt.url = _request.url;
				evt.imageType = _imageType;
				evt.imageWidth = _imageWidth;
				evt.imageHeight = _imageHeight;
				dispatchEvent(evt);
				
				parseFunction = null;
				
			}catch(e:EOFError){
				trace("[Error]")
			}
		}
		
		protected function parseAsPNG():void{
			try{
				data.position = 16;							
				_imageWidth = data.readUnsignedInt();
				_imageHeight = data.readUnsignedInt();
				
				var evt:SuperLoaderEvent = new SuperLoaderEvent(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED);
				evt.url = _request.url;
				evt.imageType = _imageType;
				evt.imageWidth = _imageWidth;
				evt.imageHeight = _imageHeight;
				dispatchEvent(evt);
				
				parseFunction = null;
				
			}catch(e:Error){
				trace("[Error]")
			}
		}
		
		protected function parseAsGIF():void{
			try{
				data.position = 6;
				data.endian = Endian.LITTLE_ENDIAN;
				_imageWidth = data.readUnsignedShort();
				_imageHeight = data.readUnsignedShort();
				
				var evt:SuperLoaderEvent = new SuperLoaderEvent(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED);
				evt.url = _request.url;
				evt.imageType = _imageType;
				evt.imageWidth = _imageWidth;
				evt.imageHeight = _imageHeight;
				dispatchEvent(evt);
				
				parseFunction = null;
				
			}catch(e:Error){
				trace("[Error]")
			}
		}
		
		protected function onLoadComplete(event:Event):void{
			var evt:SuperLoaderEvent = new SuperLoaderEvent(SuperLoaderEvent.LOAD_COMPLETE);
			evt.url = _request.url;
			evt.imageType = _imageType;
			evt.imageWidth = _imageWidth;
			evt.imageHeight = _imageHeight;
			dispatchEvent(evt);
		}
		
		protected function onSecurityError(event:Event):void{
			dispatchEvent(event);
		}
		
		public function get imageType():String{
			return _imageType;
		}
		
		public function get imageWidth():Number{
			return _imageWidth;
		}
		
		public function get imageHeight():Number{
			return _imageHeight;
		}
		
		public function get imageByteArray():ByteArray{
			return data;
		}
		
		public function abort():void{
			_stream.close();
		}
	}
}