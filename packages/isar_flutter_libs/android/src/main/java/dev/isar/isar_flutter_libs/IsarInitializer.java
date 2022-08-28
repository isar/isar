package dev.isar.isar_flutter_libs;

import android.content.Context;
import android.os.Build;

import androidx.startup.Initializer;

import java.util.ArrayList;
import java.util.List;

public class IsarInitializer implements Initializer<Void> {

    @Override
    public Void create(Context context) {
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
            System.loadLibrary("isar");
            initializePath(context.getFilesDir().getAbsolutePath());
        }
        return null;
    }

    @Override
    public List<Class<? extends Initializer<?>>> dependencies() {
        return new ArrayList<>();
    }

    private static native void initializePath(String path);
}