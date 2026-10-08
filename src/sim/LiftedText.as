package sim
{
    import flash.text.TextField;

    /**
     * Ruffle's built-in "_sans" has taller line metrics than Flash's (the baseline sits about 0.16 em lower and the line is taller), so
     * every text laid out for Flash sat too low in its box and the bottom of letters like "p" and "g" was cut off. The field draws
     * itself `lift` pixels higher than the y it is given; y still reads back as what was set, so the layouts do not change.
     */
    public class LiftedText extends TextField
    {
        private var lift:Number = 0;

        public function setLift(px:Number):void
        {
            var at:Number = y;
            lift = px;
            y = at;
        }

        override public function set y(v:Number):void
        {
            super.y = v - lift;
        }

        override public function get y():Number
        {
            return super.y + lift;
        }
    }
}
