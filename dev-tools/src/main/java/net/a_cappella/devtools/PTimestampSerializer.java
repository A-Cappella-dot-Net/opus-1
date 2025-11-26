package net.a_cappella.devtools;

import com.google.gson.*;
import net.a_cappella.continuo.datatypes.PTimestamp;

import java.lang.reflect.Type;

public class PTimestampSerializer implements JsonSerializer<PTimestamp> {
    @Override
    public JsonElement serialize(PTimestamp src, Type typeOfSrc, JsonSerializationContext context) {
        JsonObject obj = new JsonObject();
        obj.addProperty("value", src.getTimestamp());
        obj.addProperty("type", "timestamp");
        return obj;
    }
}