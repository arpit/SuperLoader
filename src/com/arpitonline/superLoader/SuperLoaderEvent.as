package com.arpitonline.superLoader
{
	import flash.events.Event;

	public class SuperLoaderEvent extends Event
	{
		public static const IMAGE_TYPE_IDENTIFIED:String = "imageTypeIdentified";
		public static const IMAGE_SIZE_IDENTIFIED:String = "imageSizeIdentified";
		
		public function SuperLoaderEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}