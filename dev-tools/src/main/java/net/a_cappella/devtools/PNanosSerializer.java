package net.a_cappella.devtools;

import com.google.gson.*;
import net.a_cappella.continuo.datatypes.PNanos;

import java.lang.reflect.Type;

public class PNanosSerializer implements JsonSerializer<PNanos> {
    @Override
    public JsonElement serialize(PNanos src, Type typeOfSrc, JsonSerializationContext context) {
        long nanos = src.getNanos();
        long millis = nanos / 1_000_000;
        long subMilliNanos = nanos % 1_000_000; // Remaining nanos after millis
        JsonObject obj = new JsonObject();
        obj.addProperty("value", millis);
        obj.addProperty("nanos", subMilliNanos);
        obj.addProperty("type", "nanos");
        return obj;
    }
}
