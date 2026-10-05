package
{
   import AQWorlds.AvatarMC;
   import flash.display.*;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.*;
   import flash.system.Capabilities;
   import flash.ui.Mouse;
   
   public class main extends MovieClip
   {
      
      public var camera_btn:SimpleButton;
      
      public var file_btn:SimpleButton;
      
      public var help_btn:SimpleButton;
      
      public var ico:MovieClip;
      
      public var newScene:MovieClip;
      
      public var resizer:MovieClip;
      
      public var sidebar_mc:sidebar;
      
      public var sizer:MovieClip;
      
      public var title:MovieClip;
      
      public var title_btns:MovieClip;
      
      public var view_btn:SimpleButton;
      
      private const VERSION:String = "Alpha";
      
      public var _activeContext:context;
      
      public var _activeAltContext:context;
      
      public var _activeGame:String = "AQWorlds";
      
      public var _avatarScaling:Number = 1;
      
      public var _activeCamera:MovieClip;
      
      public var _activeAbout:MovieClip;
      
      public function main()
      {
         super();
         addFrameScript(0,this.frame1,1,this.frame2);
         stage.scaleMode = StageScaleMode.NO_SCALE;
         stage.align = StageAlign.TOP_LEFT;
         stage.nativeWindow.minSize = new Point(960,550);
         var _loc1_:Rectangle = stage.nativeWindow.bounds;
         stage.nativeWindow.x = (Capabilities.screenResolutionX - _loc1_.width) * 0.5;
         stage.nativeWindow.y = (Capabilities.screenResolutionY - _loc1_.height) * 0.5;
         this.newScene.comingsoon.addEventListener(MouseEvent.MOUSE_OVER,this.ComingSoon,false,0,true);
         this.title_btns.close_btn.addEventListener(MouseEvent.CLICK,this.onClose,false,0,true);
         this.newScene.bg.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown,false,0,true);
         this.title.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown,false,0,true);
         this.newScene.aqw.addEventListener(MouseEvent.CLICK,this.onSelectGame,false,0,true);
         this.newScene.ed.addEventListener(MouseEvent.CLICK,this.onSelectGame,false,0,true);
      }
      
      public function get ActiveAvatar() : *
      {
         return this.sidebar_mc.characters_content.ActiveAvatar;
      }
      
      public function get ActiveSet() : *
      {
         return this.sidebar_mc.characters_content.ActiveSet;
      }
      
      private function onSelectGame(param1:MouseEvent) : void
      {
         this._activeGame = param1.target == this.newScene.aqw ? "AQWorlds" : "EpicDuel";
         play();
         this.addEventListener(Event.ENTER_FRAME,this.onWaitSwitch,false,0,true);
      }
      
      private function onWaitSwitch(param1:Event) : void
      {
         if(this.currentFrame != 2 || !this.camera_btn)
         {
            return;
         }
         this.removeEventListener(Event.ENTER_FRAME,this.onWaitSwitch);
         this.camera_btn.addEventListener(MouseEvent.CLICK,this.onCamera,false,0,true);
         stage.addEventListener(MouseEvent.CLICK,this.onStageClick,false,0,true);
         stage.addEventListener(MouseEvent.RIGHT_CLICK,this.onContextMenu,false,0,true);
         this.resizer.addEventListener(MouseEvent.MOUSE_DOWN,this.onResizeDown,false,0,true);
         stage.nativeWindow.addEventListener("resize",this.onResize,false,0,true);
         this.sizer.input.addEventListener(Event.CHANGE,this.onSizerChange,false,0,true);
         this.sizer.input.addEventListener(MouseEvent.MOUSE_OVER,this.onSizerOver,false,0,true);
         this.sizer.input.addEventListener(MouseEvent.MOUSE_OUT,this.onSizerOut,false,0,true);
         this.file_btn.addEventListener(MouseEvent.CLICK,this.onFile,false,0,true);
         this.view_btn.addEventListener(MouseEvent.CLICK,this.onView,false,0,true);
         this.help_btn.addEventListener(MouseEvent.CLICK,this.onHelp,false,0,true);
         this.title_btns.restore_btn.visible = false;
         this.title_btns.close_btn.addEventListener(MouseEvent.CLICK,this.onClose,false,0,true);
         this.title_btns.max_btn.addEventListener(MouseEvent.CLICK,this.onMax,false,0,true);
         this.title_btns.restore_btn.addEventListener(MouseEvent.CLICK,this.onMax,false,0,true);
         this.title_btns.min_btn.addEventListener(MouseEvent.CLICK,this.onMin,false,0,true);
         this.title.doubleClickEnabled = true;
         this.title.addEventListener(MouseEvent.DOUBLE_CLICK,this.onMax,false,0,true);
         this.title.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown,false,0,true);
      }
      
      private function onSizerOver(param1:MouseEvent) : void
      {
         Mouse.cursor = "ibeam";
      }
      
      private function onSizerOut(param1:MouseEvent) : void
      {
         Mouse.cursor = "arrow";
      }
      
      private function ComingSoon(param1:MouseEvent) : void
      {
         new tooltip("Coming Soon",this.newScene.comingsoon,this);
      }
      
      private function onCamera(param1:MouseEvent) : void
      {
         this._activeCamera = addChild(new screenshot(this)) as MovieClip;
      }
      
      public function onSizerChange(param1:Event) : void
      {
         var _loc2_:Number = Number(this.sizer.input.text);
         if(_loc2_ < 0)
         {
            return;
         }
         this._avatarScaling = _loc2_;
         this.sidebar_mc.setswitcher.ResizeAvatars(this._avatarScaling);
      }
      
      public function ClearCanvas() : void
      {
         var _loc1_:uint = 0;
         while(_loc1_ < numChildren)
         {
            if(getChildAt(_loc1_) is advcolor || getChildAt(_loc1_) is tooltip)
            {
               removeChildAt(_loc1_);
               _loc1_--;
            }
            _loc1_++;
         }
      }
      
      public function ResetCanvas() : void
      {
         this.sidebar_mc.setswitcher.ResetSets();
      }
      
      public function ToggleSidebar(param1:MouseEvent = null) : void
      {
         this.sizer.visible = !this.sizer.visible;
         this.sidebar_mc.visible = !this.sidebar_mc.visible;
      }
      
      public function CenterWindow(param1:MovieClip) : void
      {
         var _loc2_:Rectangle = stage.nativeWindow.bounds;
         var _loc3_:Number = this.sidebar_mc.visible ? _loc2_.width - 248.2 : _loc2_.width;
         var _loc4_:Number = this.sidebar_mc.visible ? _loc2_.height - 32.25 : _loc2_.height;
         param1.x = _loc3_ / 2 - param1.width / 2;
         param1.y = _loc4_ / 2 - param1.height / 2;
      }
      
      public function SwitchGames() : void
      {
         this.sidebar_mc.setswitcher.SwitchGames();
         this.sidebar_mc.characters_content.SwitchGames();
      }
      
      private function onFile(param1:MouseEvent) : void
      {
         new context(this,[{
            "label":"Clear Canvas",
            "func":this.ResetCanvas
         }],35,30);
      }
      
      private function onView(param1:MouseEvent) : void
      {
         new context(this,[{
            "label":"Hide Interface",
            "func":this.ToggleSidebar,
            "active":!this.sidebar_mc.visible
         }],70,30);
      }
      
      private function onHelp(param1:MouseEvent) : void
      {
         new context(this,[{
            "label":"About Paradigm",
            "func":this.context_onAbout
         }],105,30);
      }
      
      private function onStageClick(param1:MouseEvent) : void
      {
         var _loc2_:* = param1.target;
         while(Boolean(_loc2_) && _loc2_ != stage)
         {
            if(_loc2_.name == "contextMenu" || _loc2_.name == "altMenu")
            {
               return;
            }
            _loc2_ = _loc2_.parent;
         }
         this.clearContextMenu();
      }
      
      private function onContextMenu(param1:MouseEvent) : void
      {
         new context(this,[{
            "label":"Clear Canvas",
            "func":this.ResetCanvas
         }]);
      }
      
      private function context_onAbout() : void
      {
         this._activeAbout = new about(this);
      }
      
      public function onContextItemClick() : void
      {
         new messagebox(this,"<font size=\"10\" style=\"roboto medium\" color=\"#727272\">This feature is not yet implemented.</font>");
      }
      
      public function clearContextMenu() : void
      {
         try
         {
            if(this._activeContext != null)
            {
               removeChild(this._activeContext);
            }
         }
         catch(e:*)
         {
         }
         this._activeContext = null;
      }
      
      public function clearAltContextMenu() : void
      {
         try
         {
            if(this._activeAltContext != null)
            {
               removeChild(this._activeAltContext);
            }
         }
         catch(e:*)
         {
         }
         this._activeAltContext = null;
      }
      
      private function onResizeDown(param1:MouseEvent) : void
      {
         if(stage.mouseX <= this.title.width && stage.mouseX >= 0 && (stage.mouseY <= this.title.height && stage.mouseY >= 0))
         {
            return;
         }
         var _loc2_:String = "";
         if(param1.stageY < stage.nativeWindow.height * 0.33)
         {
            _loc2_ = NativeWindowResize.TOP;
         }
         else if(param1.stageY > stage.nativeWindow.height * 0.66)
         {
            _loc2_ = NativeWindowResize.BOTTOM;
         }
         if(param1.stageX < stage.nativeWindow.width * 0.33)
         {
            _loc2_ += NativeWindowResize.LEFT;
         }
         else if(param1.stageX > stage.nativeWindow.width * 0.66)
         {
            _loc2_ += NativeWindowResize.RIGHT;
         }
         stage.nativeWindow.startResize(_loc2_);
      }
      
      private function onResize(param1:Event) : void
      {
         var _loc2_:* = stage.nativeWindow.bounds;
         var _loc3_:* = this.sidebar_mc.getBounds(this);
         this.resizer.x = _loc2_.width - 24.8;
         this.resizer.y = _loc2_.height - 25.05;
         this.title.width = _loc2_.width + 41.3;
         this.title_btns.x = _loc2_.width - (960 - 832.55);
         this.camera_btn.x = _loc2_.width - (960 - 807);
         this.sidebar_mc.x = _loc2_.width - this.sidebar_mc.width;
         this.sidebar_mc.y = 31.7;
         this.resizesidebar_mc();
         this.sizer.x = this.sidebar_mc.x - this.sizer.width - 1;
         var _loc4_:MovieClip = this.sidebar_mc.background_content;
         if(Boolean(_loc4_._scale) && Boolean(_loc4_._placed))
         {
            _loc4_._placed.scaleX = _loc2_.width / stage.nativeWindow.minSize.x;
            _loc4_._placed.scaleY = _loc2_.height / stage.nativeWindow.minSize.y;
         }
      }
      
      public function LayerInterface() : void
      {
         try
         {
            setChildIndex(this.title,numChildren - 1);
            setChildIndex(this.ico,numChildren - 1);
            setChildIndex(this.file_btn,numChildren - 1);
            setChildIndex(this.view_btn,numChildren - 1);
            setChildIndex(this.help_btn,numChildren - 1);
            setChildIndex(this.camera_btn,numChildren - 1);
            setChildIndex(this.title_btns,numChildren - 1);
            setChildIndex(this.sidebar_mc,numChildren - 1);
            setChildIndex(this.resizer,numChildren - 1);
            setChildIndex(this.sizer,numChildren - 1);
            if(this._activeCamera)
            {
               this._activeCamera.onFocus();
            }
            if(this._activeAbout)
            {
               setChildIndex(this._activeAbout,numChildren - 1);
            }
         }
         catch(e:*)
         {
         }
      }
      
      private function resizesidebar_mc() : void
      {
         var _loc1_:* = stage.nativeWindow.bounds;
         this.sidebar_mc.bg.height = _loc1_.height - this.sidebar_mc.y;
         this.sidebar_mc.setswitcher.y = this.sidebar_mc.bg.height - 45.55;
         this.sidebar_mc.switch_btn_separator.y = this.sidebar_mc.bg.height - 59.1;
         this.sidebar_mc.sb.bg.height = this.sidebar_mc.bg.height - 127.4;
         this.sidebar_mc.contentmask.height = this.sidebar_mc.switch_btn_separator.y + 15 - 73.2;
         this.LayerInterface();
      }
      
      private function onMax(param1:MouseEvent) : void
      {
         if(stage.nativeWindow.displayState != NativeWindowDisplayState.MAXIMIZED)
         {
            stage.nativeWindow.maximize();
         }
         else
         {
            stage.nativeWindow.restore();
         }
         this.title_btns.restore_btn.visible = stage.nativeWindow.displayState != NativeWindowDisplayState.MAXIMIZED;
         this.title_btns.max_btn.visible = stage.nativeWindow.displayState == NativeWindowDisplayState.MAXIMIZED;
      }
      
      private function onMin(param1:MouseEvent) : void
      {
         stage.nativeWindow.minimize();
      }
      
      private function onDown(param1:MouseEvent) : void
      {
         stage.nativeWindow.startMove();
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         stage.nativeWindow.close();
      }
      
      public function mcSetColor(param1:MovieClip, param2:String, param3:String) : *
      {
         var _loc4_:MovieClip = param1;
         while(_loc4_ != null && _loc4_.parent != null && _loc4_.parent != _loc4_.stage)
         {
            if(_loc4_ is AvatarMC)
            {
               break;
            }
            _loc4_ = MovieClip(_loc4_.parent);
         }
         (_loc4_ as AvatarMC).setColor(param1,param2,param3);
      }
      
      public function registerAttackFrame(param1:MovieClip) : *
      {
         var _loc2_:MovieClip = param1;
         while(_loc2_ != null && _loc2_.parent != null && _loc2_.parent != _loc2_.stage)
         {
            if(_loc2_ is AvatarMC)
            {
               break;
            }
            _loc2_ = MovieClip(_loc2_.parent);
         }
         if(_loc2_ is AvatarMC)
         {
            if(!("attackFrames" in _loc2_.pAV.pMC))
            {
               return;
            }
            if(Boolean(_loc2_.pAV.pMC.attackFrames) && _loc2_.pAV.pMC.attackFrames.indexOf(param1) != -1)
            {
               _loc2_.pAV.pMC.attackFrames.splice(_loc2_.pAV.pMC.attackFrames.indexOf(param1),1);
            }
            _loc2_.pAV.pMC.attackFrames.push(param1);
         }
      }
      
      internal function frame1() : *
      {
         stop();
      }
      
      internal function frame2() : *
      {
         stop();
      }
   }
}

