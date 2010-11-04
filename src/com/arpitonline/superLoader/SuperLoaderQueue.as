package com.arpitonline.superLoader
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;

	public class SuperLoaderQueue
	{
		private var _configFunction:Function;
		private var superloader:SuperLoader;
		private var filterFunction:Function;	
		private var callbackFunction:Function;
		
		private var imageLoadIndex:int;
		private var possibleImagesURLs:Vector.<String>;
		
		private var items:Vector.<Loader>;
		
		
		public static const RETURN_ON_FIRST_SUCCESSFUL_IMAGE:Function = function(items:Vector.<Loader>):Boolean{
			if(items.length ==1){
				return false;
			}
			return true;
		}
			
		public function SuperLoaderQueue(configFunction:Function){
			_configFunction = configFunction;
		}
		
		
		public function load(imageURLs:Vector.<String>, filterFunction:Function, callbackFunction:Function):void{
			
			imageLoadIndex = -1;
			items = new Vector.<Loader>();
			this.possibleImagesURLs = imageURLs;
			this.filterFunction = filterFunction;
			this.callbackFunction = callbackFunction;
			
			superloader = new SuperLoader();
			superloader.addEventListener(SuperLoaderEvent.IMAGE_TYPE_IDENTIFIED, onImageTypeIdentified);
			superloader.addEventListener(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED, onImageSizeIdentified);
			superloader.addEventListener(IOErrorEvent.IO_ERROR, onImageIOError);
			
			loadNext();
			
		}
		
		private function onImageTypeIdentified(event:SuperLoaderEvent):void{
			if(event.imageType == ImageType.UNKNOWN){
				superloader.abort();
				loadNext();
			}
		}
		
		private function onImageIOError(event:IOErrorEvent):void{
			superloader.abort();
			loadNext();
		}
		
		private function loadNext():void{
			superloader.abort();
			imageLoadIndex++;
			if(imageLoadIndex == possibleImagesURLs.length){
				callbackFunction(items);
				return;
			}
			superloader.load(possibleImagesURLs[imageLoadIndex]);
		}
		
		private function onImageSizeIdentified(event:SuperLoaderEvent):void{
			var accept:Boolean = filterFunction(event);
			if(accept){
				superloader.addEventListener(SuperLoaderEvent.LOAD_COMPLETE, onLoadComplete);		
			}
			else{
				superloader.abort();
				loadNext();
			}
		}
		
		private var img:Loader;
		private function onLoadComplete(event:Event):void{
			img = new Loader();
			img.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageRendered);
			img.loadBytes(superloader.imageByteArray);
			
		}
		
		private function onImageRendered(event:Event):void{
			img.contentLoaderInfo.removeEventListener(Event.COMPLETE,onImageRendered);
			items.push(img);
			img = null;
			if(this._configFunction(items) && this.imageLoadIndex < (possibleImagesURLs.length-1)){
				loadNext();
			}
			else{
				callbackFunction(items);
			}
		}
	}
}