package
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol197")]
   public class context extends MovieClip
   {
      
      public var bg:MovieClip;
      
      public var items:Array;
      
      private const START_X:Number = 2.65;
      
      private const START_Y:Number = 3.55;
      
      private const BOTTOM_SPACING:Number = 30.2;
      
      private var m:MovieClip;
      
      private var hostComponent:*;
      
      public function context(param1:MovieClip, param2:Array, param3:Number = -1, param4:Number = -1, param5:Function = null)
      {
         var _loc8_:Object = null;
         var _loc9_:contextitem = null;
         var _loc10_:MovieClip = null;
         var _loc11_:contextdivider = null;
         this.items = [];
         super();
         this.m = param1;
         if(param2[0].label.indexOf("About ") != 0 && param2[0].label.indexOf("Window") != 0)
         {
            param2.push({
               "label":"Cancel",
               "func":param5
            });
         }
         var _loc6_:uint = 0;
         while(_loc6_ < param2.length)
         {
            _loc8_ = param2[_loc6_];
            if(_loc8_.label == "Cancel")
            {
               _loc11_ = new contextdivider();
               _loc11_.x = this.START_X;
               _loc11_.y = this.START_Y + (this.items.length > 0 ? this.items[this.items.length - 1].mc.y + this.items[this.items.length - 1].mc.height : 0);
               this.addChild(_loc11_);
            }
            _loc9_ = this.createItem(_loc8_.label,_loc8_.active ? Boolean(_loc8_.active) : false);
            _loc10_ = this.addChild(_loc9_) as MovieClip;
            _loc10_.x = this.START_X;
            _loc10_.y = this.START_Y + (this.items.length > 0 ? this.items[this.items.length - 1].mc.y + this.items[this.items.length - 1].mc.height : 0);
            this.items.push({
               "mc":_loc10_,
               "func":_loc8_.func
            });
            _loc6_++;
         }
         this.bg.height = this.items[this.items.length - 1].mc.y + this.BOTTOM_SPACING;
         var _loc7_:MovieClip = param1.addChild(this) as MovieClip;
         if(param3 == -1 && param4 == -1)
         {
            this.name = "contextMenu";
            _loc7_.x = param1.mouseX;
            _loc7_.y = param1.mouseY;
            param1.clearContextMenu();
            param1._activeContext = this;
         }
         else
         {
            this.name = "altMenu";
            _loc7_.x = param3 != -1 ? param3 : param1.mouseX;
            _loc7_.y = param4 != -1 ? param4 : param1.mouseY;
            param1.clearAltContextMenu();
            param1._activeAltContext = this;
            param1.stage.addEventListener(MouseEvent.CLICK,this.onStageClick,false,0,true);
         }
      }
      
      private function onStageClick(param1:MouseEvent) : void
      {
         if(this.hostComponent == null)
         {
            this.hostComponent = param1.target;
         }
         if(param1.target == this.hostComponent)
         {
            return;
         }
         this.m.stage.removeEventListener(MouseEvent.CLICK,this.onStageClick);
         this.m.clearAltContextMenu();
         this.hostComponent = null;
      }
      
      private function createItem(param1:String, param2:Boolean) : contextitem
      {
         var _loc3_:contextitem = new contextitem();
         _loc3_.mc.txt.mouseEnabled = false;
         _loc3_.mc.txt.text = param1;
         _loc3_.mc.active.mouseEnabled = false;
         _loc3_.mc.active.visible = param2;
         _loc3_.name = this.items.length.toString();
         _loc3_.addEventListener(MouseEvent.CLICK,this.onContextClicked,false,0,true);
         return _loc3_;
      }
      
      private function onContextClicked(param1:MouseEvent) : void
      {
         if(this.items[Number(param1.currentTarget.name)].func != null)
         {
            this.items[Number(param1.currentTarget.name)].func();
         }
         if(this.name == "altMenu")
         {
            this.m.clearAltContextMenu();
         }
         else
         {
            this.m.clearContextMenu();
         }
      }
   }
}

