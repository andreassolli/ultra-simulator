package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2429")]
   public class buttoncomponent extends MovieClip
   {
      
      public var label:TextField;
      
      public var pause_mc:MovieClip;
      
      public var play_mc:MovieClip;
      
      public function buttoncomponent(param1:String)
      {
         super();
         this.label.text = param1;
         this.play_mc.visible = true;
         this.pause_mc.visible = false;
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
         var _loc2_:* = undefined;
         switch(MovieClip(parent).ActiveGame)
         {
            case "AQWorlds":
               _loc2_ = MovieClip(parent).ActiveAvatar.pMC;
               break;
            case "EpicDuel":
               _loc2_ = MovieClip(parent).ActiveAvatar;
         }
         switch(this.label.text)
         {
            case "Combat Animations":
               _loc2_.handleAttack();
               break;
            case "PetBuff":
            case "PetAttack1":
            case "PetAttack2":
               if(_loc2_.pAV.petMC.mcChar == null)
               {
                  return;
               }
               _loc2_.pAV.petMC.mcChar.gotoAndPlay(this.label.text.split("Pet")[1]);
               break;
            case "on":
               _loc2_.onWeapons();
               break;
            case "off":
               _loc2_.offWeapons();
         }
      }
   }
}

