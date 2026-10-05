package
{
   import AQWorlds.AvatarMC;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol252")]
   public class colorcomponent extends MovieClip
   {
      
      public var color:MovieClip;
      
      public var input:TextField;
      
      public var type:TextField;
      
      private var _color:int;
      
      private var _type:String;
      
      private var defaults:Object = {
         "hairColors":["3E1F00","003333","FFFFFF","222F41","2B2B2B","29466D","5F3C2B","A21E2B"],
         "skinColors":["FFEDDC","FFCC99","FFB164","DF9061","9B5F3A","634128","3B241C"],
         "eyeColors":["66CCFF","663333","009966","A44040","333333"],
         "baseColors":["282532"],
         "trimColors":["FFFFFF"],
         "accessoryColors":["0FA75B"]
      };
      
      public function colorcomponent(param1:String, param2:int = -1)
      {
         super();
         this.type.text = param1;
         this._type = param1;
         this._color = param2;
         this.UpdatePreview();
         this.UpdateText();
         this.input.addEventListener(Event.CHANGE,this.onInputChanged,false,0,true);
         this.input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.color.addEventListener(MouseEvent.CLICK,this.onAdvColor,false,0,true);
         this.color.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.color.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.addEventListener(Event.ADDED_TO_STAGE,this.onStage,false,0,true);
      }
      
      private function onInputOver(param1:MouseEvent) : void
      {
         Mouse.cursor = "ibeam";
      }
      
      private function onOver(param1:MouseEvent) : void
      {
         Mouse.cursor = "button";
      }
      
      private function onOut(param1:MouseEvent) : void
      {
         Mouse.cursor = "arrow";
      }
      
      private function onStage(param1:Event) : void
      {
         var _loc2_:String = null;
         if(this._color != -1)
         {
            return;
         }
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onStage);
         switch(this._type)
         {
            case "Hair Color":
               _loc2_ = this.defaults["hairColors"][Math.floor(Math.random() * this.defaults["hairColors"].length)];
               break;
            case "Skin Color":
               _loc2_ = this.defaults["skinColors"][Math.floor(Math.random() * this.defaults["skinColors"].length)];
               break;
            case "Eye Color":
               _loc2_ = this.defaults["eyeColors"][Math.floor(Math.random() * this.defaults["eyeColors"].length)];
               break;
            case "Primary Color":
            case "Base Color":
               _loc2_ = this.defaults["baseColors"][0];
               break;
            case "Secondary Color":
            case "Trim Color":
               _loc2_ = this.defaults["trimColors"][0];
               break;
            case "Accent Color":
            case "Accent 2 Color":
            case "Accessory Color":
               _loc2_ = this.defaults["accessoryColors"][0];
         }
         this._color = parseInt("0x" + _loc2_,16);
         var _loc3_:Object = new Object();
         var _loc4_:String = this.type.text.split(" Color")[0];
         _loc3_["intColor" + _loc4_] = this._color;
         switch(MovieClip(parent).ActiveGame)
         {
            case "AQWorlds":
               (MovieClip(parent).ActiveAvatar.pMC as AvatarMC).updateColor(_loc3_);
               break;
            case "EpicDuel":
               MovieClip(parent).ActiveAvatar.setColors(_loc3_);
         }
         this.UpdatePreview();
         this.UpdateText();
         if(MovieClip(parent).ActiveSet["color_" + _loc4_] == null)
         {
            MovieClip(parent).ActiveSet["color_" + _loc4_] = {};
         }
         MovieClip(parent).ActiveSet["color_" + _loc4_].color = this._color;
      }
      
      public function get ColorType() : String
      {
         return this._type;
      }
      
      private function RemoveExistingAdvColor() : Point
      {
         var _loc3_:Point = null;
         var _loc1_:* = MovieClip(parent).Ancestor;
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.numChildren)
         {
            if(_loc1_.getChildAt(_loc2_) is advcolor)
            {
               _loc3_ = new Point(_loc1_.getChildAt(_loc2_).x,_loc1_.getChildAt(_loc2_).y);
               _loc1_.removeChild(_loc1_.getChildAt(_loc2_));
               return _loc3_;
            }
            _loc2_++;
         }
         return new Point(0,0);
      }
      
      private function onAdvColor(param1:MouseEvent) : void
      {
         if(MovieClip(parent).Ancestor.getChildByName("advcolor_" + this.type.text) != null)
         {
            MovieClip(parent).Ancestor.removeChild(MovieClip(parent).Ancestor.getChildByName("advcolor_" + this.type.text));
            return;
         }
         var _loc2_:Point = this.RemoveExistingAdvColor();
         var _loc3_:* = MovieClip(parent).Ancestor.addChild(new advcolor(MovieClip(parent).Ancestor,this.type.text,this,this._color));
         if(_loc2_.x != 0 && _loc2_.y != 0)
         {
            _loc3_.x = _loc2_.x;
            _loc3_.y = _loc2_.y;
         }
      }
      
      private function onInputChanged(param1:Event) : void
      {
         var _loc2_:String = this.input.text.charAt(0) == "#" ? this.input.text.substring(1) : this.input.text;
         this._color = parseInt("0x" + _loc2_,16);
         this.Update(false);
      }
      
      public function UpdateColor(param1:uint) : void
      {
         this._color = param1;
         this.Update();
      }
      
      private function Update(param1:Boolean = true) : void
      {
         var _loc2_:Object = new Object();
         var _loc3_:String = this.type.text.split(" Color")[0];
         _loc2_["intColor" + _loc3_] = this._color;
         switch(MovieClip(parent).ActiveGame)
         {
            case "AQWorlds":
               (MovieClip(parent).ActiveAvatar.pMC as AvatarMC).updateColor(_loc2_);
               break;
            case "EpicDuel":
               MovieClip(parent).ActiveAvatar.setColors(_loc2_);
         }
         this.UpdatePreview();
         if(param1)
         {
            this.UpdateText();
         }
         if(MovieClip(parent).ActiveSet["color_" + _loc3_] == null)
         {
            MovieClip(parent).ActiveSet["color_" + _loc3_] = {};
         }
         MovieClip(parent).ActiveSet["color_" + _loc3_].color = this._color;
      }
      
      private function UpdateText() : void
      {
         var _loc1_:String = Math.abs(this._color).toString(16);
         while(_loc1_.length < 6)
         {
            _loc1_ = "0" + _loc1_;
         }
         this.input.text = "#" + _loc1_.toUpperCase();
      }
      
      private function UpdatePreview() : void
      {
         var _loc1_:Object = new Object();
         _loc1_.red = this._color >> 16 & 0xFF;
         _loc1_.green = this._color >> 8 & 0xFF;
         _loc1_.blue = this._color & 0xFF;
         this.color.color.transform.colorTransform = new ColorTransform(1,1,1,1,_loc1_.red,_loc1_.green,_loc1_.blue,0);
      }
   }
}

