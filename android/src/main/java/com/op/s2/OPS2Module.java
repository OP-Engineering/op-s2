package com.op.s2;

import android.util.Log;
import androidx.annotation.NonNull;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

@ReactModule(name = OPS2Module.NAME)
public class OPS2Module extends ReactContextBaseJavaModule {
  public static final String NAME = "OPS2";

  private OPS2Bridge bridge;

  public OPS2Module(ReactApplicationContext reactContext) {
    super(reactContext);
    bridge = new OPS2Bridge(reactContext);
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  @ReactMethod(isBlockingSynchronousMethod = true)
  public boolean install() {
    try {
      System.loadLibrary("op-s2");
      bridge.install(getReactApplicationContext());
      return true;
    } catch (Exception exception) {
      Log.e(NAME, "Failed to install JSI Bindings!", exception);
      return false;
    }
  }
}
