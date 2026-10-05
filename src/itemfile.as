package
{
   import flash.desktop.ClipboardFormats;
   import flash.desktop.NativeDragActions;
   import flash.desktop.NativeDragManager;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.NativeDragEvent;
   import flash.filesystem.File;
   import flash.net.FileFilter;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol185")]
   public class itemfile extends MovieClip
   {
      
      public var file:TextField;
      
      public var icon:MovieClip;
      
      public var type:TextField;
      
      public function itemfile(param1:String)
      {
         super();
         this.type.text = param1;
         this.icon.gotoAndStop(param1);
         this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,this.onInitDrag,false,0,true);
         this.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,this.onDrop,false,0,true);
         this.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT,this.onExit,false,0,true);
         this.addEventListener(MouseEvent.CLICK,this.OpenFileDialog,false,0,true);
         this.addEventListener(Event.ADDED_TO_STAGE,this.onStage,false,0,true);
      }
      
      private function onStage(param1:Event) : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onStage);
         this.file.text = this.ActiveSet["item_file_" + this.type.text] != null ? this.ActiveSet["item_file_" + this.type.text].name : "";
      }
      
      private function OpenFileDialog(param1:MouseEvent) : void
      {
         var _loc2_:File = new File();
         _loc2_.browseForOpen(this.type.text,[new FileFilter("SWF","*.swf")]);
         _loc2_.addEventListener(Event.SELECT,this.OpenFileSelected);
      }
      
      private function OpenFileSelected(param1:Event) : void
      {
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               this.handleAQWFile(param1.target as File);
               break;
            case "EpicDuel":
               this.handleEDFile([param1.target as File]);
         }
      }
      
      private function onInitDrag(param1:NativeDragEvent) : void
      {
         NativeDragManager.acceptDragDrop(this);
      }
      
      private function get itemType() : Function
      {
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               switch(this.type.text)
               {
                  case "Weapon":
                     return this.ActiveAvatar.pMC.onLoadWeaponComplete;
                  case "Helmet":
                     return this.ActiveAvatar.pMC.onLoadHelmComplete;
                  case "Hair":
                     return this.ActiveAvatar.pMC.onHairLoadComplete;
                  case "Cape":
                     return this.ActiveAvatar.pMC.onLoadCapeComplete;
                  case "Armor":
                     return this.ActiveAvatar.pMC.onLoadArmorComplete;
                  case "Ground":
                     return this.ActiveAvatar.pMC.onLoadMiscComplete;
                  case "Pet":
                     return this.ActiveAvatar.onLoadPetComplete;
               }
               break;
            case "EpicDuel":
               switch(this.type.text)
               {
                  case "Primary":
                  case "Secondary":
                  case "Auxiliary":
                  case "Hair Above":
                  case "Hair":
                  case "Head":
                  case "Armor":
                  case "Craft":
                     return this.ActiveAvatar.assetCompleteHandler;
               }
         }
         return null;
      }
      
      private function get ActiveAvatar() : *
      {
         return MovieClip(parent).ActiveAvatar;
      }
      
      private function get ActiveSet() : *
      {
         return MovieClip(parent).ActiveSet;
      }
      
      private function get ActiveGame() : String
      {
         return MovieClip(parent).ActiveGame;
      }
      
      public function ClearItem() : void
      {
      }
      
      private function loadFile(param1:File) : void
      {
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               this.ActiveSet["itemLinks"][this.type.text] = param1.name.split(".swf")[0];
               this.ActiveAvatar.pMC.load(param1.nativePath,this.itemType);
               break;
            case "EpicDuel":
               this.ActiveAvatar.queueLoad(param1.nativePath,this.itemType);
         }
      }
      
      private function onDrop(param1:NativeDragEvent) : void
      {
         NativeDragManager.dropAction = NativeDragActions.COPY;
         var _loc2_:Array = param1.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
         if(_loc2_.length < 1)
         {
            return;
         }
         switch(this.ActiveGame)
         {
            case "AQWorlds":
               this.handleAQWFile(_loc2_[0]);
               break;
            case "EpicDuel":
               this.handleEDFile(_loc2_);
         }
      }
      
      private function handleAQWFile(param1:File) : void
      {
         var _loc2_:String = param1.name.split(".swf")[0];
         this.file.text = _loc2_;
         this.loadFile(param1);
         this.ActiveSet["item_file_" + this.type.text] = {
            "name":_loc2_,
            "path":param1.nativePath,
            "date":param1.modificationDate
         };
      }
      
      private function handleEDFile(param1:Array) : void
      {
         var _loc2_:File = null;
         for each(_loc2_ in param1)
         {
            this.loadFile(_loc2_);
         }
         this.ActiveAvatar.processQueue();
      }
      
      private function onExit(param1:NativeDragEvent) : void
      {
      }
   }
}

