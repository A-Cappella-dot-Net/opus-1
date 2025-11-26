package net.a_cappella.devtools;

import com.google.gson.*;
import net.a_cappella.continuo.datatypes.PDate;

import java.lang.reflect.Type;

public class PDateSerializer implements JsonSerializer<PDate> {
    @Override
    public JsonElement serialize(PDate src, Type typeOfSrc, JsonSerializationContext context) {
        JsonObject obj = new JsonObject();
        obj.addProperty("value", src.getDate());
        obj.addProperty("type", "date");
        return obj;
    }
}
