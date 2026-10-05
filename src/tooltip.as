package
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol23")]
   public class tooltip extends MovieClip
   {
      
      public var bg:MovieClip;
      
      public var tip:TextField;
      
      private const TIP_START_X:Number = 15.4;
      
      private const TIP_START_Y:Number = 8;
      
      private var Ancestor:MovieClip;
      
      private var mc:*;
      
      public function tooltip(param1:String, param2:*, param3:MovieClip)
      {
         super();
         this.Ancestor = param3;
         this.mc = param2;
         this.tip.text = param1;
         this.tip.width = this.tip.textWidth + 7;
         this.bg.width = this.TIP_START_X + this.tip.textWidth + 25;
         this.x = this.Ancestor.mouseX + 5;
         this.y = this.Ancestor.mouseY + 20;
         this.addEventListener(Event.ENTER_FRAME,this.onFrame,false,0,true);
         param3.addChild(this);
      }
      
      private function onFrame(param1:Event) : void
      {
         if(!this.mc.hitTestPoint(this.Ancestor.mouseX,this.Ancestor.mouseY))
         {
            this.removeEventListener(Event.ENTER_FRAME,this.onFrame);
            try
            {
               this.Ancestor.removeChild(this);
            }
            catch(e:*)
            {
            }
         }
         else
         {
            this.x = this.Ancestor.mouseX + 5;
            this.y = this.Ancestor.mouseY + 20;
         }
      }
   }
}

