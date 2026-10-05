import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.tags.SymbolClassTag;
import com.jpexs.decompiler.flash.tags.DefineSpriteTag;
import com.jpexs.decompiler.flash.tags.Tag;
import com.jpexs.decompiler.flash.tags.base.BoundedTag;
import com.jpexs.decompiler.flash.tags.base.CharacterTag;
import java.io.*;

/**
 * Prints "<characterId> <className> <xmin> <ymin> <xmax> <ymax> <frames>" (twips)
 * for every exported symbol of an SWF, or only those whose class name starts with
 * one of the given prefixes / equals one of the given ids.
 *   java -cp tools:ffdec/lib/* SwfIndex file.swf [prefix|id ...]
 */
public class SwfIndex {
  public static void main(String[] a) throws Exception {
    SWF swf = new SWF(new BufferedInputStream(new FileInputStream(a[0])), false);
    java.util.Set<Integer> done = new java.util.HashSet<>();
    for (Tag t : swf.getTags()) {
      if (!(t instanceof SymbolClassTag)) continue;
      SymbolClassTag sc = (SymbolClassTag) t;
      for (int i = 0; i < sc.tags.size(); i++) {
        int id = sc.tags.get(i);
        String name = sc.names.get(i);
        boolean ok = a.length == 1;
        for (int j = 1; j < a.length && !ok; j++) ok = name.startsWith(a[j]) || a[j].equals(String.valueOf(id));
        if (!ok) continue;
        CharacterTag ct = swf.getCharacter(id);
        if (!(ct instanceof BoundedTag)) continue;
        com.jpexs.decompiler.flash.types.RECT r = ((BoundedTag) ct).getRect();
        int frames = ct instanceof DefineSpriteTag ? ((DefineSpriteTag) ct).getFrameCount() : 1;
        done.add(id);
        System.out.println(id + " " + name + " " + r.Xmin + " " + r.Ymin + " " + r.Xmax + " " + r.Ymax + " " + frames);
      }
    }
    // numeric ids that are not exported through SymbolClass (e.g. nested timeline symbols)
    for (int j = 1; j < a.length; j++) {
      if (!a[j].matches("\\d+")) continue;
      int id = Integer.parseInt(a[j]);
      if (done.contains(id)) continue;
      CharacterTag ct = swf.getCharacter(id);
      if (!(ct instanceof BoundedTag)) continue;
      com.jpexs.decompiler.flash.types.RECT r = ((BoundedTag) ct).getRect();
      int frames = ct instanceof DefineSpriteTag ? ((DefineSpriteTag) ct).getFrameCount() : 1;
      System.out.println(id + " id" + id + " " + r.Xmin + " " + r.Ymin + " " + r.Xmax + " " + r.Ymax + " " + frames);
    }
  }
}
