package
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2473")]
   public class sidebar extends MovieClip
   {
      
      public var background_content:backgrounds;
      
      public var bg:MovieClip;
      
      public var characters_content:characters;
      
      public var contentmask:MovieClip;
      
      public var emotes_content:emotes;
      
      public var sb:scroll;
      
      public var setswitcher:sets;
      
      public var switch_btn_separator:MovieClip;
      
      public var tabs:MovieClip;
      
      public var toggleSidebar:SimpleButton;
      
      public function sidebar()
      {
         super();
         this.toggleSidebar.addEventListener(MouseEvent.CLICK,MovieClip(parent).ToggleSidebar,false,0,true);
         this.setupTabs();
      }
      
      public function get ActiveTab() : MovieClip
      {
         var _loc2_:String = null;
         var _loc1_:Array = ["nav1","nav2","nav3"];
         for each(_loc2_ in _loc1_)
         {
            if(!MovieClip(this.tabs.getChildByName(_loc2_)).active.visible)
            {
               continue;
            }
            switch(_loc2_)
            {
               case "nav1":
                  return this.characters_content;
               case "nav2":
                  return this.emotes_content;
               case "nav3":
                  return this.background_content;
            }
         }
         return null;
      }
      
      private function setupTabs() : void
      {
         this.enableTab("nav1");
         this.disableTab("nav2");
         this.disableTab("nav3");
         this.tabs.nav1.addEventListener(MouseEvent.CLICK,this.onTabSwitch,false,0,true);
         this.tabs.nav2.addEventListener(MouseEvent.CLICK,this.onTabSwitch,false,0,true);
         this.tabs.nav3.addEventListener(MouseEvent.CLICK,this.onTabSwitch,false,0,true);
      }
      
      private function onTabSwitch(param1:MouseEvent) : void
      {
         this.disableTab("nav1");
         this.disableTab("nav2");
         this.disableTab("nav3");
         this.enableTab(param1.target.parent.name);
      }
      
      private function enableTab(param1:String) : void
      {
         MovieClip(this.tabs.getChildByName(param1)).active.visible = true;
         MovieClip(this.tabs.getChildByName(param1)).inactive.visible = false;
         switch(param1)
         {
            case "nav1":
               this.characters_content.visible = true;
               break;
            case "nav2":
               this.emotes_content.visible = true;
               break;
            case "nav3":
               this.background_content.visible = true;
         }
      }
      
      private function disableTab(param1:String) : void
      {
         MovieClip(this.tabs.getChildByName(param1)).active.visible = false;
         MovieClip(this.tabs.getChildByName(param1)).inactive.visible = true;
         switch(param1)
         {
            case "nav1":
               this.characters_content.visible = false;
               break;
            case "nav2":
               this.emotes_content.visible = false;
               break;
            case "nav3":
               this.background_content.visible = false;
         }
      }
   }
}

