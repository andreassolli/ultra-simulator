package
{
   import com.adobe.images.PNGEncoder;
   import flash.desktop.Clipboard;
   import flash.desktop.ClipboardFormats;
   import flash.display.*;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;

   [Embed(source="/_assets/assets.swf", symbol="symbol49")]
   public class screenshot extends MovieClip
   {

      public var clipboard_btn:SimpleButton;

      public var close_btn:SimpleButton;

      public var export_btn:SimpleButton;

      public var export_txt:TextField;

      public var options_btn:SimpleButton;

      private var Ancestor:MovieClip;

      private var _activeOption:String = "";

      private var _context:*;

      public function screenshot(param1:MovieClip)
      {
         super();
         this.Ancestor = param1;
         this.Ancestor.CenterWindow(this);
         this.export_txt.mouseEnabled = false;
         this.export_btn.addEventListener(MouseEvent.CLICK,this.onExport,false,0,true);
         this.clipboard_btn.addEventListener(MouseEvent.CLICK,this.onClip,false,0,true);
         this.clipboard_btn.addEventListener(MouseEvent.MOUSE_OVER,this.onOverClip,false,0,true);
         this.options_btn.addEventListener(MouseEvent.CLICK,this.onDropDown,false,0,true);
         this.close_btn.addEventListener(MouseEvent.CLICK,this.onClose,false,0,true);
         this.addEventListener(MouseEvent.CLICK,this.onFocus,false,0,true);
      }

      public function onFocus(param1:MouseEvent = null) : void
      {
         try
         {
            this.Ancestor.setChildIndex(this,this.Ancestor.numChildren - 1);
            if(this._context)
            {
               this.Ancestor.setChildIndex(this._context,this.Ancestor.numChildren - 1);
            }
         }
         catch(e:*)
         {
         }
      }

      public function ClearContextMenu() : void
      {
         if(this._context)
         {
            try
            {
               this.Ancestor.removeChild(this._context);
            }
            catch(e:*)
            {
            }
         }
         this._context = null;
      }

      private function get ActiveAvatar() : *
      {
         return this.Ancestor.sidebar_mc.characters_content.ActiveAvatar.pMC;
      }

      private function ProduceBMP() : Array
      {
         var _loc1_:Rectangle = null;
         var _loc2_:Number = NaN;
         var _loc3_:Matrix = null;
         var _loc4_:Boolean = false;
         var _loc6_:BitmapData = null;
         var _loc7_:Rectangle = null;
         var _loc8_:Array = null;
         var _loc9_:* = undefined;
         if(this._activeOption == "")
         {
            return [];
         }
         var _loc5_:Array = [];
         switch(this._activeOption)
         {
            case "Window":
               this.visible = false;
               this.Ancestor.ClearCanvas();
               _loc7_ = stage.nativeWindow.bounds;
               _loc6_ = new BitmapData(_loc7_.width,_loc7_.height,true,0);
               _loc6_.draw(this.Ancestor);
               _loc5_.push(_loc6_);
               this.visible = true;
               break;
            case "Active Avatar":
               _loc1_ = this.ActiveAvatar.getBounds(this.Ancestor);
               _loc2_ = 15;
               _loc3_ = new Matrix();
               if(this.Ancestor._activeGame == "AQWorlds")
               {
                  _loc3_.translate(_loc1_.width / 2,_loc1_.height / 1.5);
                  _loc3_.scale(_loc2_,_loc2_);
                  _loc6_ = new BitmapData(_loc2_ * _loc1_.width,_loc2_ * _loc1_.height,true,0);
                  _loc6_.draw(this.ActiveAvatar,_loc3_);
                  _loc5_.push(_loc6_);
               }
               break;
            case "Active Avatar Pet":
               if(this.ActiveAvatar.pAV.petMC.mcChar == null)
               {
                  return [];
               }
               _loc1_ = this.ActiveAvatar.pAV.petMC.mcChar.getBounds(this.Ancestor);
               _loc2_ = 15;
               _loc3_ = new Matrix();
               _loc3_.translate(_loc1_.width * 1.5,_loc1_.height * 1.15);
               _loc3_.scale(_loc2_,_loc2_);
               _loc6_ = new BitmapData(_loc2_ * (_loc1_.width * 2),_loc2_ * (_loc1_.height * 2),true,0);
               _loc6_.draw(this.ActiveAvatar.pAV.petMC.mcChar,_loc3_);
               _loc5_.push(_loc6_);
               break;
            case "All Visible Avatars":
               _loc8_ = this.Ancestor.sidebar_mc.setswitcher.ActiveAvatars;
               for each(_loc9_ in _loc8_)
               {
                  if(this.Ancestor._activeGame == "AQWorlds")
                  {
                     _loc1_ = _loc9_.getBounds(this.Ancestor);
                     _loc2_ = 15;
                     _loc3_ = new Matrix();
                     _loc3_.translate(_loc1_.width / 2,_loc1_.height / 1.5);
                     _loc3_.scale(_loc2_,_loc2_);
                     _loc6_ = new BitmapData(_loc2_ * _loc1_.width,_loc2_ * _loc1_.height,true,0);
                     _loc6_.draw(_loc9_,_loc3_);
                     _loc5_.push(_loc6_);
                  }
               }
         }
         return _loc5_;
      }

      private function onExport(param1:MouseEvent) : void
      {
         if(this._activeOption == "")
         {
            return;
         }
         var _loc2_:File = new File();
         if(this._activeOption == "All Visible Avatars")
         {
            _loc2_.browseForDirectory("PNG Screenshots of " + this._activeOption);
            _loc2_.addEventListener(Event.SELECT,this.SaveFilesSelected);
         }
         else
         {
            _loc2_.browseForSave("PNG Screenshot of " + this._activeOption);
            _loc2_.addEventListener(Event.SELECT,this.SaveFileSelected);
         }
      }

      private function SaveFileSelected(param1:Event) : void
      {
         var _loc2_:FileStream = new FileStream();
         _loc2_.open(param1.target as File,FileMode.WRITE);
         _loc2_.writeBytes(PNGEncoder.encode(this.ProduceBMP()[0]));
         _loc2_.close();
      }

      private function SaveFilesSelected(param1:Event) : void
      {
         var _loc4_:* = undefined;
         var _loc5_:String = null;
         var _loc6_:File = null;
         var _loc7_:FileStream = null;
         var _loc2_:Array = this.ProduceBMP();
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            _loc5_ = this.Ancestor._activeGame + "_" + String(new Date().time) + "_" + _loc3_ + ".png";
            _loc6_ = new File((param1.target as File).nativePath + "\\" + _loc5_);
            _loc7_ = new FileStream();
            _loc7_.open(_loc6_,FileMode.WRITE);
            _loc7_.writeBytes(PNGEncoder.encode(_loc4_));
            _loc7_.close();
            _loc3_++;
         }
      }

      private function onDropDown(param1:MouseEvent) : void
      {
         if(Boolean(this._context) && this._context.parent != null)
         {
            try
            {
               this.Ancestor.removeChild(this._context);
            }
            catch(e:*)
            {
            }
            this._context = null;
            return;
         }
         var _loc2_:Point = localToGlobal(new Point(this.options_btn.x,this.options_btn.y));
         this._context = new context(this.Ancestor,[{
            "label":"Window",
            "func":this.SetWindow,
            "active":this._activeOption == "Window"
         },{
            "label":"Active Avatar",
            "func":this.SetAvatar,
            "active":this._activeOption == "Active Avatar"
         },{
            "label":"Active Avatar Pet",
            "func":this.SetPet,
            "active":this._activeOption == "Active Avatar Pet"
         },{
            "label":"All Visible Avatars",
            "func":this.SetAll,
            "active":this._activeOption == "All Visible Avatars"
         }],_loc2_.x + 49,_loc2_.y + this.options_btn.height);
      }

      private function SetActive(param1:String) : void
      {
         this._activeOption = param1;
         this.export_txt.text = param1;
         this._context = null;
      }

      private function SetWindow() : void
      {
         this.SetActive("Window");
      }

      private function SetAvatar() : void
      {
         this.SetActive("Active Avatar");
      }

      private function SetPet() : void
      {
         this.SetActive("Active Avatar Pet");
      }

      private function SetAll() : void
      {
         this.SetActive("All Visible Avatars");
      }

      private function onClip(param1:MouseEvent) : void
      {
         if(this._activeOption == "")
         {
            return;
         }
         Clipboard.generalClipboard.setData(ClipboardFormats.BITMAP_FORMAT,this.ProduceBMP()[0]);
      }

      private function onOverClip(param1:MouseEvent) : void
      {
         new tooltip("Copy to Clipboard",this.clipboard_btn,this.Ancestor);
      }

      private function onClose(param1:MouseEvent) : void
      {
         if(this._context)
         {
            try
            {
               this.Ancestor.removeChild(this._context);
            }
            catch(e:*)
            {
            }
            this._context = null;
         }
         this.Ancestor._activeCamera = null;
         this.Ancestor.removeChild(this);
      }
   }
}
