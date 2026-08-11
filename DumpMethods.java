import java.lang.reflect.Method;
import java.net.URL;
import java.net.URLClassLoader;

public class DumpMethods {
    public static void main(String[] args) throws Exception {
        URLClassLoader classLoader = new URLClassLoader(new URL[]{
            new URL("file:///C:/Users/PC%20NET/.gradle/caches/modules-2/files-2.1/io.github.pytgcalls/ntgcalls/2.0.0/extracted/classes.jar")
        });
        Class<?> clazz = classLoader.loadClass("io.github.pytgcalls.NTgCalls");
        System.out.println("Methods of NTgCalls:");
        for (Method m : clazz.getDeclaredMethods()) {
            System.out.println(m.toString());
        }
    }
}
