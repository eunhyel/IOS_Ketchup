# WorkManager creates its generated Room database through reflection at startup.
# Keep the generated implementation's zero-argument constructor under AGP 9.
-keep,allowoptimization class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
