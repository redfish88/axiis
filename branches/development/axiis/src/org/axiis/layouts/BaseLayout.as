package org.axiis.layouts
{
	import com.degrafa.geometry.Geometry;
	
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import mx.events.PropertyChangeEvent;
	
	import org.axiis.core.AbstractLayout;
	import org.axiis.core.AxiisSprite;
	import org.axiis.core.ILayout;
	import org.axiis.core.PropertySetter;
	
	[Event(name="invalidate", type="org.axiis.LayoutEvent")]
	[Event(name="preRender", type="flash.events.Event")]
	[Event(name="itemPreDraw", type="flash.events.Event")]
	public class BaseLayout extends AbstractLayout
	{
		
		public function BaseLayout()
		{
			super();
		}
		
		private var activeStates:Array = [];

		[Bindable(event="scaleFillChange")]
		/**
		 * Set to TRUE - this will use a common bounds to fill all layout items being drawn
		 * Set to FALSE - each layout item will have its own fill bounds 
		 */
		public function set scaleFill(value:Boolean):void
		{
			if(value != _scaleFill)
			{
				_scaleFill = value;
				this.invalidate();
				dispatchEvent(new Event("scaleFillChange"));
			}
		}
	
		public function get scaleFill():Boolean
		{
			return _scaleFill;
		}
		private var _scaleFill:Boolean;
		
		/**
		 * Set to TRUE - drawing geometries will have their intial bounds set to 
		 * that of the currentReference of the PARENT LAYOUT.  This directly positions child
		 * drawing sprites on x/y according to currentReference x/y of parent layout.
		 * 
		 * Set to FALSE - sprite gets the x/y of the current Layout
		 */
		public var inheritParentBounds:Boolean = true;
		
		var t:Number;
	
		override public function render(newSprite:AxiisSprite = null):void 
		{
			if (!visible)
				return;
			
			t=flash.utils.getTimer();
			
			trimChildSprites();
			
			dispatchEvent(new Event("preRender"));
			
			if(newSprite)
				this.sprite = newSprite;
			//sprite.visible = false;
			_rendering = true;
			
				
			if(!sprite || !_referenceGeometryRepeater)
				return;			
			
			if (inheritParentBounds && parentLayout)
			{
				bounds = new Rectangle(parentLayout.currentReference.x + (isNaN(x) ? 0 : x),
									parentLayout.currentReference.y + (isNaN(y) ? 0 : y),
									parentLayout.currentReference.width,
									parentLayout.currentReference.height);
			}
			else
			{
				bounds = new Rectangle((isNaN(x) ? 0:x),(isNaN(y) ? 0:y),width,height);
			}
			sprite.x = isNaN(_bounds.x) ? 0 :_bounds.x;
			sprite.y = isNaN(_bounds.y) ? 0 :_bounds.y;
			
			_referenceGeometryRepeater.dataProvider=_dataItems;
			if (_dataItems)
				_itemCount = _dataItems.length;
			
			if (_dataItems && _dataItems.length > 0 )
			{
				_currentIndex = -1;
				
				if(parentLayout == null)
				{
					clearSetterArrays();
				}
				/* originalPropertySetters = [];
				currentPropertySetters = [];
				propertySettersArrays = []; */
				addModificationListeners();
				
				_referenceGeometryRepeater.repeat(preIteration, postIteration, repeatComplete);
			}
		}
		
		protected function clearSetterArrays():void
		{
			propertySettersArrays = [];
			currentPropertySetters = [];
			originalPropertySetters = [];
			
			for each(var layout:BaseLayout in layouts)
			{
				layout.clearSetterArrays();
			}
		}
		
		public function addModificationListeners():void
		{
			for each(var geometry:Geometry in drawingGeometries)
			{
				geometry.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,handleGeometryPropertyChange);
			}
		}
		
		public function removeModificationListeners():void
		{
			for each(var geometry:Geometry in drawingGeometries)
			{
				geometry.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE,handleGeometryPropertyChange);
			}
		}
		
		protected function handleGeometryPropertyChange(event:PropertyChangeEvent):void
		{
			if (currentIndex==itemCount-1 && this.referenceRepeater.iterationLoopComplete) {
					currentPropertySetters=this.propertySettersArrays[0]; //Grab the first one
				//	trace("setting iteration 0 " + event.property + "=" + event.newValue);
			}
			
			if(!hasModificationForProperty(originalPropertySetters,event.source,event.property))
			{
				var oldPropertySetter:PropertySetter = new PropertySetter(event.source,event.property,event.oldValue);
				originalPropertySetters.push(oldPropertySetter);
				var i:int = 0;
				for each(var arr:Array in propertySettersArrays)
				{
					arr.push(oldPropertySetter.clone());
					i++
				}
			}
			
			/* if(referenceRepeater.currentIteration == -1)
				return; */
			
			var found:Boolean = false;
			for each(var propertySetter:PropertySetter in currentPropertySetters)
			{
				if(propertySetter.target == event.source && propertySetter.property == event.property)
				{
					
					propertySetter.value = event.newValue;
					found = true
					
					
				//	trace(name,"U",referenceRepeater.currentIteration,propertySetter.target,propertySetter.property,propertySetter.value)
				}
			}
			if(!found)
			{
				
				var newPropertySetter:PropertySetter = new PropertySetter(event.source,event.property,event.newValue);
				currentPropertySetters.push(newPropertySetter);
			//	trace(name,"N",referenceRepeater.currentIteration,oldPropertySetter.target,oldPropertySetter.property,oldPropertySetter.value)
			}
		}
		
		protected function hasModificationForProperty(propertySetters:Array,target:Object,property:Object):Boolean
		{
			for each(var propertySetter:PropertySetter in propertySetters)
			{
				if(propertySetter.target == target && propertySetter.property == property)
					return true;
			}
			return false;
		}
		
		private var propertySettersArrays:Array = [];
		
		private var currentPropertySetters:Array = [];
		
		private var originalPropertySetters:Array = [];
		
		private function clonePropertySetterArray(arr:Array):Array
		{
			var toReturn:Array = [];
			for each(var propertySetter:PropertySetter in arr)
			{
				toReturn.push(propertySetter.clone());
			}
			return toReturn;
		}
		
		protected function preIteration():void
		{
			currentPropertySetters = clonePropertySetterArray(currentPropertySetters);
			
			_currentIndex = referenceRepeater.currentIteration;
			_currentDatum = dataItems[_currentIndex];
			if (dataField)
				_currentValue = getProperty(_currentDatum,dataField);
			else
				_currentValue=_currentDatum;
			if (labelField)
				_currentLabel = getProperty(_currentDatum,labelField).toString();
		}

		protected function postIteration():void
		{ 
			_currentReference = referenceRepeater.geometry;
			
			// Add a new Sprite if there isn't one available on the display list.
			if(_currentIndex > sprite.drawingSprites.length - 1)
			{
				var newChildSprite:AxiisSprite = createChildSprite(this);				
				sprite.addDrawingSprite(newChildSprite);
				childSprites.push(newChildSprite);
			}
			var currentChild:AxiisSprite = AxiisSprite(sprite.drawingSprites[currentIndex]);
			currentChild.data = currentDatum;
			
			dispatchEvent(new Event("itemPreDraw"));
			
			propertySettersArrays.push(currentPropertySetters);
			
			currentChild.bounds = bounds;
			currentChild.scaleFill = scaleFill;
			currentChild.geometries = drawingGeometries;
			currentChild.states = states;
			currentChild.revertingModifications = [];
			currentChild.render();
			
			var i:int=0;
			for each(var layout:ILayout in layouts)
			{
				// When we have multiple peer layouts the AxiisSprite needs to
				// differentiate between child drawing sprites and child layout sprites
				layout.parentLayout = this as ILayout;
				if (currentChild.layoutSprites.length-1 < i)
				{
					var ns:AxiisSprite = createChildSprite(this);
					currentChild.addLayoutSprite(ns);
				}
				layout.render(currentChild.layoutSprites[i]);
				i++;
			}
		}
		
		protected function repeatComplete():void
		{
			sprite.visible = visible;
			_rendering = false;
			
			removeModificationListeners();
			
			/* for(var a:int = 0; a < propertySettersArrays.length; a++)
			{
				AxiisSprite(sprite.drawingSprites[a]).revertingModifications = propertySettersArrays[a];
			} */
			
			if(parentLayout == null)
			{
				updateSpritePropertySetters();
			}
			
			trace("BaseLayout.render elapsed=" + (flash.utils.getTimer()-t) + "ms");
		}
		
		protected function updateSpritePropertySetters():void
		{
			for(var a:int = 0; a < propertySettersArrays.length; a++)
			{
				AxiisSprite(childSprites[a]).revertingModifications = propertySettersArrays[a];
			}
			
			for each(var layout:BaseLayout in layouts)
			{
				layout.updateSpritePropertySetters();
			}
		}
		
		private function createChildSprite(layout:ILayout):AxiisSprite
		{
			var newChildSprite:AxiisSprite = new AxiisSprite();
			newChildSprite.doubleClickEnabled=true;
			newChildSprite.layout = layout;
			return newChildSprite;
		}

		private function trimChildSprites():void
		{
			if (!sprite || _itemCount < 1)
				return;
			var trim:int = sprite.drawingSprites.length-_itemCount;
			for (var i:int=0; i <trim;i++)
			{
				var s:AxiisSprite = AxiisSprite(sprite.removeChild(sprite.drawingSprites[sprite.drawingSprites.length-1]));
				s.dispose();
			}
		}
		
		private function getProperty(obj:Object, propertyName:String):Object
		{
			if(obj == null)
				return null;
				
			var chain:Array=propertyName.split(".");
			if (chain.length < 2)
				return obj[chain[0]];
			else
				return getProperty(obj[chain[0]],chain.slice(1,chain.length).join("."));
		}
		
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
			if(sprite)
				sprite.visible = visible;
		}
	}
}