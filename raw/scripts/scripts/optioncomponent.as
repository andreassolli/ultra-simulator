package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol106")]
   public class optioncomponent extends MovieClip
   {
      
      public var label:TextField;
      
      public var toggle:MovieClip;
      
      public var active:Boolean;
      
      public function optioncomponent(param1:String, param2:Boolean)
      {
         super();
         this.label.text = param1;
         this.toggle.gotoAndStop(param2 ? "On" : "Off");
         this.active = param2;
         this.addEventListener(MouseEvent.CLICK,this.onToggle,false,0,true);
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
      
      private function onToggle(param1:MouseEvent) : void
      {
         var _loc2_:* = undefined;
         this.toggle.gotoAndPlay(this.toggle.currentLabel == "Off" ? "TurningOn" : "TurningOff");
         this.active = this.toggle.currentLabel == "TurningOn";
         if(MovieClip(parent) is backgrounds)
         {
            MovieClip(parent).scaleBG(this.active);
            return;
         }
         switch(MovieClip(parent).ActiveGame)
         {
            case "AQWorlds":
               _loc2_ = MovieClip(parent).ActiveAvatar.pMC;
               break;
            case "EpicDuel":
               _loc2_ = MovieClip(parent).ActiveAvatar;
         }
         var _loc3_:* = MovieClip(parent).ActiveSet;
         _loc3_["itemShow"][this.label.text] = this.active;
         _loc2_.handleVisibilities();
      }
   }
}

