package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.geom.ColorTransform;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol54")]
   public class savedcolor extends MovieClip
   {
      
      public var color:MovieClip;
      
      private var _color:uint;
      
      public function savedcolor(param1:uint)
      {
         super();
         this._color = param1;
         var _loc2_:Object = new Object();
         _loc2_.red = param1 >> 16 & 0xFF;
         _loc2_.green = param1 >> 8 & 0xFF;
         _loc2_.blue = param1 & 0xFF;
         this.color.transform.colorTransform = new ColorTransform(1,1,1,1,_loc2_.red,_loc2_.green,_loc2_.blue,0);
         this.color.addEventListener(MouseEvent.CLICK,this.onColorClick,false,0,true);
      }
      
      private function onColorClick(param1:MouseEvent) : void
      {
         MovieClip(parent).UpdateSelectedColor(this._color,true);
      }
   }
}

