package AQWorlds
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.ColorTransform;
   import flash.utils.Timer;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol91")]
   public class PetMC extends MovieClip
   {
      
      public var defaultmc:MovieClip;
      
      public var pname:MovieClip;
      
      public var shadow:MovieClip;
      
      internal var ldr:Loader = new Loader();
      
      internal var WORLD:MovieClip;
      
      internal var xDep:*;
      
      internal var yDep:*;
      
      internal var xTar:*;
      
      internal var yTar:Number;
      
      internal var ox:*;
      
      internal var oy:*;
      
      internal var px:*;
      
      internal var py:*;
      
      internal var tx:*;
      
      internal var ty:Number;
      
      internal var nDuration:*;
      
      internal var nXStep:*;
      
      internal var nYStep:Number;
      
      internal var cbx:*;
      
      internal var cby:Number;
      
      internal var defaultCT:ColorTransform = MovieClip(this).transform.colorTransform;
      
      internal var iniTimer:Timer;
      
      public var spFX:Object = {};
      
      public var mcChar:MovieClip;
      
      private var m:MovieClip;
      
      public function PetMC(param1:MovieClip)
      {
         super();
         this.pname.visible = false;
         this.pname.ti.text = "";
         param1.addChild(this);
         this.visible = false;
      }
      
      private function linearTween(param1:*, param2:*, param3:*, param4:*) : Number
      {
         return param3 * param1 / param4 + param2;
      }
      
      public function walkTo(param1:*, param2:*, param3:*) : void
      {
         this.xDep = this.x;
         this.yDep = this.y;
         this.xTar = param1;
         this.yTar = param2;
         this.nDuration = Math.round(Math.sqrt(Math.pow(this.xTar - this.x,2) + Math.pow(this.yTar - this.y,2)) / param3);
         if(this.nDuration)
         {
            this.nXStep = 0;
            this.nYStep = 0;
            if(!this.mcChar.onMove)
            {
               this.mcChar.onMove = true;
               this.mcChar.gotoAndPlay("Walk");
            }
            this.addEventListener(Event.ENTER_FRAME,this.onEnterFrameWalk,false,0,true);
         }
      }
      
      private function onEnterFrameWalk(param1:Event) : void
      {
         var _loc2_:* = undefined;
         var _loc3_:* = undefined;
         if(this.nXStep <= this.nDuration || Boolean(this.nYStep <= this.nDuration) && Boolean(this.mcChar.onMove))
         {
            _loc2_ = this.x;
            _loc3_ = this.y;
            this.x = this.linearTween(this.nXStep,this.xDep,this.xTar - this.xDep,this.nDuration);
            this.y = this.linearTween(this.nYStep,this.yDep,this.yTar - this.yDep,this.nDuration);
            if(this.nXStep <= this.nDuration)
            {
               ++this.nXStep;
            }
            if(this.nYStep <= this.nDuration)
            {
               ++this.nYStep;
            }
            if(Math.round(_loc2_) == Math.round(this.x) && Math.round(_loc3_) == Math.round(this.y) && (this.nXStep > 1 || this.nYStep > 1))
            {
               this.stopWalking();
            }
         }
         else
         {
            this.stopWalking();
         }
      }
      
      public function stopWalking() : void
      {
         if(this.mcChar != null && Boolean(this.mcChar.onMove))
         {
            this.mcChar.onMove = false;
            this.mcChar.gotoAndPlay("Idle");
            this.removeEventListener(Event.ENTER_FRAME,this.onEnterFrameWalk);
         }
      }
      
      public function turn(param1:String) : void
      {
         if(param1 == "right" && this.mcChar.scaleX < 0 || param1 == "left" && this.mcChar.scaleX > 0)
         {
            this.mcChar.scaleX *= -1;
            this.mcChar.x *= -1;
         }
      }
      
      public function scale(param1:Number) : void
      {
         if(this.mcChar != null)
         {
            if(this.mcChar.scaleX >= 0)
            {
               this.mcChar.scaleX = param1;
            }
            else
            {
               this.mcChar.scaleX = -param1;
            }
            this.mcChar.scaleY = param1;
            this.shadow.scaleX = this.shadow.scaleY = param1;
            this.pname.y = -this.mcChar.height - 10;
         }
      }
   }
}

