package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol194")]
   public class emotecomponent extends MovieClip
   {
      
      public var label:TextField;
      
      public var pause_mc:MovieClip;
      
      public var play_mc:MovieClip;
      
      public function emotecomponent(param1:String)
      {
         super();
         this.label.text = param1;
         this.label.mouseEnabled = false;
         this.play_mc.visible = true;
         this.pause_mc.visible = false;
         this.addEventListener(MouseEvent.CLICK,this.onEmote,false,0,true);
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
      
      private function onEmote(param1:MouseEvent) : void
      {
         switch(MovieClip(parent).ActiveGame)
         {
            case "AQWorlds":
               MovieClip(parent).ActiveAvatar.pMC.mcChar.gotoAndPlay(this.label.text);
               break;
            case "EpicDuel":
               MovieClip(parent).ActiveAvatar.gotoAndPlay(this.label.text);
         }
      }
   }
}

