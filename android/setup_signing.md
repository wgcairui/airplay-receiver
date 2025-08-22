# APK签名配置说明

## 当前状态

应用已成功构建，使用了新的包名 `com.oppo.padcast.receiver`，可以与现有应用共存。

目前使用debug签名，如需配置正式签名，请按以下步骤操作：

## 配置自定义签名（可选）

### 1. 签名文件已生成
位置：`android/app/padcast-release-key.jks`
密码：`padcast2024`
别名：`padcast-release`

### 2. 配置文件已创建
`android/key.properties` 文件包含签名配置

### 3. 激活自定义签名

在 `android/app/build.gradle.kts` 中，将以下代码：

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

修改为：

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

并在 `android` 块中的 `defaultConfig` 后添加：

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file("$projectDir/$it") }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}
```

最后将 `buildTypes` 中的 release 配置修改为：

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

## 构建命令

```bash
# 构建发布版APK
flutter build apk --release

# 构建调试版APK  
flutter build apk --debug
```

## 已完成的更改

1. ✅ 更改应用包名：`com.oppo.padcast.padcast` → `com.oppo.padcast.receiver`
2. ✅ 生成新的签名密钥文件
3. ✅ 创建签名配置文件
4. ✅ 成功构建APK (当前使用debug签名)
5. ✅ 新APK可与现有应用共存安装

## 安装测试

构建的APK位于：`build/app/outputs/flutter-apk/app-release.apk`

可以直接安装到设备上，不会与现有应用冲突。