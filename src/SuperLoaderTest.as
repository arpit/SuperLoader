package {
	import com.arpitonline.superLoader.SuperLoader;
	import com.arpitonline.superLoader.SuperLoaderEvent;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;

	public class SuperLoaderTest extends Sprite
	{
		private var JPEG_URL:String = "http://media.smashingmagazine.com/cdn_smash/wp-content/uploads/2009/12/daily-monster.jpg";
		private var PNG_URL:String = "http://edgeofthewest.files.wordpress.com/2007/12/calvin.png"
		private var GIF_URL:String = "http://www.supershareware.com/images/icons/AZ_Paint___Animated_GIF_Editor-38389.gif"
		
		public function SuperLoaderTest()
		{
			stage.scaleMode = "noScale";
			stage.align = "TL";
			
			var sl:SuperLoader = new SuperLoader();
			sl.addEventListener(SuperLoaderEvent.IMAGE_TYPE_IDENTIFIED, function(event:SuperLoaderEvent):void{
				trace(sl.imageType);
			});
			sl.addEventListener(SuperLoaderEvent.IMAGE_SIZE_IDENTIFIED, function(event:SuperLoaderEvent):void{
				trace(sl.imageWidth, sl.imageHeight);
			});
			sl.addEventListener(Event.COMPLETE, function(event:Event):void{
				var loader:Loader = new Loader();
				loader.loadBytes(sl.imageByteArray);
				addChild(loader);
			});
			sl.load(GIF_URL);
		}
		
	}
}
