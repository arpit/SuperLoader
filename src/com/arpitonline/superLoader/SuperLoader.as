package com.arpitonline.superLoader
{
	import flash.errors.EOFError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
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
	 * Constructor
	 */ 
	public class SuperLoader extends EventDispatcher{
		public function SuperLoader(){
		}
		
		private var _request:URLRequest;
		
		public function load(fileURL:String):void{
			var request:URLRequest = new URLRequest(fileURL);
			data  = new ByteArray();
			loadRequest(request);
		}
		
		
		private var _stream:URLStream;
		private var _imageWidth:Number;
		private var _imageHeight:Number;
		private var data:ByteArray;
		
		public function loadRequest(urlRequest:URLRequest):void{
			_request = urlRequest;
			_stream = new URLStream();
			_stream.addEventListener(ProgressEvent.PROGRESS, onStreamProgress);
			_stream.load(_request);
		}
		
		private var doRead:Boolean = true;
		
		private var parseFunction:Function;
		
		private function onStreamProgress(event:ProgressEvent):void{
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
							dispatchEvent(new SuperLoaderEvent(SuperLoaderEvent.IMAGE_TYPE_IDENTIFIED));
							break;
				case 137: 	_imageType = ImageType.PNG;
							parseFunction = parseAsPNG;
							dispatchEvent(new SuperLoaderEvent(SuperLoaderEvent.IMAGE_TYPE_IDENTIFIED));
							break;
				case 71:	_imageType = ImageType.GIF;
							parseFunction = parseAsGIF;
							dispatchEvent(new SuperLoaderEvent(SuperLoaderEvent.IMAGE_TYPE_IDENTIFIED));
							break;
				default:	_imageType = ImageType.UNKNOWN
							break;
			}
			return;
		}
		
		
			
		private function parseAsJPEG():void{
			var format:Number;
			var marker:Number;
			var start:Number;
			
			try{
				data.endian = Endian.BIG_ENDIAN;
				data.position = 3;
				format = data.readUnsignedByte();					
		
				while( marker != 0xC0 ){
					start = data.readUnsignedShort() - 1;
					data.position = data.position + start;
					marker = data.readUnsignedByte();							
				}											
				
				data.position = data.position + 3;
				_imageHeight = data.readUnsignedShort();
				_imageWidth = data.readUnsignedShort();
				dispatchEvent(new SuperLoaderEvent(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED));
			}catch(e:EOFError){
				trace("[Error]")
			}
		}
		
		private function parseAsPNG():void{
			try{
				data.position = 16;							
				_imageWidth = data.readUnsignedInt();
				_imageHeight = data.readUnsignedInt();
				dispatchEvent(new SuperLoaderEvent(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED));
			}catch(e:Error){
				trace("[Error]")
			}
		}
		
		private function parseAsGIF():void{
			try{
				data.position = 6;
				data.endian = Endian.LITTLE_ENDIAN;
				_imageWidth = data.readUnsignedShort();
				_imageHeight = data.readUnsignedShort();
				dispatchEvent(new SuperLoaderEvent(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED));
			}catch(e:Error){
				trace("[Error]")
			}
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
	}
}