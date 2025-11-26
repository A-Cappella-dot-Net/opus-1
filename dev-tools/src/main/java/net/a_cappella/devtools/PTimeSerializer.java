package net.a_cappella.devtools;

import com.google.gson.*;
import net.a_cappella.continuo.datatypes.PTime;

import java.lang.reflect.Type;

public class PTimeSerializer implements JsonSerializer<PTime> {
    @Override
    public JsonElement serialize(PTime src, Type typeOfSrc, JsonSerializationContext context) {
        JsonObject obj = new JsonObject();
        obj.addProperty("value", src.getTime());
        obj.addProperty("type", "time");
        return obj;
    }
}
