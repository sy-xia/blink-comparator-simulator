package
{
   import fl.controls.listClasses.CellRenderer;
   import fl.controls.listClasses.ICellRenderer;
   import flash.display.Sprite;
   
   public class HackedCellRenderer extends CellRenderer implements ICellRenderer
   {
      
      internal var _displayedIcon:Sprite;
      
      internal var _emptyIcon:Sprite;
      
      public function HackedCellRenderer()
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         _loc1_ = 4;
         _loc2_ = 2;
         _emptyIcon = new Sprite();
         _emptyIcon.graphics.lineStyle();
         _emptyIcon.graphics.beginFill(16711680,0);
         _emptyIcon.graphics.drawCircle(_loc2_ + _loc1_,_loc1_,_loc1_);
         _emptyIcon.graphics.endFill();
         _displayedIcon = new Sprite();
         _displayedIcon.graphics.lineStyle();
         _displayedIcon.graphics.beginFill(16724016,1);
         _displayedIcon.graphics.drawCircle(_loc2_ + _loc1_,_loc1_,_loc1_);
         _displayedIcon.graphics.endFill();
         super();
      }
      
      override protected function draw() : void
      {
         enabled = !_data.inUse;
         if(_data.displayed != undefined)
         {
            if(_data.displayed)
            {
               setStyle("icon",_displayedIcon);
            }
            else
            {
               setStyle("icon",_emptyIcon);
            }
         }
         super.draw();
      }
   }
}

