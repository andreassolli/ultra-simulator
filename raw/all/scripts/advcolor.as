package
{
   import flash.display.*;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.ui.Mouse;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol246")]
   public class advcolor extends MovieClip
   {
      
      public var b_dec:SimpleButton;
      
      public var b_inc:SimpleButton;
      
      public var b_input:TextField;
      
      public var bg:MovieClip;
      
      public var close_btn:SimpleButton;
      
      public var colorDisplay:MovieClip;
      
      public var cursor:MovieClip;
      
      public var g_dec:SimpleButton;
      
      public var g_inc:SimpleButton;
      
      public var g_input:TextField;
      
      public var h_dec:SimpleButton;
      
      public var h_inc:SimpleButton;
      
      public var h_input:TextField;
      
      public var hex_input:TextField;
      
      public var l_dec:SimpleButton;
      
      public var l_inc:SimpleButton;
      
      public var l_input:TextField;
      
      public var label:TextField;
      
      public var r_dec:SimpleButton;
      
      public var r_inc:SimpleButton;
      
      public var r_input:TextField;
      
      public var s_dec:SimpleButton;
      
      public var s_inc:SimpleButton;
      
      public var s_input:TextField;
      
      public var save_btn:SimpleButton;
      
      public var sldr_bounds:MovieClip;
      
      public var slider:MovieClip;
      
      private var _map_color:uint;
      
      private var _color:uint;
      
      private var _ancestor:MovieClip;
      
      private var _h_color:Number;
      
      private var _s_color:Number;
      
      private var _l_color:Number;
      
      private const MAP_X:Number = 20.05;
      
      private const MAP_Y:Number = 62.25;
      
      private const MAP_SIZE:Number = 234.15;
      
      private const SLDR_X:Number = 272.05;
      
      private const SLDR_Y:Number = 62.25;
      
      private const SLDR_WIDTH:Number = 21.9;
      
      private const SLDR_HEIGHT:Number = 234.15;
      
      private var saved_clrs:Array = [];
      
      private const CLR_START_X:Number = 50.8;
      
      private const CLR_START_Y:Number = 312.05;
      
      private const CLR_SPACING:Number = 30;
      
      private var map_bmp:BitmapData;
      
      private var sldr_bmp:BitmapData;
      
      private var map_mc:MovieClip;
      
      private var sldr_mc:MovieClip;
      
      private var component:MovieClip;
      
      public function advcolor(param1:MovieClip, param2:String, param3:MovieClip, param4:uint)
      {
         super();
         this.name = "advcolor_" + param2;
         this.component = param3;
         this.label.text = param2;
         this.label.mouseEnabled = false;
         this._map_color = param4;
         this.UpdateSelectedColor(this._map_color);
         this._ancestor = param1;
         this.map_mc = new MovieClip();
         addChild(this.map_mc);
         this.sldr_mc = new MovieClip();
         addChild(this.sldr_mc);
         this.createMap();
         this.createSlider();
         this.r_inc.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.r_inc.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.r_dec.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.r_dec.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.g_inc.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.g_inc.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.g_dec.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.g_dec.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.b_inc.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.b_inc.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.b_dec.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.b_dec.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.h_inc.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.h_inc.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.h_dec.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.h_dec.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.s_inc.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.s_inc.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.s_dec.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.s_dec.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.l_inc.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.l_inc.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.l_dec.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.l_dec.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.save_btn.addEventListener(MouseEvent.MOUSE_OVER,this.onOver,false,0,true);
         this.save_btn.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.r_input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.r_input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.g_input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.g_input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.b_input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.b_input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.h_input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.h_input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.s_input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.s_input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.l_input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.l_input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.hex_input.addEventListener(MouseEvent.MOUSE_OVER,this.onInputOver,false,0,true);
         this.hex_input.addEventListener(MouseEvent.MOUSE_OUT,this.onOut,false,0,true);
         this.r_inc.addEventListener(MouseEvent.CLICK,this.onIncrease,false,0,true);
         this.r_dec.addEventListener(MouseEvent.CLICK,this.onDecrease,false,0,true);
         this.g_inc.addEventListener(MouseEvent.CLICK,this.onIncrease,false,0,true);
         this.g_dec.addEventListener(MouseEvent.CLICK,this.onDecrease,false,0,true);
         this.b_inc.addEventListener(MouseEvent.CLICK,this.onIncrease,false,0,true);
         this.b_dec.addEventListener(MouseEvent.CLICK,this.onDecrease,false,0,true);
         this.h_inc.addEventListener(MouseEvent.CLICK,this.onIncrease,false,0,true);
         this.h_dec.addEventListener(MouseEvent.CLICK,this.onDecrease,false,0,true);
         this.s_inc.addEventListener(MouseEvent.CLICK,this.onIncrease,false,0,true);
         this.s_dec.addEventListener(MouseEvent.CLICK,this.onDecrease,false,0,true);
         this.l_inc.addEventListener(MouseEvent.CLICK,this.onIncrease,false,0,true);
         this.l_dec.addEventListener(MouseEvent.CLICK,this.onDecrease,false,0,true);
         this.r_input.addEventListener(Event.CHANGE,this.onInputChanged,false,0,true);
         this.g_input.addEventListener(Event.CHANGE,this.onInputChanged,false,0,true);
         this.b_input.addEventListener(Event.CHANGE,this.onInputChanged,false,0,true);
         this.h_input.addEventListener(Event.CHANGE,this.onInputChanged,false,0,true);
         this.s_input.addEventListener(Event.CHANGE,this.onInputChanged,false,0,true);
         this.l_input.addEventListener(Event.CHANGE,this.onInputChanged,false,0,true);
         this.sldr_bounds.addEventListener(MouseEvent.MOUSE_DOWN,this.onSliderDown,false,0,true);
         this.sldr_bounds.addEventListener(MouseEvent.MOUSE_UP,this.onSliderUp,false,0,true);
         this.sldr_bounds.addEventListener(MouseEvent.CLICK,this.onSliderClick,false,0,true);
         this.cursor.addEventListener(MouseEvent.MOUSE_DOWN,this.onCursorDown,false,0,true);
         this.cursor.addEventListener(MouseEvent.MOUSE_UP,this.onCursorUp,false,0,true);
         this.map_mc.addEventListener(MouseEvent.CLICK,this.onMapClick,false,0,true);
         this.map_mc.addEventListener(MouseEvent.MOUSE_DOWN,this.onCursorDown,false,0,true);
         this.map_mc.addEventListener(MouseEvent.MOUSE_UP,this.onCursorUp,false,0,true);
         this.hex_input.addEventListener(Event.CHANGE,this.onHexChange,false,0,true);
         this.save_btn.addEventListener(MouseEvent.CLICK,this.onSaveColor,false,0,true);
         this.bg.addEventListener(MouseEvent.MOUSE_DOWN,this.onDrag,false,0,true);
         this.addEventListener(MouseEvent.MOUSE_UP,this.onStopDrag,false,0,true);
         this.close_btn.addEventListener(MouseEvent.CLICK,this.onClose,false,0,true);
         param1.CenterWindow(this);
         if(this.ActiveSet["color_" + param3.ColorType] != null && Boolean(this.ActiveSet["color_" + param3.ColorType].hasOwnProperty("sets")))
         {
            this.saved_clrs = this.ActiveSet["color_" + param3.ColorType].sets;
            this.onSaveColor();
         }
      }
      
      private function onOver(param1:MouseEvent) : void
      {
         Mouse.cursor = "button";
      }
      
      private function onOut(param1:MouseEvent) : void
      {
         Mouse.cursor = "arrow";
      }
      
      private function onInputOver(param1:MouseEvent) : void
      {
         Mouse.cursor = "ibeam";
      }
      
      private function get Ancestor() : MovieClip
      {
         return this._ancestor;
      }
      
      private function get ActiveSet() : *
      {
         return MovieClip(this.component.parent).ActiveSet;
      }
      
      private function onSaveColor(param1:MouseEvent = null) : void
      {
         var _loc3_:MovieClip = null;
         var _loc2_:Number = 0;
         if(param1 != null)
         {
            if(this.saved_clrs.length > 0)
            {
               _loc2_ = 0;
               while(_loc2_ < this.saved_clrs.length)
               {
                  removeChild(this.saved_clrs[_loc2_].mc);
                  _loc2_++;
               }
            }
            if(this.saved_clrs.length >= 7)
            {
               this.saved_clrs.shift();
            }
            this.saved_clrs.push({
               "mc":null,
               "color":this._color
            });
         }
         _loc2_ = this.saved_clrs.length - 1;
         while(_loc2_ >= 0)
         {
            _loc3_ = addChild(new savedcolor(this.saved_clrs[_loc2_].color)) as MovieClip;
            _loc3_.x = this.CLR_START_X + this.CLR_SPACING * (this.saved_clrs.length - 1 - _loc2_);
            _loc3_.y = this.CLR_START_Y;
            this.saved_clrs[_loc2_].mc = _loc3_;
            _loc2_--;
         }
         if(param1 != null)
         {
            if(this.ActiveSet["color_" + this.component.ColorType] == null)
            {
               this.ActiveSet["color_" + this.component.ColorType] = {};
            }
            this.ActiveSet["color_" + this.component.ColorType].sets = this.saved_clrs;
         }
      }
      
      private function onInputChanged(param1:Event) : void
      {
         var _loc2_:Object = this.getRGB();
         switch(param1.target)
         {
            case this.r_input:
               this.UpdateSelectedColor(Number(this.r_input.text) << 16 | _loc2_.green << 8 | _loc2_.blue,true);
               break;
            case this.g_input:
               this.UpdateSelectedColor(_loc2_.red << 16 | Number(this.g_input.text) << 8 | _loc2_.blue,true);
               break;
            case this.b_input:
               this.UpdateSelectedColor(_loc2_.red << 16 | _loc2_.green << 8 | Number(this.b_input.text),true);
               break;
            case this.h_input:
               this._h_color = Number(this.h_input.text);
               this.ToRGB();
               break;
            case this.s_input:
               this._s_color = Number(this.s_input.text);
               this.ToRGB();
               break;
            case this.l_input:
               this._l_color = Number(this.l_input.text);
               this.ToRGB();
         }
      }
      
      private function onIncrease(param1:MouseEvent) : void
      {
         var _loc2_:Object = this.getRGB();
         switch(param1.target)
         {
            case this.r_inc:
               this.UpdateSelectedColor(_loc2_.red + 1 << 16 | _loc2_.green << 8 | _loc2_.blue,true);
               break;
            case this.g_inc:
               this.UpdateSelectedColor(_loc2_.red << 16 | _loc2_.green + 1 << 8 | _loc2_.blue,true);
               break;
            case this.b_inc:
               this.UpdateSelectedColor(_loc2_.red << 16 | _loc2_.green << 8 | _loc2_.blue + 1,true);
               break;
            case this.h_inc:
               this._h_color += 1;
               this.ToRGB();
               break;
            case this.s_inc:
               this._s_color += 0.01;
               this.ToRGB();
               break;
            case this.l_inc:
               this._l_color += 0.01;
               this.ToRGB();
         }
      }
      
      private function onDecrease(param1:MouseEvent) : void
      {
         var _loc2_:Object = this.getRGB();
         switch(param1.target)
         {
            case this.r_dec:
               this.UpdateSelectedColor(_loc2_.red - 1 << 16 | _loc2_.green << 8 | _loc2_.blue,true);
               break;
            case this.g_dec:
               this.UpdateSelectedColor(_loc2_.red << 16 | _loc2_.green - 1 << 8 | _loc2_.blue,true);
               break;
            case this.b_dec:
               this.UpdateSelectedColor(_loc2_.red << 16 | _loc2_.green << 8 | _loc2_.blue - 1,true);
               break;
            case this.h_dec:
               --this._h_color;
               this.ToRGB();
               break;
            case this.s_dec:
               this._s_color -= 0.01;
               this.ToRGB();
               break;
            case this.l_dec:
               this._l_color -= 0.01;
               this.ToRGB();
         }
      }
      
      private function getRGB() : Object
      {
         var _loc1_:Object = new Object();
         _loc1_.red = this._color >> 16 & 0xFF;
         _loc1_.green = this._color >> 8 & 0xFF;
         _loc1_.blue = this._color & 0xFF;
         return _loc1_;
      }
      
      public function UpdateSelectedColor(param1:uint, param2:Boolean = false) : void
      {
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         this._color = param1;
         if(param2)
         {
            this._map_color = this._color;
            this.createMap();
         }
         var _loc3_:Object = this.getRGB();
         this.r_input.text = _loc3_.red;
         this.g_input.text = _loc3_.green;
         this.b_input.text = _loc3_.blue;
         this.colorDisplay.color.transform.colorTransform = new ColorTransform(1,1,1,1,_loc3_.red,_loc3_.green,_loc3_.blue,0);
         var _loc4_:Number = Math.min(_loc3_.red,Math.min(_loc3_.green,_loc3_.blue));
         var _loc5_:Number = Math.max(_loc3_.red,Math.max(_loc3_.green,_loc3_.blue));
         var _loc6_:Number = _loc5_ - _loc4_;
         var _loc7_:Number = _loc5_ + _loc4_;
         this._l_color = _loc7_ / 510;
         if(_loc5_ == _loc4_)
         {
            this._s_color = 0;
            this._h_color = 0;
         }
         else
         {
            _loc9_ = (_loc5_ - _loc3_.red) / _loc6_;
            _loc10_ = (_loc5_ - _loc3_.green) / _loc6_;
            _loc11_ = (_loc5_ - _loc3_.blue) / _loc6_;
            this._s_color = this._l_color <= 0.5 ? _loc6_ / _loc7_ : _loc6_ / (510 - _loc7_);
            if(_loc3_.red == _loc5_)
            {
               this._h_color = 60 * (6 + _loc11_ - _loc10_);
            }
            else if(_loc3_.green == _loc5_)
            {
               this._h_color = 60 * (2 + _loc9_ - _loc11_);
            }
            else if(_loc3_.blue == _loc5_)
            {
               this._h_color = 60 * (4 + _loc10_ - _loc9_);
            }
            this._h_color %= 360;
         }
         this.h_input.text = String(this._h_color);
         this.s_input.text = String(this._s_color.toFixed(2));
         this.l_input.text = String(this._l_color.toFixed(2));
         var _loc8_:String = Math.abs(this._color).toString(16);
         while(_loc8_.length < 6)
         {
            _loc8_ = "0" + _loc8_;
         }
         this.hex_input.text = _loc8_.toUpperCase();
         this.component.UpdateColor(this._color);
      }
      
      private function ToRGB(param1:Object = null) : void
      {
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc2_:Object = this.getRGB();
         if(this._s_color == 0)
         {
            _loc2_.red = _loc2_.green = _loc2_.blue = this._l_color * 255;
         }
         else
         {
            if(this._l_color <= 0.5)
            {
               _loc4_ = this._l_color + this._l_color * this._s_color;
            }
            else
            {
               _loc4_ = this._l_color + this._s_color - this._l_color * this._s_color;
            }
            _loc3_ = 2 * this._l_color - _loc4_;
            _loc2_.red = this.ToRGB1(_loc3_,_loc4_,this._h_color + 120);
            _loc2_.green = this.ToRGB1(_loc3_,_loc4_,this._h_color);
            _loc2_.blue = this.ToRGB1(_loc3_,_loc4_,this._h_color - 120);
         }
         this.UpdateSelectedColor(_loc2_.red << 16 | _loc2_.green << 8 | _loc2_.blue);
      }
      
      private function ToRGB1(param1:Number, param2:Number, param3:Number) : Number
      {
         if(param3 > 360)
         {
            param3 -= 360;
         }
         else if(param3 < 0)
         {
            param3 += 360;
         }
         if(param3 < 60)
         {
            param1 += (param2 - param1) * param3 / 60;
         }
         else if(param3 < 180)
         {
            param1 = param2;
         }
         else if(param3 < 240)
         {
            param1 += (param2 - param1) * (240 - param3) / 60;
         }
         return param1 * 255;
      }
      
      private function UpdateColorAtSlider() : void
      {
         this._map_color = this.sldr_bmp.getPixel(0,this.slider.y - this.SLDR_Y);
         this.createMap();
         this.UpdateColorAtCursor();
      }
      
      private function onSliderDown(param1:MouseEvent) : void
      {
         this.addEventListener(Event.ENTER_FRAME,this.onSliderDragging,false,0,true);
      }
      
      private function onSliderDragging(param1:Event) : void
      {
         if(this.sldr_bounds.hitTestPoint(this.Ancestor.mouseX,this.Ancestor.mouseY,true))
         {
            this.slider.startDrag(true,new Rectangle(this.slider.x,this.SLDR_Y,0,this.SLDR_HEIGHT - this.slider.height));
         }
         else
         {
            this.removeEventListener(Event.ENTER_FRAME,this.onSliderDragging);
            this.slider.stopDrag();
         }
         this.UpdateColorAtSlider();
      }
      
      private function onSliderUp(param1:MouseEvent) : void
      {
         this.removeEventListener(Event.ENTER_FRAME,this.onSliderDragging);
         this.slider.stopDrag();
      }
      
      private function onSliderClick(param1:MouseEvent) : void
      {
         if(this.sldr_mc.hitTestPoint(this.Ancestor.mouseX,this.Ancestor.mouseY,true))
         {
            this.slider.y = this.sldr_bounds.mouseY + this.SLDR_Y - this.slider.height;
         }
         this.UpdateColorAtSlider();
      }
      
      private function UpdateColorAtCursor() : void
      {
         this.UpdateSelectedColor(this.map_bmp.getPixel(this.cursor.x - this.MAP_X,this.cursor.y - this.MAP_Y));
         var _loc1_:String = Math.abs(this._color).toString(16);
         while(_loc1_.length < 6)
         {
            _loc1_ = "0" + _loc1_;
         }
         this.hex_input.text = _loc1_.toUpperCase();
      }
      
      private function onCursorDown(param1:MouseEvent) : void
      {
         this.addEventListener(Event.ENTER_FRAME,this.onCursorDragging,false,0,true);
      }
      
      private function onCursorUp(param1:MouseEvent) : void
      {
         this.removeEventListener(Event.ENTER_FRAME,this.onCursorDragging);
         this.cursor.stopDrag();
      }
      
      private function onCursorDragging(param1:Event) : void
      {
         if(this.map_mc.hitTestPoint(this.Ancestor.mouseX,this.Ancestor.mouseY,true))
         {
            this.cursor.startDrag(true,new Rectangle(this.MAP_X + 7.5,this.MAP_Y + 7.5,this.MAP_SIZE - this.cursor.width,this.MAP_SIZE - this.cursor.height));
         }
         else
         {
            this.removeEventListener(Event.ENTER_FRAME,this.onCursorDragging);
            this.cursor.stopDrag();
         }
         this.UpdateColorAtCursor();
      }
      
      private function onMapClick(param1:MouseEvent) : void
      {
         this.cursor.x = this.map_mc.mouseX + this.MAP_X;
         this.cursor.y = this.map_mc.mouseY + this.MAP_Y;
         this.UpdateColorAtCursor();
      }
      
      private function onHexChange(param1:Event) : void
      {
         if(this.hex_input.text.length < 1)
         {
            return;
         }
         var _loc2_:String = this.hex_input.text;
         this._map_color = _loc2_ != "" ? uint(parseInt("0x" + _loc2_,16)) : 0;
         this._color = this._map_color;
         this.createMap();
      }
      
      private function createMap() : void
      {
         var _loc1_:String = "linear";
         var _loc2_:Array = [16777215,this._map_color];
         var _loc3_:Array = [100,100];
         var _loc4_:Array = [0,255];
         var _loc5_:Matrix = new Matrix();
         while(this.map_mc.numChildren > 0)
         {
            this.map_mc.removeChildAt(0);
         }
         this.map_mc.graphics.clear();
         _loc5_.createGradientBox(this.MAP_SIZE,this.MAP_SIZE);
         this.map_mc.graphics.beginGradientFill(_loc1_,_loc2_,_loc3_,_loc4_,_loc5_ as Matrix);
         this.map_mc.graphics.moveTo(0,0);
         this.map_mc.graphics.lineTo(0 + this.MAP_SIZE,0);
         this.map_mc.graphics.lineTo(0 + this.MAP_SIZE,0 + this.MAP_SIZE);
         this.map_mc.graphics.lineTo(0,0 + this.MAP_SIZE);
         this.map_mc.graphics.lineTo(0,0);
         this.map_mc.graphics.endFill();
         var _loc6_:MovieClip = new MovieClip();
         _loc6_.name = "upper";
         this.map_mc.addChild(_loc6_);
         _loc2_ = [16777215,0,0];
         _loc3_ = [0,0,100];
         _loc4_ = [0,15,255];
         _loc5_ = new Matrix();
         _loc5_.createGradientBox(this.MAP_SIZE,this.MAP_SIZE,90 * Math.PI / 180);
         _loc6_.graphics.beginGradientFill(_loc1_,_loc2_,_loc3_,_loc4_,_loc5_ as Matrix);
         _loc6_.graphics.moveTo(0,0);
         _loc6_.graphics.lineTo(0 + this.MAP_SIZE,0);
         _loc6_.graphics.lineTo(0 + this.MAP_SIZE,0 + this.MAP_SIZE);
         _loc6_.graphics.lineTo(0,0 + this.MAP_SIZE);
         _loc6_.graphics.lineTo(0,0);
         _loc6_.graphics.endFill();
         this.map_mc.x = this.MAP_X;
         this.map_mc.y = this.MAP_Y;
         this.map_bmp = new BitmapData(this.map_mc.width,this.map_mc.height);
         this.map_bmp.draw(this.map_mc);
         setChildIndex(this.cursor,numChildren - 1);
      }
      
      private function createSlider() : void
      {
         var _loc1_:Array = [16711680,16776960,65280,65535,255,16711935,16711680];
         var _loc2_:Array = [100,100,100,100,100,100,100];
         var _loc3_:Array = [0,42,64,127,184,215,255];
         var _loc4_:Matrix = new Matrix();
         _loc4_.createGradientBox(this.SLDR_WIDTH,this.SLDR_HEIGHT,270 * Math.PI / 180);
         this.sldr_mc.graphics.clear();
         this.sldr_mc.graphics.beginGradientFill("linear",_loc1_,_loc2_,_loc3_,_loc4_ as Matrix,"reflect","linear");
         this.sldr_mc.graphics.moveTo(0,0);
         this.sldr_mc.graphics.lineTo(0 + this.SLDR_WIDTH,0);
         this.sldr_mc.graphics.lineTo(0 + this.SLDR_WIDTH,0 + this.SLDR_HEIGHT);
         this.sldr_mc.graphics.lineTo(0,0 + this.SLDR_HEIGHT);
         this.sldr_mc.graphics.lineTo(0,0);
         this.sldr_mc.graphics.endFill();
         this.sldr_mc.x = this.SLDR_X;
         this.sldr_mc.y = this.SLDR_Y;
         this.sldr_bmp = new BitmapData(this.sldr_mc.width,this.sldr_mc.height,false);
         this.sldr_bmp.draw(this.sldr_mc);
         setChildIndex(this.slider,numChildren - 1);
         setChildIndex(this.sldr_bounds,numChildren - 1);
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         this.Ancestor.removeChild(this);
      }
      
      private function onDrag(param1:MouseEvent) : void
      {
         this.Ancestor.setChildIndex(this,this.Ancestor.numChildren - 1);
         this.addEventListener(Event.ENTER_FRAME,this.onDragging,false,0,true);
      }
      
      private function onDragging(param1:Event) : void
      {
         if(this.hitTestPoint(this.Ancestor.mouseX,this.Ancestor.mouseY,true))
         {
            this.startDrag();
         }
         else
         {
            this.removeEventListener(Event.ENTER_FRAME,this.onDragging);
            this.stopDrag();
         }
      }
      
      private function onStopDrag(param1:MouseEvent) : void
      {
         this.removeEventListener(Event.ENTER_FRAME,this.onDragging);
         this.stopDrag();
      }
   }
}

