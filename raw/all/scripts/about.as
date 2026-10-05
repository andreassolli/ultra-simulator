package
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol19")]
   public class about extends MovieClip
   {
      
      public var btn_close:SimpleButton;
      
      private var m:MovieClip;
      
      public function about(param1:MovieClip)
      {
         super();
         this.m = param1;
         param1.addChild(this);
         param1.CenterWindow(this);
         this.btn_close.addEventListener(MouseEvent.CLICK,this.onClick,false,0,true);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         this.m._activeAbout = null;
         MovieClip(parent).removeChild(this);
      }
   }
}

