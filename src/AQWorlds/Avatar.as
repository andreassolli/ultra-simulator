package AQWorlds
{
   import flash.display.MovieClip;
   import flash.events.Event;
   
   public class Avatar
   {
      
      public var pMC:MovieClip;
      
      public var pnm:String;
      
      public var objData:Object = null;
      
      public var dataLeaf:Object = {};
      
      public var isMyAvatar:Boolean = true;
      
      public var petMC:PetMC;
      
      public var sLinkPet:String = "";
      
      private var loadCount:int = 0;
      
      private var firstLoad:Boolean = true;
      
      public var strProj:String = "";
      
      private var specialAnimation:Object = new Object();
      
      public var m:MovieClip;
      
      public function Avatar(param1:MovieClip)
      {
         super();
         this.m = param1;
         this.petMC = new PetMC(param1);
      }
      
      public function initAvatar(param1:Object) : *
      {
         this.pMC.updateName();
      }
      
      private function onLoadPetError(param1:Event) : void
      {
      }
      
      public function onLoadPetComplete(param1:Event) : void
      {
         var _loc2_:Class = this.pMC.findDef(this.pMC.ActiveSet["itemLinks"]["Pet"],{"or":1});
         if(_loc2_ != null)
         {
            this.petMC.visible = this.pMC.ActiveSet["itemShow"]["Pet"];
            if(this.petMC.numChildren > 0)
            {
               this.petMC.removeChildAt(1);
            }
            this.petMC.mcChar = MovieClip(this.petMC.addChildAt(new _loc2_(),1));
            this.petMC.mcChar.name = "mc";
            this.petPos();
         }
      }
      
      public function petPos() : void
      {
         this.petMC.x = this.pMC.x - 20;
         this.petMC.y = this.pMC.y + 5;
         this.petMC.mcChar.scaleX = this.m._avatarScaling;
         this.petMC.mcChar.scaleY = this.m._avatarScaling;
         this.petMC.shadow.scaleX = this.m._avatarScaling;
         this.petMC.shadow.scaleY = this.m._avatarScaling;
         this.m.setChildIndex(this.petMC,this.m.numChildren - 1);
      }
   }
}

