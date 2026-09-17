# Tesseract and Leptonica are bound to native code in both directions: the
# Java classes declare native methods, and the C++ side reaches back for
# fields and constructors by name (TessBaseAPI's native handle, the Rects
# it builds for ProgressValues). R8 sees none of that -- to it those
# members look unused -- so without these rules a minified release build
# strips or renames them and OCR fails at runtime with an
# UnsatisfiedLinkError, while every debug build keeps working.
#
# The AAR ships no consumer rules of its own, so this is the only place
# they exist.
-keep class com.googlecode.tesseract.android.** { *; }
-keep class com.googlecode.leptonica.android.** { *; }
