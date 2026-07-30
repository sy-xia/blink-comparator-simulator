package blinkComparatorSimulator_fla
{
   import adobe.utils.*;
   import edu.unl.astro.starField.*;
   import fl.controls.Button;
   import fl.controls.CheckBox;
   import fl.controls.DataGrid;
   import fl.controls.Slider;
   import fl.data.DataProvider;
   import fl.events.ListEvent;
   import flash.accessibility.*;
   import flash.display.*;
   import flash.errors.*;
   import flash.events.*;
   import flash.external.*;
   import flash.filters.*;
   import flash.geom.*;
   import flash.media.*;
   import flash.net.*;
   import flash.printing.*;
   import flash.system.*;
   import flash.text.*;
   import flash.ui.*;
   import flash.utils.*;
   import flash.xml.*;
   
   public dynamic class MainTimeline extends MovieClip
   {
      
      public var displayedItemQueueIndex:int;
      
      public var observationsDataGrid:DataGrid;
      
      public var speedSlider:Slider;
      
      public var addToQueueButton:Button;
      
      public var lastSwitchInstant:Number;
      
      public var settingsLoader:URLLoader;
      
      public var animationStartTime:Number;
      
      public var settingsXML:XML;
      
      public var showCrosshairsCheckBox:CheckBox;
      
      public var settingsFile:String;
      
      public var epochTextField:TextField;
      
      public var queueDataGrid:DataGrid;
      
      public var forwardButton:Button;
      
      public var removeFromQueueButton:Button;
      
      public var observationsListDP:DataProvider;
      
      public var playButton:Button;
      
      public var starField:StarField;
      
      public var coordinatesMC:MovieClip;
      
      public var backButton:Button;
      
      public function MainTimeline()
      {
         super();
         addFrameScript(0,frame1);
         __setProp_forwardButton_Scene1_Layer1_1();
         __setProp_removeFromQueueButton_Scene1_Layer1_1();
         __setProp_addToQueueButton_Scene1_Layer1_1();
         __setProp_speedSlider_Scene1_Layer1_1();
         __setProp_backButton_Scene1_Layer1_1();
         __setProp_showCrosshairsCheckBox_Scene1_Layer1_1();
         __setProp_playButton_Scene1_Layer1_1();
      }
      
      internal function __setProp_showCrosshairsCheckBox_Scene1_Layer1_1() : *
      {
         try
         {
            showCrosshairsCheckBox["componentInspectorSetting"] = true;
         }
         catch(e:Error)
         {
         }
         showCrosshairsCheckBox.enabled = true;
         showCrosshairsCheckBox.label = "show crosshairs";
         showCrosshairsCheckBox.labelPlacement = "right";
         showCrosshairsCheckBox.selected = true;
         showCrosshairsCheckBox.visible = true;
         try
         {
            showCrosshairsCheckBox["componentInspectorSetting"] = false;
         }
         catch(e:Error)
         {
         }
      }
      
      public function startAnimating(... rest) : void
      {
         lastSwitchInstant = getTimer();
         addEventListener(Event.ENTER_FRAME,onEnterFrameFunc);
         playButton.label = "stop";
      }
      
      internal function __setProp_speedSlider_Scene1_Layer1_1() : *
      {
         try
         {
            speedSlider["componentInspectorSetting"] = true;
         }
         catch(e:Error)
         {
         }
         speedSlider.direction = "horizontal";
         speedSlider.enabled = true;
         speedSlider.liveDragging = true;
         speedSlider.maximum = 10;
         speedSlider.minimum = 1;
         speedSlider.snapInterval = 0.1;
         speedSlider.tickInterval = 0;
         speedSlider.value = 5;
         speedSlider.visible = true;
         try
         {
            speedSlider["componentInspectorSetting"] = false;
         }
         catch(e:Error)
         {
         }
      }
      
      internal function __setProp_forwardButton_Scene1_Layer1_1() : *
      {
         try
         {
            forwardButton["componentInspectorSetting"] = true;
         }
         catch(e:Error)
         {
         }
         forwardButton.emphasized = false;
         forwardButton.enabled = true;
         forwardButton.label = ">";
         forwardButton.labelPlacement = "right";
         forwardButton.selected = false;
         forwardButton.toggle = false;
         forwardButton.visible = true;
         try
         {
            forwardButton["componentInspectorSetting"] = false;
         }
         catch(e:Error)
         {
         }
      }
      
      public function loadSettings() : void
      {
         var _loc1_:GammaTransferFunction = null;
         var _loc2_:LinearTransferFunction = null;
         var _loc3_:XML = null;
         var _loc4_:XML = null;
         starField.lock();
         _loc1_ = new GammaTransferFunction();
         _loc2_ = new LinearTransferFunction();
         _loc2_.inverted = false;
         starField.transferFunction = _loc1_;
         starField.dimensions = {
            "width":400,
            "height":300
         };
         starField.x = 14;
         starField.y = 62;
         starField.noiseMean = settingsXML.fieldParameters.@noiseMean;
         starField.noiseSigma = settingsXML.fieldParameters.@noiseSigma;
         starField.saturationMagnitude = settingsXML.fieldParameters.@saturationMagnitude;
         starField.psf = new AiryDisc(settingsXML.fieldParameters.@psfRadius);
         for each(_loc3_ in settingsXML.starsList.elements())
         {
            switch(String(_loc3_.name()))
            {
               case "constantStar":
                  starField.addStar(new Star({
                     "x":int(_loc3_.@x),
                     "y":int(_loc3_.@y),
                     "magnitude":Number(_loc3_.@magnitude)
                  }));
                  break;
               case "pulsatingStar":
                  starField.addStar(new PulsatingStar({
                     "x":int(_loc3_.@x),
                     "y":int(_loc3_.@y),
                     "centerMagnitude":Number(_loc3_.@centerMagnitude)
                  },PulsatingStar.PRESETS[String(_loc3_.@prototypeName)]));
                  break;
               case "eclipsingBinary":
                  starField.addStar(new EclipsingBinary({
                     "x":int(_loc3_.@x),
                     "y":int(_loc3_.@y),
                     "peakMagnitude":Number(_loc3_.@peakMagnitude)
                  },EclipsingBinary.PRESETS[String(_loc3_.@prototypeName)]));
            }
         }
         for each(_loc4_ in settingsXML.observationsList.elements())
         {
            observationsListDP.addItem({
               "epoch":Number(_loc4_.@epoch),
               "noiseSeed":uint(_loc4_.@noiseSeed)
            });
         }
         starField.unlock();
         observationsDataGrid.dataProvider = observationsListDP;
         observationsDataGrid.selectedIndex = 0;
         updateButtonStates();
         addChild(starField);
      }
      
      internal function __setProp_removeFromQueueButton_Scene1_Layer1_1() : *
      {
         try
         {
            removeFromQueueButton["componentInspectorSetting"] = true;
         }
         catch(e:Error)
         {
         }
         removeFromQueueButton.emphasized = false;
         removeFromQueueButton.enabled = true;
         removeFromQueueButton.label = "remove";
         removeFromQueueButton.labelPlacement = "right";
         removeFromQueueButton.selected = false;
         removeFromQueueButton.toggle = false;
         removeFromQueueButton.visible = true;
         try
         {
            removeFromQueueButton["componentInspectorSetting"] = false;
         }
         catch(e:Error)
         {
         }
      }
      
      public function updateButtonStates(... rest) : void
      {
         addToQueueButton.enabled = observationsDataGrid.selectedIndices.length > 0;
         removeFromQueueButton.enabled = queueDataGrid.selectedIndices.length > 0;
         forwardButton.enabled = backButton.enabled = playButton.enabled = queueDataGrid.length > 1;
      }
      
      public function isAnimating() : Boolean
      {
         return playButton.label == "stop";
      }
      
      public function removeFromQueue(... rest) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         var _loc6_:HackedCellRenderer = null;
         var _loc7_:int = 0;
         _loc2_ = queueDataGrid.selectedItems;
         if(_loc2_.length > 0)
         {
            _loc3_ = null;
            if(displayedItemQueueIndex >= 0 && displayedItemQueueIndex < queueDataGrid.length)
            {
               _loc3_ = queueDataGrid.getItemAt(displayedItemQueueIndex);
            }
            _loc4_ = queueDataGrid.selectedIndex;
            _loc7_ = 0;
            while(_loc7_ < _loc2_.length)
            {
               _loc5_ = _loc2_[_loc7_];
               queueDataGrid.dataProvider.removeItem(_loc5_);
               observationsDataGrid.getItemAt(_loc5_.observationsIndex).inUse = false;
               _loc6_ = observationsDataGrid.getCellRendererAt(_loc5_.observationsIndex,0) as HackedCellRenderer;
               if(_loc6_ != null)
               {
                  _loc6_.drawNow();
               }
               _loc7_++;
            }
            if(_loc4_ >= queueDataGrid.length || _loc4_ == -1 && queueDataGrid.length > 0)
            {
               queueDataGrid.selectedIndex = queueDataGrid.length - 1;
            }
            else
            {
               queueDataGrid.selectedIndex = _loc4_;
            }
            displayedItemQueueIndex = queueDataGrid.dataProvider.getItemIndex(_loc3_);
            if(displayedItemQueueIndex == -1)
            {
               displayedItemQueueIndex = queueDataGrid.selectedIndex;
            }
            if(queueDataGrid.length <= 1 && isAnimating())
            {
               stopAnimating();
            }
            updateStarField();
            updateButtonStates();
         }
      }
      
      internal function __setProp_addToQueueButton_Scene1_Layer1_1() : *
      {
         try
         {
            addToQueueButton["componentInspectorSetting"] = true;
         }
         catch(e:Error)
         {
         }
         addToQueueButton.emphasized = false;
         addToQueueButton.enabled = true;
         addToQueueButton.label = "add";
         addToQueueButton.labelPlacement = "right";
         addToQueueButton.selected = false;
         addToQueueButton.toggle = false;
         addToQueueButton.visible = true;
         try
         {
            addToQueueButton["componentInspectorSetting"] = false;
         }
         catch(e:Error)
         {
         }
      }
      
      public function onMouseMoveOverStage(param1:MouseEvent) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         if(showCrosshairsCheckBox.selected && starField.visible && starField.hitTestPoint(mouseX,mouseY,true))
         {
            _loc2_ = int(mouseX - starField.x);
            _loc3_ = int(mouseY - starField.y);
            if(_loc2_ < 0)
            {
               _loc2_ = 0;
            }
            else if(_loc2_ >= starField.dimensions.width)
            {
               _loc2_ = starField.dimensions.width - 1;
            }
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            else if(_loc3_ >= starField.dimensions.height)
            {
               _loc3_ = starField.dimensions.height - 1;
            }
            coordinatesMC.xField.text = _loc2_.toString();
            coordinatesMC.yField.text = _loc3_.toString();
            coordinatesMC.x = starField.x + _loc2_;
            coordinatesMC.y = starField.y + _loc3_;
            coordinatesMC.visible = true;
            param1.updateAfterEvent();
         }
         else
         {
            coordinatesMC.visible = false;
         }
      }
      
      public function onQueueItemDoubleClicked(param1:ListEvent) : void
      {
         displayedItemQueueIndex = param1.index;
         updateStarField();
      }
      
      public function goForwardInQueue(... rest) : void
      {
         if(queueDataGrid.length > 0)
         {
            displayedItemQueueIndex = (displayedItemQueueIndex + 1) % queueDataGrid.length;
            updateStarField();
         }
      }
      
      public function addToQueue(... rest) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Object = null;
         var _loc4_:HackedCellRenderer = null;
         var _loc5_:Object = null;
         var _loc6_:int = 0;
         _loc2_ = observationsDataGrid.selectedIndices;
         if(_loc2_.length > 0)
         {
            _loc3_ = null;
            _loc6_ = 0;
            while(_loc6_ < _loc2_.length)
            {
               _loc5_ = observationsDataGrid.getItemAt(_loc2_[_loc6_]);
               if(!_loc5_.inUse)
               {
                  _loc3_ = new Object();
                  _loc3_.epoch = _loc5_.epoch;
                  _loc3_.noiseSeed = _loc5_.noiseSeed;
                  _loc3_.observationsIndex = _loc2_[_loc6_];
                  queueDataGrid.dataProvider.addItem(_loc3_);
                  _loc5_.inUse = true;
                  _loc4_ = observationsDataGrid.getCellRendererAt(_loc2_[_loc6_],0) as HackedCellRenderer;
                  if(_loc4_ != null)
                  {
                     _loc4_.drawNow();
                  }
               }
               _loc6_++;
            }
            if(_loc3_ != null)
            {
               queueDataGrid.selectedItem = _loc3_;
            }
            displayedItemQueueIndex = queueDataGrid.length - 1;
            observationsDataGrid.selectedIndex = -1;
            queueDataGrid.scrollToIndex(displayedItemQueueIndex);
            updateStarField();
            updateButtonStates();
         }
      }
      
      public function stopAnimating(... rest) : void
      {
         removeEventListener(Event.ENTER_FRAME,onEnterFrameFunc);
         playButton.label = "blink";
      }
      
      public function toggleAnimation(... rest) : void
      {
         if(isAnimating())
         {
            stopAnimating();
         }
         else
         {
            startAnimating();
         }
      }
      
      public function onEnterFrameFunc(... rest) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:int = 0;
         _loc2_ = getTimer() - lastSwitchInstant;
         _loc3_ = 50;
         _loc4_ = 1000;
         _loc5_ = _loc3_ + (_loc4_ - _loc3_) * (1 - Math.log(speedSlider.value) / Math.LN10);
         _loc6_ = Math.floor(_loc2_ / _loc5_);
         if(_loc6_ == 0)
         {
            return;
         }
         displayedItemQueueIndex = (displayedItemQueueIndex + _loc6_) % queueDataGrid.length;
         lastSwitchInstant += _loc5_ * _loc6_;
         updateStarField();
      }
      
      internal function frame1() : *
      {
         observationsDataGrid.allowMultipleSelection = true;
         queueDataGrid.allowMultipleSelection = true;
         observationsDataGrid.setStyle("cellRenderer",HackedCellRenderer);
         queueDataGrid.setStyle("cellRenderer",HackedCellRenderer);
         observationsDataGrid.addEventListener("change",updateButtonStates);
         queueDataGrid.addEventListener("change",updateButtonStates);
         observationsDataGrid.addEventListener(ListEvent.ITEM_DOUBLE_CLICK,addToQueue);
         queueDataGrid.addEventListener(ListEvent.ITEM_DOUBLE_CLICK,onQueueItemDoubleClicked);
         observationsDataGrid.addColumn("epoch").sortOptions = Array.NUMERIC;
         queueDataGrid.addColumn("epoch").sortOptions = Array.NUMERIC;
         coordinatesMC.visible = false;
         displayedItemQueueIndex = -1;
         addToQueueButton.addEventListener(MouseEvent.CLICK,addToQueue);
         removeFromQueueButton.addEventListener(MouseEvent.CLICK,removeFromQueue);
         queueDataGrid.addEventListener(Event.CHANGE,updateStarField);
         backButton.addEventListener(MouseEvent.CLICK,goBackInQueue);
         forwardButton.addEventListener(MouseEvent.CLICK,goForwardInQueue);
         playButton.addEventListener(MouseEvent.CLICK,toggleAnimation);
         starField = new StarField();
         observationsListDP = new DataProvider();
         starField.visible = false;
         showCrosshairsCheckBox.addEventListener(Event.CHANGE,onShowCrosshairsToggled);
         stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveOverStage);
         settingsXML = new XML();
         settingsFile = root.loaderInfo.parameters.settingsFile is String ? root.loaderInfo.parameters.settingsFile : "settings.xml";
         settingsLoader = new URLLoader(new URLRequest(settingsFile));
         settingsLoader.addEventListener("complete",onSettingsLoaded);
      }
      
      internal function __setProp_playButton_Scene1_Layer1_1() : *
      {
         try
         {
            playButton["componentInspectorSetting"] = true;
         }
         catch(e:Error)
         {
         }
         playButton.emphasized = false;
         playButton.enabled = true;
         playButton.label = "blink";
         playButton.labelPlacement = "right";
         playButton.selected = false;
         playButton.toggle = false;
         playButton.visible = true;
         try
         {
            playButton["componentInspectorSetting"] = false;
         }
         catch(e:Error)
         {
         }
      }
      
      public function onShowCrosshairsToggled(... rest) : void
      {
         if(!showCrosshairsCheckBox.selected)
         {
            coordinatesMC.visible = false;
         }
      }
      
      public function onSettingsLoaded(... rest) : void
      {
         settingsXML = XML(settingsLoader.data);
         loadSettings();
         setChildIndex(coordinatesMC,numChildren - 1);
      }
      
      internal function __setProp_backButton_Scene1_Layer1_1() : *
      {
         try
         {
            backButton["componentInspectorSetting"] = true;
         }
         catch(e:Error)
         {
         }
         backButton.emphasized = false;
         backButton.enabled = true;
         backButton.label = "<";
         backButton.labelPlacement = "right";
         backButton.selected = false;
         backButton.toggle = false;
         backButton.visible = true;
         try
         {
            backButton["componentInspectorSetting"] = false;
         }
         catch(e:Error)
         {
         }
      }
      
      public function goBackInQueue(... rest) : void
      {
         if(queueDataGrid.length > 0)
         {
            displayedItemQueueIndex = (displayedItemQueueIndex + queueDataGrid.length - 1) % queueDataGrid.length;
            updateStarField();
         }
      }
      
      public function updateStarField(... rest) : void
      {
         var _loc2_:Object = null;
         var _loc3_:HackedCellRenderer = null;
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         if(displayedItemQueueIndex >= queueDataGrid.length)
         {
            trace("WARNING, this should never have happened, the displayed item index is out of range");
            displayedItemQueueIndex = queueDataGrid.length - 1;
         }
         if(displayedItemQueueIndex < 0)
         {
            starField.visible = false;
            epochTextField.text = "...";
         }
         else
         {
            _loc5_ = queueDataGrid.getItemAt(displayedItemQueueIndex);
            starField.visible = true;
            starField.setEpochAndNoiseSeed(_loc5_.epoch,_loc5_.noiseSeed);
            epochTextField.text = _loc5_.epoch;
         }
         _loc4_ = 0;
         while(_loc4_ < queueDataGrid.length)
         {
            _loc2_ = queueDataGrid.getItemAt(_loc4_);
            _loc2_.displayed = _loc4_ == displayedItemQueueIndex;
            _loc3_ = queueDataGrid.getCellRendererAt(_loc4_,0) as HackedCellRenderer;
            if(_loc3_ != null)
            {
               _loc3_.drawNow();
            }
            _loc4_++;
         }
      }
   }
}

