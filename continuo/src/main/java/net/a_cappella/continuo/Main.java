package net.a_cappella.continuo;

import org.springframework.context.support.ClassPathXmlApplicationContext;

public class Main {
    private static ClassPathXmlApplicationContext ctx;

    public static void main(String args[]) {
        String springFile = "app-spring.xml";
        if (args.length>=1) {
            springFile = args[0];
        }

        try {
            ctx = new ClassPathXmlApplicationContext(springFile);
            ShutdownHook.registerShutdownAction(() -> ctx.close());
        } catch (Exception x) {
            x.printStackTrace();
        }
    }
}
