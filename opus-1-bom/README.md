# opus-1-bom

The Maven BOM for opus-1: importing it as a platform aligns the versions of all opus-1 library modules (continuo, cembalo, presto, presto-aeron, madrigal-common, madrigal-aeron, madrigal), so consumers depend on the modules without specifying versions.

```kotlin
dependencies {
    api(platform("net.a-cappella:opus-1-bom:<version>"))
    implementation("net.a-cappella:presto")
}
```
