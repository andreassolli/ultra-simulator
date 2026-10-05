package
{
    import flash.display.MovieClip;

    /**
     * Minimal ancestor/root object supplied to the recovered AvatarMC.
     *
     * AvatarMC's constructor expects a MovieClip-like ancestor. We keep this
     * object deliberately empty for the first compilation pass.
     */
    public class CharacterRoot extends MovieClip
    {
        public function CharacterRoot()
        {
            super();
        }
    }
}
