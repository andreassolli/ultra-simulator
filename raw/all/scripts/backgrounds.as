package
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2430")]
   public class backgrounds extends MovieClip
   {
      
      private const START_X:Number = 5.65;
      
      private const START_Y:Number = 57.9;
      
      private const SPACING:Number = 55;
      
      private var maps:Object;
      
      private var map_count:uint = 0;
      
      private var queue:Array;
      
      public var _placed:*;
      
      private var origSize:Point;
      
      public var _scale:Boolean = false;
      
      private var tLoader:Loader;
      
      private var AD:ApplicationDomain;
      
      private var LC:LoaderContext;
      
      public function backgrounds()
      {
         var _loc1_:File = null;
         var _loc2_:Array = null;
         var _loc3_:uint = 0;
         var _loc4_:* = undefined;
         this.maps = {};
         this.queue = [];
         this.origSize = new Point(0,0);
         this.tLoader = new Loader();
         this.AD = new ApplicationDomain();
         this.LC = new LoaderContext(false,this.AD);
         super();
         try
         {
            _loc1_ = File.applicationDirectory;
            _loc1_ = _loc1_.resolvePath("backgrounds");
            _loc2_ = _loc1_.getDirectoryListing();
            _loc3_ = 0;
            while(_loc3_ < _loc2_.length)
            {
               this.queueLoad(_loc2_[_loc3_]);
               _loc3_++;
            }
            _loc4_ = addChild(new optioncomponent("Scale Background",false));
            _loc4_.x = this.START_X;
            _loc4_.y = 16.9;
            _loc4_ = addChild(new backgroundcomponent({
               "name":"None",
               "mc":null
            }));
            _loc4_.x = this.START_X;
            _loc4_.y = this.START_Y;
            ++this.map_count;
            this.processQueue();
         }
         catch(e:*)
         {
         }
      }
      
      private function get Ancestor() : *
      {
         return MovieClip(MovieClip(parent).parent);
      }
      
      public function scaleBG(param1:Boolean) : void
      {
         var _loc2_:Rectangle = null;
         this._scale = param1;
         if(!this._placed)
         {
            return;
         }
         if(this._scale)
         {
            _loc2_ = this.Ancestor.stage.nativeWindow.bounds;
            this._placed.scaleX = _loc2_.width / this.Ancestor.stage.nativeWindow.minSize.x;
            this._placed.scaleY = _loc2_.height / this.Ancestor.stage.nativeWindow.minSize.y;
         }
         else
         {
            this._placed.width = this.origSize.x;
            this._placed.height = this.origSize.y;
         }
      }
      
      public function SetBG(param1:String) : void
      {
         var _loc2_:Rectangle = null;
         if(this._placed)
         {
            this.Ancestor.removeChild(this._placed);
         }
         if(param1 == "None")
         {
            this._placed = null;
            return;
         }
         try
         {
            this._placed = this.Ancestor.addChild(this.maps[param1]);
            this._placed.mouseEnabled = this._placed.mouseChildren = false;
            this._placed.y = 55;
            this.origSize = new Point(this._placed.width,this._placed.height);
            if(this._scale)
            {
               _loc2_ = this.Ancestor.stage.nativeWindow.bounds;
               this._placed.scaleX = _loc2_.width / this.Ancestor.stage.nativeWindow.minSize.x;
               this._placed.scaleY = _loc2_.height / this.Ancestor.stage.nativeWindow.minSize.y;
            }
            else
            {
               this._placed.width = this.origSize.x;
               this._placed.height = this.origSize.y;
            }
            this.Ancestor.setChildIndex(this._placed,0);
         }
         catch(e:*)
         {
         }
      }
      
      private function queueLoad(param1:File) : void
      {
         this.queue.push(param1);
      }
      
      private function processQueue() : void
      {
         if(this.queue.length < 1)
         {
            return;
         }
         this.loadBG(this.queue[0]);
      }
      
      private function loadBG(param1:File) : void
      {
         var _loc2_:ByteArray = new ByteArray();
         var _loc3_:FileStream = new FileStream();
         _loc3_.open(param1,FileMode.READ);
         _loc3_.readBytes(_loc2_);
         _loc3_.close();
         this.tLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onLoadBackground,false,0,true);
         this.LC.allowLoadBytesCodeExecution = true;
         this.tLoader.loadBytes(_loc2_,this.LC);
      }
      
      private function onLoadBackground(param1:Event) : void
      {
         this.maps[this.queue[0].name.split(".swf")[0]] = param1.target.content;
         var _loc2_:* = addChild(new backgroundcomponent({
            "name":this.queue[0].name.split(".swf")[0],
            "mc":this.maps[this.queue[0].name.split(".swf")[0]]
         }));
         _loc2_.x = this.START_X;
         _loc2_.y = this.START_Y + this.SPACING * this.map_count;
         ++this.map_count;
         this.queue.shift();
         this.processQueue();
      }
   }
}

