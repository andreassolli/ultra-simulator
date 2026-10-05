package
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2454")]
   public class scroll extends MovieClip
   {
      
      public var bg:MovieClip;
      
      public var fg:MovieClip;
      
      private const ACTIVE_TAB_START_Y:Number = 58.15;
      
      private const SPACING:Number = 30;
      
      private var ActiveTab:MovieClip;
      
      private var MaskHeight:Number;
      
      private var mDown:Boolean = false;
      
      public function scroll()
      {
         super();
         this.addEventListener(Event.ENTER_FRAME,this.onStage,false,0,true);
      }
      
      private function onStage(param1:Event) : void
      {
         if(MovieClip(parent).ActiveTab == null)
         {
            return;
         }
         this.removeEventListener(Event.ENTER_FRAME,this.onStage);
         MovieClip(parent).addEventListener(MouseEvent.MOUSE_WHEEL,this.onWheel,false,0,true);
         this.fg.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown,false,0,true);
         stage.addEventListener(MouseEvent.MOUSE_UP,this.onUp,false,0,true);
         this.addEventListener(Event.ENTER_FRAME,this.onUpdate,false,0,true);
         this.ResizeBar();
      }
      
      private function onWheel(param1:MouseEvent) : void
      {
         if(this.fg.height == this.bg.height)
         {
            return;
         }
         param1.delta *= -3;
         param1.delta /= 0.5;
         this.fg.y += param1.delta;
         if(this.fg.y < 0)
         {
            this.fg.y = 0;
         }
         if(this.fg.y > this.bg.height - this.fg.height)
         {
            this.fg.y = this.bg.height - this.fg.height;
         }
         this.UpdateContent();
      }
      
      private function onUpdate(param1:Event) : void
      {
         if(this.ActiveTab != MovieClip(parent).ActiveTab || MovieClip(parent).contentmask.height != this.MaskHeight)
         {
            this.ResizeBar();
         }
         if(!this.mDown)
         {
            this.fg.stopDrag();
            return;
         }
         this.fg.startDrag(false,new Rectangle(0,0,0,this.bg.height - this.fg.height));
         this.UpdateContent();
      }
      
      private function UpdateContent() : void
      {
         this.ActiveTab.y = this.ACTIVE_TAB_START_Y + -1 * ((this.ActiveTab.height - this.MaskHeight + this.SPACING) * (this.fg.y / (this.bg.height - this.fg.height)));
      }
      
      private function UpdateBar() : void
      {
      }
      
      private function onDown(param1:MouseEvent) : void
      {
         if(this.fg.height == this.bg.height)
         {
            return;
         }
         this.mDown = true;
      }
      
      private function onUp(param1:MouseEvent) : void
      {
         this.mDown = false;
      }
      
      public function ResetScroll() : void
      {
         this.ActiveTab.y = this.ACTIVE_TAB_START_Y;
         this.fg.y = 0;
      }
      
      public function ResizeBar() : void
      {
         this.ActiveTab = MovieClip(parent).ActiveTab;
         this.MaskHeight = MovieClip(parent).contentmask.height;
         this.ResetScroll();
         this.fg.height = this.ActiveTab.height <= this.MaskHeight ? (this.fg.height = this.bg.height) : this.bg.height * (this.MaskHeight / this.ActiveTab.height);
         this.visible = this.fg.height != this.bg.height;
      }
   }
}

