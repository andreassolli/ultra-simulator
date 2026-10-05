package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol28")]
   public class setbtn extends MovieClip
   {
      
      public var id:TextField;
      
      public function setbtn(param1:String)
      {
         super();
         this.id.text = param1;
         this.id.mouseEnabled = false;
         this.addEventListener(MouseEvent.CLICK,this.onClick,false,0,true);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         MovieClip(parent).setActive(Number(this.id.text));
      }
   }
}

