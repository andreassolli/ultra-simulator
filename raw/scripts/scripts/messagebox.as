package
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol108")]
   public class messagebox extends MovieClip
   {
      
      public var bg:MovieClip;
      
      public var btn:SimpleButton;
      
      public var content:TextField;
      
      private const BT_BG_TXT:Number = 47.5;
      
      private var m:MovieClip;
      
      public function messagebox(param1:MovieClip, param2:String)
      {
         super();
         this.m = param1;
         this.content.text = "";
         this.content.htmlText = param2;
         this.content.height = this.content.textHeight + 12;
         this.bg.height = this.content.height + this.BT_BG_TXT;
         this.btn.addEventListener(MouseEvent.CLICK,this.onClose,false,0,true);
         var _loc3_:* = param1.addChild(this);
         param1.CenterWindow(_loc3_);
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         this.m._activeAbout = null;
         this.m.removeChild(this);
      }
   }
}

