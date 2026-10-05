package
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2197")]
   public class backgroundcomponent extends MovieClip
   {
      
      public var bmp:MovieClip;
      
      public var label:TextField;
      
      public function backgroundcomponent(param1:Object)
      {
         var _loc2_:Matrix = null;
         var _loc3_:BitmapData = null;
         var _loc4_:Bitmap = null;
         var _loc5_:* = undefined;
         super();
         this.label.text = param1.name;
         this.label.mouseEnabled = false;
         this.bmp.mouseEnabled = this.bmp.mouseChildren = false;
         if(param1.name != "None")
         {
            _loc2_ = new Matrix();
            _loc2_.translate(-param1.mc.width / 4,-param1.mc.height / 4);
            _loc3_ = new BitmapData(220,50,true,0);
            _loc3_.draw(param1.mc,_loc2_);
            _loc4_ = new Bitmap(_loc3_);
            while(this.bmp.numChildren > 0)
            {
               this.bmp.removeChildAt(0);
            }
            _loc5_ = this.bmp.addChild(_loc4_);
         }
         this.addEventListener(MouseEvent.CLICK,this.onClick,false,0,true);
         this.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
      }
      
      private function onOver(param1:MouseEvent) : void
      {
         Mouse.cursor = "button";
      }
      
      private function onOut(param1:MouseEvent) : void
      {
         Mouse.cursor = "arrow";
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         MovieClip(parent).SetBG(this.label.text);
      }
   }
}

