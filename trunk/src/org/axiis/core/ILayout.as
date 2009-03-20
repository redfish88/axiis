package org.axiis.core
{
	import com.degrafa.geometry.Geometry;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;
	
	public interface ILayout extends IEventDispatcher
	{
		function set parentLayout(value:ILayout):void;
		function get parentLayout():ILayout;
		
		function set bounds(value:Rectangle):void;
		function get bounds():Rectangle;
		
		function set dataProvider(value:Object):void;
		function get dataProvider():Object;
		
		function set dataField(value:String):void;
		function get dataField():String;
		
		function set geometries(value:Array):void;
		function get geometries():Array;
		
		function set fills(value:Array):void;
		function get fills():Array;
		
		function set strokes(value:Array):void;
		function get strokes():Array;
		
		function set layouts(value:Array):void;
		function get layouts():Array;
		
		function set x(value:Number):void;
		function get x():Number;
		
		function set y(value:Number):void;
		function get y():Number;
		
		function set width(value:Number):void;
		function get width():Number;
		
		function set height(value:Number):void;
		function get height():Number;
		
		//Do we really need this? not sure it is being used now.
		function set scale(value:String):void
		function get scale():String;
		
		function get currentIndex():int;
		
		function get currentItem():Sprite;
		
		function get currentDatum():Object
		
		function set selectedIndex(value:int):void;
		function get selectedIndex():int;
		
		function set selectedItem(value:Sprite):void;
		function get selectedItem():Sprite;
		
		function set selectedDatum(value:Object):void;
		function get selectedDatum():Object;
		
		function set referenceRepeater(value:IGeometryRepeater):void;
		function get referenceRepeater():IGeometryRepeater;
		
		function get currentReference():Geometry;
		
		function applyIteration(iteration:int,parentIteration:int=-1):void;
		
		/**
		 * Registers a DisplayObject as the owner of this ILayout.
		 * Throws an error if the ILayout already has an owner.
		 */
		function registerOwner(displayObject:DisplayObject):void;
		
		
		// hasOwner??
		
		/**
		 * Returns the Sprite associated with this ILayout if owner is
		 * in fact the owner of this ILayout.
		 * 
		 * This can be more secure if we look at the call stack to determine
		 * ownership.
		 */
		function getSprite(owner:DisplayObject):Sprite;
		
		function initialize():void;
		
		function measure():void;
		
		function render(sprite:Sprite = null,index:int=-1):void; 
	}
}