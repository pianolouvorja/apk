# Regras adicionais de R8/ProGuard para release do LouvorJA PIANO.
# Flutter e plugins publicados fornecem as consumer rules necessarias.
# Adicione regras -keep apenas quando uma dependencia quebrar sob minify.

# Evita expor atributos de depuracao desnecessarios no artefato release.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Preserva classes chamadas por AndroidX/FileProvider durante a instalacao do APK.
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.core.content.FileProvider$PathStrategy { *; }
