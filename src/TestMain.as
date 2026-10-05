package
{
    import AQWorlds.AvatarMC;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;

    public class TestMain extends Sprite
    {
        private var player:AvatarMC;
        private var characters:Array = [];

        private var leftDown:Boolean = false;
        private var rightDown:Boolean = false;
        private var upDown:Boolean = false;
        private var downDown:Boolean = false;

        private var speed:Number = 8;

        public function TestMain()
        {
            addEventListener(Event.ADDED_TO_STAGE, onAdded);
        }

        private function onAdded(event:Event):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, onAdded);

            // Catch anything that causes the recovered code to terminate
            // the SWF before Flash Player can show us the error.
            loaderInfo.uncaughtErrorEvents.addEventListener(
                UncaughtErrorEvent.UNCAUGHT_ERROR,
                onUncaughtError
            );

            stage.frameRate = 30;

            drawBackground();
            createTitle();

            try
            {
                createCharacters();
            }
            catch (error:Error)
            {
                showError(error);
            }

            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        private function createCharacters():void
        {
            var root:CharacterRoot = new CharacterRoot();

            player = new AvatarMC(root);
            player.name = "Player";
            player.x = stage.stageWidth * 0.50;
            player.y = stage.stageHeight * 0.55;
            addChild(player);
            characters.push(player);

            var npc1:AvatarMC = new AvatarMC(root);
            npc1.name = "Character2";
            npc1.x = stage.stageWidth * 0.25;
            npc1.y = stage.stageHeight * 0.55;
            addChild(npc1);
            characters.push(npc1);

            var npc2:AvatarMC = new AvatarMC(root);
            npc2.name = "Character3";
            npc2.x = stage.stageWidth * 0.50;
            npc2.y = stage.stageHeight * 0.78;
            addChild(npc2);
            characters.push(npc2);

            var npc3:AvatarMC = new AvatarMC(root);
            npc3.name = "Character4";
            npc3.x = stage.stageWidth * 0.75;
            npc3.y = stage.stageHeight * 0.55;
            addChild(npc3);
            characters.push(npc3);

            setChildIndex(player, numChildren - 1);
        }

        private function onEnterFrame(event:Event):void
        {
            if (!player)
                return;

            var dx:Number = 0;
            var dy:Number = 0;

            if (leftDown)
                dx -= speed;

            if (rightDown)
                dx += speed;

            if (upDown)
                dy -= speed;

            if (downDown)
                dy += speed;

            if (dx != 0 || dy != 0)
            {
                player.x += dx;
                player.y += dy;

                clampPlayer();
            }
        }

        private function clampPlayer():void
        {
            var halfW:Number = 80;
            var halfH:Number = 120;

            if (player.x < halfW)
                player.x = halfW;

            if (player.x > stage.stageWidth - halfW)
                player.x = stage.stageWidth - halfW;

            if (player.y < halfH)
                player.y = halfH;

            if (player.y > stage.stageHeight - halfH)
                player.y = stage.stageHeight - halfH;
        }

        private function onKeyDown(event:KeyboardEvent):void
        {
            switch (event.keyCode)
            {
                case Keyboard.LEFT:
                case Keyboard.A:
                    leftDown = true;
                    break;

                case Keyboard.RIGHT:
                case Keyboard.D:
                    rightDown = true;
                    break;

                case Keyboard.UP:
                case Keyboard.W:
                    upDown = true;
                    break;

                case Keyboard.DOWN:
                case Keyboard.S:
                    downDown = true;
                    break;
            }
        }

        private function onKeyUp(event:KeyboardEvent):void
        {
            switch (event.keyCode)
            {
                case Keyboard.LEFT:
                case Keyboard.A:
                    leftDown = false;
                    break;

                case Keyboard.RIGHT:
                case Keyboard.D:
                    rightDown = false;
                    break;

                case Keyboard.UP:
                case Keyboard.W:
                    upDown = false;
                    break;

                case Keyboard.DOWN:
                case Keyboard.S:
                    downDown = false;
                    break;
            }
        }

        private function drawBackground():void
        {
            graphics.beginFill(0x20252B);
            graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            graphics.endFill();

            graphics.beginFill(0x30363D);
            graphics.drawRect(
                0,
                stage.stageHeight * 0.42,
                stage.stageWidth,
                stage.stageHeight * 0.48
            );
            graphics.endFill();
        }

        private function createTitle():void
        {
            var label:TextField = new TextField();

            label.width = stage.stageWidth;
            label.height = 40;
            label.x = 20;
            label.y = 15;
            label.selectable = false;

            var format:TextFormat = new TextFormat();
            format.font = "_sans";
            format.size = 18;
            format.bold = true;
            format.color = 0xFFFFFF;

            label.defaultTextFormat = format;
            label.text = "Recovered Character Test  •  WASD / Arrow Keys";

            addChild(label);
        }

        private function onUncaughtError(event:UncaughtErrorEvent):void
        {
            if (event.error is Error)
            {
                showError(event.error as Error);
            }
            else
            {
                showErrorMessage(String(event.error));
            }

            event.preventDefault();
        }

        private function showError(error:Error):void
        {
            var message:String =
                "RUNTIME ERROR\n\n" +
                "Name: " + error.name + "\n" +
                "Message: " + error.message + "\n" +
                "Error ID: " + error.errorID + "\n\n" +
                "Stack:\n" + error.getStackTrace();

            showErrorMessage(message);
        }

        private function showErrorMessage(message:String):void
        {
            var errorField:TextField = new TextField();

            errorField.x = 20;
            errorField.y = 60;
            errorField.width = stage.stageWidth - 40;
            errorField.height = stage.stageHeight - 80;
            errorField.multiline = true;
            errorField.wordWrap = true;
            errorField.selectable = true;
            errorField.background = true;
            errorField.backgroundColor = 0x000000;
            errorField.textColor = 0xFFFFFF;

            var format:TextFormat = new TextFormat();
            format.font = "_typewriter";
            format.size = 14;

            errorField.defaultTextFormat = format;
            errorField.text = message;

            addChild(errorField);
        }
    }
}
