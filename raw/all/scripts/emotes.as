package
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2431")]
   public class emotes extends MovieClip
   {
      
      private const START_X:Number = 5.65;
      
      private const START_Y:Number = 16.9;
      
      private const SPACER:Number = 45;
      
      private var items:Array = [];
      
      public function emotes()
      {
         super();
         this.SwitchGames();
      }
      
      private function buildAQWEmotes() : void
      {
         var _loc2_:* = undefined;
         var _loc3_:MovieClip = null;
         var _loc1_:Array = this.ActiveAvatar.pMC.mcChar.currentLabels;
         _loc1_.sortOn("name");
         for each(_loc2_ in _loc1_)
         {
            _loc3_ = new emotecomponent(_loc2_.name);
            _loc3_.x = this.START_X;
            _loc3_.y = this.START_Y + this.SPACER * this.items.length;
            addChild(_loc3_);
            this.items.push(_loc3_);
         }
      }
      
      private function buildEDEmotes() : void
      {
         var _loc2_:* = undefined;
         var _loc3_:MovieClip = null;
         var _loc1_:Array = this.ActiveAvatar.currentLabels;
         _loc1_.sortOn("name");
         for each(_loc2_ in _loc1_)
         {
            _loc3_ = new emotecomponent(_loc2_.name);
            _loc3_.x = this.START_X;
            _loc3_.y = this.START_Y + this.SPACER * this.items.length;
            addChild(_loc3_);
            this.items.push(_loc3_);
         }
      }
      
      public function get Ancestor() : MovieClip
      {
         return MovieClip(MovieClip(parent).parent);
      }
      
      public function get ActiveGame() : String
      {
         return this.Ancestor._activeGame;
      }
      
      public function get ActiveAvatar() : *
      {
         return MovieClip(parent).setswitcher.ActiveAvatar;
      }
      
      public function get ActiveSet() : *
      {
         return MovieClip(parent).setswitcher.ActiveSet;
      }
      
      public function SwitchGames() : void
      {
         while(numChildren > 0)
         {
            removeChildAt(0);
         }
         this.items = [];
         switch(MovieClip(parent).setswitcher.ActiveGame)
         {
            case "AQWorlds":
               this.buildAQWEmotes();
               break;
            case "EpicDuel":
               this.buildEDEmotes();
         }
      }
   }
}

